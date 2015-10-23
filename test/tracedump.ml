open Core_kernel.Std
open Bap.Std
open Result
open Cmdliner

let () = Frame_trace_plugin.register ()

let uri =
  let doc = "Trace resource identifier RFC3986." in
  let uri =
    let uri_parser str =
      try `Ok (Uri.of_string str) with
        exn -> `Error (Printf.sprintf "bad uri address") in
    let uri_printer fmt u =
      Uri.to_string u |> Format.pp_print_string fmt in
    uri_parser, uri_printer in
  Arg.(required & pos 0 (some uri) None & info [] ~doc ~docv:"URI")

let print_error = function
  | `Protocol_error err -> Error.pp Format.err_formatter err
  | `System_error err -> prerr_string @@ Unix.error_message err
  | `No_provider -> prerr_string "No provider for a given URI"
  | `Ambiguous_uri -> prerr_string "More than one provider for a given URI"
  
let main uri =
  Trace.load uri >>|
  Trace.events >>|
  Sequence.iter ~f:(Format.printf "@[%a@]@." Value.pp)

let cmd =
  let doc = "tracedump" in
  let man = [
    `S "DESCTIPTION";
    `P "dump trace frame events to stdout"
  ] in
  Term.(pure main $ uri),
  Term.info "tracedump" ~doc ~man

let () = 
  match Term.eval cmd with 
  | `Error _ -> exit 1 
  | `Ok result ->
    begin
      match result with
      | Error e -> print_error e; exit 2
      | _ -> exit 0
    end
  | `Version
  | `Help -> exit 0

