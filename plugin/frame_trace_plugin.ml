open Core_kernel
open Bap.Std
open Bap_traces.Std
include Self()

let create_frame_reader uri =
  let reader = Frame_reader.create uri in
  let arch = Frame_reader.arch reader in
  object(self)
    val mutable events : value list = []
    val context =
      object
        val mutable tid = None
        method switch id' =
          match tid with
          | Some id when Int64.equal id id' -> false
          | _ -> tid <- Some id'; true
      end

    method meta = Frame_reader.meta reader

    method next =
      match events with
      | e :: ev -> events <- ev; Some (Ok e)
      | [] -> match Frame_reader.next_frame reader with
        | None -> None
        | Some frame ->
          events <-
            Frame_events.of_frame ?arch ~context:context#switch frame;
          self#next
        | exception exn -> Some (Error (Error.of_exn exn))
  end

module Frame_proto : Trace.P = struct
  let name = "frame-trace"

  let supports tag =
    let checkers =
      let same = Value.Tag.same in
      Event.[
        same pc_update;
        same context_switch;
        same code_exec;
        same memory_load;
        same memory_store;
        same register_read;
        same register_write ] in
    List.exists ~f:(fun same -> same tag) checkers

  let probe uri =
    (match Uri.scheme uri with
      | Some s -> String.equal s "file"
      | None -> false) &&
    Filename.check_suffix (Uri.path uri) ".frames"
end

let build_reader tool uri id =
  let build () =
    let reader = create_frame_reader uri in
    Trace.Reader.{ tool; meta = reader#meta; next = fun () -> reader#next } in
  try Ok (build ()) with
  | Caml_unix.Unix_error (err, _, _) -> Result.fail (`System_error err)
  | exn -> Result.fail (`Protocol_error (Error.of_exn  exn))

let () =
  let tool = Trace.register_tool (module Frame_proto : Trace.S) in
  let proto = Trace.register_proto (module Frame_proto) in
  Trace.register_reader proto @@ build_reader tool
