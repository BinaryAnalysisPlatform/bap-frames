open Core_kernel
open Bap.Std
open Bap_traces.Std
open Binary_packing
open Format

module Frame = Frame_piqi

type field =
  | Magic
  | Version
  | Bfd_arch
  | Bfd_mach
  | Frames
  | Toc
[@@deriving enumerate, variants]

module F = Frame_enum.Make(struct
    type t = field
    let rank = Variants_of_field.to_rank
    let all = all_of_field
  end)

let field_to_enum = F.to_enum
let field_of_enum = F.of_enum
let max_field = F.max

type header = {
  magic : int64;
  version : int;
  bfd_arch : Frame_arch.t;
  bfd_mach : int;
  frames : int64;
  toc_off : int64;
}

type frame = Frame.frame


type chan = {
  close : unit -> unit;
  read  : unit -> frame;
}

type reader = {
  header : header;
  meta : dict;
  chan : chan;
  frames : unit -> frame option;
}

type t = reader


(** Map BFD architecture specification to BAP architecture.

    Note: it looks like that having BFD Arch and Machine
    specifications is not enough, and some information is missing in the
    trace header, in particular we need endianness information.
*)
module Arch = struct
  let arm n = Frame_mach.Arm.(match of_enum n with
      | Some V4 -> Some `armv4
      | Some V4T -> Some `thumbv4
      | Some V5 -> Some `armv5
      | Some (V5T | V5TE | XScale) -> Some `thumbv5
      | Some Unknown -> Some `armv7
      | Some _ -> Some `armv7
      | None -> None)

  let mips n = Frame_mach.Mips.(match of_enum n with
      | Some Unknown -> Some `mips
      | Some (Isa32 | Isa32r2) -> Some `mips
      | Some (Isa64 | Isa64r2) -> Some `mips64
      | None -> None)

  let ppc n = Frame_mach.Ppc.(match of_enum n with
      | Some Ppc32 -> Some `ppc
      | Some Ppc64 -> Some `ppc64
      | _ -> None)

  let sparc n = Frame_mach.Sparc.(match of_enum n with
      | Some (Sparc | Unknown) -> Some `sparc
      | Some (V9 | V9a | V9b) -> Some `sparcv9
      | _ -> None)

  let i386 n = Frame_mach.I386.(match of_enum n with
      | Some (I386 | I8086 | I386_intel | Unknown) -> Some `x86
      | Some (X86_64 | X86_64_intel) -> Some `x86_64
      | _ -> None)

  let aarch64 n = Frame_mach.AArch64.(match of_enum n with
      | Some (Unknown) -> Some `aarch64
      | _ -> None)

  (** a projection from BFD architectures to BAP.  *)
  let of_bfd arch mach = match arch with
    | Frame_arch.Arm -> arm mach
    | Frame_arch.I386 -> i386 mach
    | Frame_arch.Mips -> mips mach
    | Frame_arch.Powerpc -> ppc mach
    | Frame_arch.Sparc -> sparc mach
    | Frame_arch.AArch64 -> aarch64 mach
    | _ -> None
end

exception Parse_error of string
let parse_error fmt =
  Format.ksprintf (fun s -> raise (Parse_error s)) fmt

let field_size = 8
let header_size = (max_field + 1) * field_size
let field_offset f = field_to_enum f * field_size
let field f unpack buf = unpack ~buf ~pos:(field_offset f)
let int = unpack_signed_64_int_little_endian
let int64 = unpack_signed_64_little_endian


let arch ~buf ~pos =
  match Frame_arch.of_enum (int ~buf ~pos) with
  | None -> parse_error "Unknown BFD arch id: %d" (int ~buf ~pos)
  | Some a -> a

let header buf = {
  magic    = field magic    int64    buf;
  version  = field version  int      buf;
  bfd_arch = field bfd_arch arch     buf;
  bfd_mach = field bfd_mach int      buf;
  frames   = field frames   int64    buf;
  toc_off  = field toc      int64    buf;
}

let read_header ic =
  let len = header_size in
  let buf = Bytes.create len in
  match In_channel.really_input ic ~buf ~pos:0 ~len with
  | None -> parse_error "malformed header"
  | Some () -> header buf

let tracer {Frame.Tracer.name; args; envp; version} = Tracer.{
    name; version;
    args = Array.of_list args;
    envp = Array.of_list envp;
  }

let binary {Frame.Target.path; args; envp; md5sum} = Binary.{
    path; md5sum;
    args = Array.of_list args;
    envp = Array.of_list envp;
  }

let fstats {Frame.Fstats.size; atime; mtime; ctime} = File_stats.{
    size; atime; mtime; ctime
  }

let tstats {Frame.Meta_frame.time; host; user} = Trace_stats.{
    time; host; user
  }

let field tag v d = Dict.set d tag v

let meta_fields meta = Frame.Meta_frame.[
    field Meta.trace_stats @@ tstats meta;
    field Meta.tracer @@ tracer meta.tracer;
    field Meta.binary @@ binary meta.target;
    field Meta.binary_file_stats @@ fstats meta.fstats;
  ]

let meta_frame init frame =
  meta_fields frame |> List.fold ~init ~f:(fun d f -> f d)

let read_size =
  let len = field_size in
  let buf = Bytes.create len in
  fun ch ->
    Caml.really_input ch buf 0 len;
    int ~buf ~pos:0

let read_piqi parse ch =
  let len = read_size ch in
  Caml.really_input_string ch len |>
  Piqirun.init_from_string |>
  parse

let read_frames input = fun () ->
  try
    Some (input.read ())
  with
    Piqirun.IBuf.End_of_buffer | End_of_file ->
    input.close ();
    None

let read_meta header ch =
  let dict = match Arch.of_bfd header.bfd_arch header.bfd_mach with
    | None -> Dict.empty
    | Some arch -> Dict.set Dict.empty Meta.arch arch in
  if header.version = 1 then dict
  else meta_frame dict @@ read_piqi Frame_piqi.parse_meta_frame ch

let create uri =
  let ic = In_channel.create ~binary:true (Uri.path uri) in
  let close = lazy (In_channel.close ic) in
  let close () = Lazy.force close in
  try
    let header = read_header ic in
    let read () =
      try read_piqi Frame_piqi.parse_frame ic with exn ->
        if Int64.(header.toc_off <> 0L &&
                  In_channel.pos ic >= header.toc_off)
        then raise End_of_file
        else raise exn in
    let chan = {close; read} in
    let meta = read_meta header ic in
    let frames = read_frames chan in
    {header;meta;frames;chan}
  with exn ->
    close ();
    raise exn

let close t = t.chan.close ()

let meta t = t.meta
let arch t = Arch.of_bfd t.header.bfd_arch t.header.bfd_mach
let next_frame t = t.frames ()
let version t = t.header.version
