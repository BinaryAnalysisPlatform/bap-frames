(**
    Trace container implementation.

    Bugs:
    We keep track of things as Int64's, but ML's IO only uses ints.
*)
open Core_kernel.Std

exception Trace_exception of string

type frame = Frame_piqi.frame

module In_channel : sig
  include (module type of In_channel)
  exception End_of_file
  exception Overflow of string
  val read_i64 : t -> Int64.t
end = struct
  include In_channel
  exception End_of_file
  exception Overflow of string

  let read_byte ic =
    match input_byte ic with
    | None -> raise End_of_file
    | Some n -> n
  (* this stuff is basically lifted from the BatIO source. it was useful
   * for reading traces, and rather than try and buggily emulate it I figured
   * it'd be better to just lift it... *)
  let fix = lnot 0x7FFFFFFF

  let read_i32 ch =
    let ch1 = read_byte ch in
    let ch2 = read_byte ch in
    let ch3 = read_byte ch in
    let ch4 = read_byte ch in
    if ch4 land 128 <> 0 then begin
      if ch4 land 64 = 0 then raise (Overflow "read_i32");
      (ch1 lor (ch2 lsl 8) lor (ch3 lsl 16) lor ((ch4 land 127) lsl 24)) lor fix
    end else begin
      if ch4 land 64 <> 0 then raise (Overflow "read_i32");
      ch1 lor (ch2 lsl 8) lor (ch3 lsl 16) lor (ch4 lsl 24)
    end

  let read_real_i32 ch =
    let ch1 = read_byte ch in
    let ch2 = read_byte ch in
    let ch3 = read_byte ch in
    let base = Int32.of_int_exn (ch1 lor (ch2 lsl 8) lor (ch3 lsl 16)) in
    let big = Int32.shift_left (Int32.of_int_exn (read_byte ch)) 24 in
    Int32.bit_or base big

  let read_i64 ch =
    let ch1 = read_byte ch in
    let ch2 = read_byte ch in
    let ch3 = read_byte ch in
    let ch4 = read_byte ch in
    let base = Int64.of_int_exn (ch1 lor (ch2 lsl 8) lor (ch3 lsl 16)) in
    let small = Int64.bit_or base (Int64.shift_left (Int64.of_int_exn ch4) 24) in
    let big = Int64.of_int32 (read_real_i32 ch) in
    Int64.bit_or (Int64.shift_left big 32) small

end

(* XXX: Auto-pull this from C++ header file *)
let default_frames_per_toc_entry = 10000L
and default_auto_finish = false
and default_arch = Arch_bfd.Bfd_arch_i386
and default_machine = 0L

(* Internal definitions *)
let magic_number = 7456879624156307493L
and magic_number_offset = 0L
and trace_version_offset = 8L
and bfd_arch_offset = 16L
and bfd_machine_offset = 24L
and num_trace_frames_offset = 32L
and toc_offset_offset = 40L
and first_frame_offset = 48L

let out_trace_version = 1L
and lowest_supported_version = 1L
and highest_supported_version = 1L

let write_i64 oc i64 = output_string oc (Int64.to_string i64)

let read_i64 = In_channel.read_i64

(** [foldn f i n] is f (... (f (f i n) (n-1)) ...) 0 *)
let rec foldn64 ?(t=0L) f i n =
  let open Int64 in
  match n-t with
  | 0L -> f i n
  | _ when n>t -> foldn64 ~t f (f i n) (n-1L)
  | n when n = -1L -> i (* otags has trouble with '-1L' *)
  | w -> raise (Invalid_argument "negative index number in foldn64")

(* End helpers *)

class writer ?(arch=default_arch) ?(machine=default_machine) ?(frames_per_toc_entry = default_frames_per_toc_entry) ?(auto_finish=default_auto_finish) filename =
  (* Open the trace file *)
  let oc = Out_channel.create ~binary:true ~append:false filename in
  (* Seek to the first frame *)
  let () = Out_channel.seek oc first_frame_offset in
  object(self)

    val mutable toc = []
    val mutable num_frames = 0L
    val frames_per_toc_entry = frames_per_toc_entry
    val auto_finish = auto_finish
    val mutable is_finished = false

    initializer let hb = Heap_block.create_exn self in
      Gc.Expert.add_finalizer hb (fun o -> let o = Heap_block.value o in
                                   if not o#has_finished then o#finish)

    method add (frame:frame) =
      if num_frames <> 0L && Int64.rem num_frames frames_per_toc_entry = 0L then
        (* Put a toc entry *)
        toc <- (Out_channel.pos oc) :: toc;

      let () = num_frames <- Int64.succ num_frames in

      (* Convert to string so we know length *)
      let s = Frame_piqi_ext.gen_frame frame `pb in
      let len = Int64.of_int (String.length s) in
      if len <= 0L then
        raise (Trace_exception "Attempt to add zero-length frame to trace");

      (* Write the length in binary *)
      let () = write_i64 oc len in

      let old_offset = Out_channel.pos oc in
      (* Finally write the serialized string out. *)
      let () = Out_channel.output_string oc s in

      (* Double-check our size. *)
      assert (Int64.(old_offset + len)
              = Out_channel.pos oc);

    method finish =
      if is_finished then raise (Trace_exception "finish called twice");

      let toc_offset = Out_channel.pos oc in
      (* Make sure the toc is the right size. *)
      let () = assert ((num_frames = 0L) || Int64.((Int64.pred num_frames) / frames_per_toc_entry) = Int64.of_int (List.length toc)) in
      (* Write frames per toc entry. *)
      let () = write_i64 oc frames_per_toc_entry in
      (* Write toc to file. *)
      let () = List.iter ~f:(fun offset -> write_i64 oc offset) (List.rev toc) in
      (* Now we need to write the magic number, number of trace frames,
         and the offset of field m at the start of the trace. *)
      (* Magic number. *)
      let () = Out_channel.seek oc magic_number_offset in
      let () = write_i64 oc magic_number in
      (* Trace version. *)
      let () = Out_channel.seek oc trace_version_offset in
      let () = write_i64 oc out_trace_version in
      (* CPU architecture. *)
      let () = Out_channel.seek oc bfd_arch_offset in
      (* Goodbye type safety! *)
      let () = write_i64 oc (Int64.of_int (Obj.magic arch)) in
      (* Machine type. *)
      let () = Out_channel.seek oc bfd_machine_offset in
      let () = write_i64 oc machine in
      (* Number of trace frames. *)
      let () = Out_channel.seek oc num_trace_frames_offset in
      let () = write_i64 oc num_frames in
      (* Offset of toc. *)
      let () = Out_channel.seek oc toc_offset_offset in
      let () = write_i64 oc toc_offset in
      (* Finally close the final and mark us as finished. *)
      let () = Out_channel.close oc in
      is_finished <- true

    method has_finished = is_finished

  end

class reader filename =
  let ic = In_channel.create ~binary:true filename in
  (* Verify magic number *)
  let () = if read_i64 ic <> magic_number then
      raise (Trace_exception "Magic number is incorrect") in
  (* Trace version *)
  let trace_version = read_i64 ic in
  let () = if trace_version < lowest_supported_version ||
              trace_version > highest_supported_version then
      raise (Trace_exception "Unsupported trace version") in
  (* Read arch type, break type safety *)
  let archnum = read_i64 ic in
  let () = if not (archnum < (Int64.of_int (Obj.magic Arch_bfd.Bfd_arch_last))) then
      raise (Trace_exception "Invalid architecture") in
  let arch : Arch_bfd.bfd_architecture = Obj.magic (Int64.to_int_exn archnum) in
  let machine = read_i64 ic in
  (* Read number of trace frames. *)
  let num_frames = read_i64 ic in
  (* Find offset of toc. *)
  let toc_offset = read_i64 ic in
  (* Find the toc. *)
  let () = In_channel.seek ic toc_offset in
  (* Read number of frames per toc entry. *)
  let frames_per_toc_entry = read_i64 ic in
  (* Read each toc entry. *)
  let toc_size = Int64.((Int64.pred num_frames) / frames_per_toc_entry) in
  let toc =
    let toc_rev = foldn64
        (fun acc n ->
           if n = 0L then acc else
             (read_i64 ic) :: acc
        ) [] toc_size in
    Array.of_list (List.rev toc_rev)
  in
  (* We should be at the end of the file now. *)
  let () = assert ((In_channel.pos ic) = (In_channel.length ic)) in
  object(self)
    val mutable current_frame = 0L

    method get_num_frames = num_frames

    method get_frames_per_toc_entry = frames_per_toc_entry

    method get_arch = arch

    method get_machine = machine

    method get_trace_version = trace_version

    method seek frame_number =
      (* First, make sure the frame is in range. *)
      let () = self#check_end_of_trace_num frame_number "seek to non-existent frame" in

      (* Find the closest toc entry, if any. *)
      let toc_number = Int64.(frame_number / frames_per_toc_entry) in

      current_frame <- (match toc_number with
          | 0L -> let () = In_channel.seek ic first_frame_offset in
            0L
          | _ -> let () = In_channel.seek ic toc.(Int64.to_int_exn (Int64.pred toc_number)) in
            Int64.(toc_number * frames_per_toc_entry));

      while current_frame <> frame_number do
        (* Read frame length and skip that far ahead. *)
        let frame_len = read_i64 ic in
        let () = In_channel.seek ic Int64.((In_channel.pos ic) + frame_len) in
        current_frame <- Int64.succ current_frame
      done

    method get_frame : frame =
      let () = self#check_end_of_trace "get_frame on non-existant frame" in
      let frame_len = read_i64 ic in
      if (frame_len <= 0L) then
        raise (Trace_exception (Printf.sprintf "Read zero-length frame at offset %#Lx" (LargeFile.pos_in ic)));
      let buf = String.create (Int64.to_int_exn frame_len) in
      (* Read the frame info buf. *)
      match In_channel.really_input ic ~buf:buf ~pos:0 ~len:(Int64.to_int_exn frame_len) with
      | None -> raise (Invalid_argument "really_input")
      | Some () ->
        let f = Frame_piqi.parse_frame (Piqirun.init_from_string buf) in
        let () = current_frame <- Int64.succ current_frame in
        f

    method get_frames requested_frames =
      let () = self#check_end_of_trace "get_frame on non-existant frame" in
      (* The number of frames we copy is bounded by the number of
         frames left in the trace. *)
      let 
        num_frames = min requested_frames Int64.(num_frames - current_frame)
      in
      List.rev (foldn64 ~t:1L (fun l n -> self#get_frame :: l) [] num_frames)

    method end_of_trace =
      self#end_of_trace_num current_frame

    method private end_of_trace_num frame_num =
      Int64.succ frame_num > num_frames

    method private check_end_of_trace_num frame_num msg =
      if self#end_of_trace_num frame_num then
        raise (Trace_exception msg)

    method private check_end_of_trace msg =
      if self#end_of_trace then
        raise (Trace_exception msg)

    initializer self#seek 0L
  end
