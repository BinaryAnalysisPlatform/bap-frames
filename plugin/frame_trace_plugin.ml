open Core_kernel.Std
open Bap.Std
open Bap_traces.Std
include Self()

module FE = Frame_events

let create_frame_reader path =
  let reader = new Trace_container.reader path in
  object(self)
    val mutable events = []
    val context =
      object
        val mutable tid = None
        method switch id' =
          match tid with
          | Some id when id = id' -> false
          | _ -> tid <- Some id'; true
      end

    method private tracer_meta =
      Some Tracer.{
          name;
          args = argv;
          version = Int64.to_string reader#get_trace_version
        }

    method private arch_meta =
      Arch_bfd.sexp_of_bfd_architecture reader#get_arch |>
      Sexp.to_string |>
      String.substr_replace_all ~pattern:"Bfd_arch_" ~with_:"" |>
      Arch.of_string |>
      Option.map ~f:(function
          | `x86 when
              reader#get_machine = (Int64.of_int Arch_bfd.mach_x86_64) -> `x86_64
          | a -> a)


    method meta =
      let set : 'a. 'a tag -> 'a option -> Dict.t -> Dict.t = fun tag value dict ->
        Option.value_map value
          ~f:(fun value -> Dict.set dict tag value) ~default:dict in
      let open Meta in
      let meta = if reader#get_trace_version = 1L
        then Dict.empty
        else match reader#get_frame with
          | `meta_frame f -> Frame_events.of_meta_frame f
          | _ -> Dict.empty in
      set tracer self#tracer_meta meta |>
      set arch self#arch_meta

    method next () =
      let arch = Dict.find self#meta Meta.arch in
      let rec loop () =
        match events with
        | e::ee -> events <- ee; Some e
        | [] when reader#end_of_trace -> None
        | [] ->
          events <- FE.of_frame ~context:context#switch
              ?arch reader#get_frame;
          loop () in
      try
        let open Result in
        match loop () with
        | Some event -> Option.some (Ok event)
        | None -> None
      with exn -> Option.some @@ Or_error.of_exn exn
  end

module Frame_proto : Trace.P = struct
  let name = "frame-trace"

  let supports tag =
    let checkers =
      let open Value.Tag in
      let open Event in
      [ same pc_update;
        same context_switch;
        same code_exec;
        same memory_load;
        same memory_store;
        same register_read;
        same register_write ] in
    List.exists ~f:(fun same -> same tag) checkers

  let probe uri =
    let is_readable uri =
      try
        let _reader = create_frame_reader @@ Uri.path uri in
        true
      with exn -> false in
    Uri.scheme uri = Some "file" &&
    Filename.check_suffix (Uri.path uri) ".frames" &&
    is_readable uri
end

let build_reader tool uri id =
  let build () =
    let reader = create_frame_reader @@ Uri.path uri in
    let open Trace.Reader in
    { tool;
      meta = reader#meta;
      next = reader#next } in
  try Ok (build ()) with
  | Unix.Unix_error (err, _, _) -> Result.fail (`System_error err)
  | exn -> Result.fail (`Protocol_error (Error.of_exn  exn))

let () =
  let tool = Trace.register_tool (module Frame_proto : Trace.S) in
  let proto = Trace.register_proto (module Frame_proto) in
  Trace.register_reader proto @@ build_reader tool
