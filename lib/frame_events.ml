open Core_kernel
open Bap.Std
open Bap_traces.Std
open Event

module Frame = Frame_piqi
module EF : sig
  val memory_load :
    arch option ->
    Frame.mem_operand ->
    Frame.bit_length ->
    Frame.binary -> Trace.event

  val memory_store :
    arch option ->
    Frame.mem_operand ->
    Frame.bit_length ->
    Frame.binary -> Trace.event

  val register_read :
    arch option ->
    Frame.reg_operand ->
    Frame.bit_length ->
    Frame.binary -> Trace.event

  val register_write :
    arch option ->
    Frame.reg_operand ->
    Frame.bit_length ->
    Frame.binary -> Trace.event

  (* val timestamp : int64 -> Trace.event *)

  val pc_update : arch option -> Frame.address -> Trace.event

  val code_exec : arch option -> Frame.address -> Frame.binary -> Trace.event

  val context_switch : Frame.thread_id -> Trace.event

  val syscall : number:Frame.uint64 -> Frame.argument_list -> Trace.event

  val exn :
    arch option ->
    Frame.exception_number ->
    from_addr:Frame.address option ->
    to_addr:Frame.address option -> Trace.event

  val modload : arch option ->
    string -> Frame.address -> Frame.address -> Trace.event

  val mode : string -> Trace.event

  (* val call : ??? *)
  (* val return : ??? *)
end = struct
  let addr_of_address arch address =
    match Option.value_map arch ~default:`r32 ~f:Arch.addr_size with
    | `r32 -> Bitvector.of_int64 ~width:32 address
    | `r64 -> Bitvector.of_int64 ~width:64 address

  let move arch tag cell width value =
    let data =
      let endian =
        Option.value_map arch ~default:Bitvector.LittleEndian ~f:Arch.endian in
      let width = match width with 0 -> None | w -> Some w in
      Bitvector.of_binary ?width endian value in
    Move.Fields.create ~cell ~data |>
    Value.create tag

  let memory_operation arch tag mo width value =
    move arch tag (addr_of_address arch mo.Frame.Mem_operand.address)
      width value

  let memory_load arch mo width value =
    memory_operation arch memory_load mo width value

  let memory_store arch mo width value =
    memory_operation arch memory_store mo width value

  let register_operation arch tag ro width value =
    move arch tag (Var.create ro.Frame.Reg_operand.name @@ Type.imm width)
      width value

  let register_read arch ro width value =
    register_operation arch register_read ro width value

  let register_write arch ro width value =
    register_operation arch register_write ro width value

  let pc_update arch address =
    Value.create pc_update (addr_of_address arch address)

  let code_exec arch address data =
    Chunk.Fields.create ~addr:(addr_of_address arch address) ~data |>
    Value.create code_exec

  let context_switch id =
    Value.create context_switch @@ Int64.to_int_exn id

  let syscall ~number args =
    Syscall.Fields.create
      ~number:(Int64.to_int_exn number)
      ~args:(Array.of_list @@ List.map ~f:Bitvector.of_int64 args) |>
    Value.create syscall

  let exn arch number ~from_addr ~to_addr =
    Exn.Fields.create
      ~number:(Int64.to_int_exn number)
      ~src:(Option.map from_addr ~f:(addr_of_address arch))
      ~dst:(Option.map to_addr ~f:(addr_of_address arch)) |>
    Value.create exn

  let modload arch name low high =
    Modload.Fields.create
      ~name
      ~low:(addr_of_address arch low)
      ~high:(addr_of_address arch high) |>
    Value.create modload

  let mode (fe : string) =
    Value.create mode (try Mode.read fe with _exn -> Mode.unknown)
end

let of_new_frame context arch address thread_id =
  if context thread_id then
    [EF.pc_update arch address; EF.context_switch thread_id]
  else
    [EF.pc_update arch address]

let of_operand_usage usage of_read of_written bit_length binary =
  let open Frame.Operand_usage in
  match usage.read, usage.written with
  | true, true -> [of_read bit_length binary;
                   of_written bit_length binary]
  | true, false -> [of_read bit_length binary]
  | false, true -> [of_written bit_length binary]
  | false, false -> [] (*FIXME: error occure?*)

let of_mem_operand arch mo usage bit_length binary =
  of_operand_usage usage
    (EF.memory_load arch mo)
    (EF.memory_store arch mo)
    bit_length binary

let of_reg_operand arch ro usage bit_length binary =
  of_operand_usage usage (EF.register_read arch ro) (EF.register_write arch ro)
    bit_length binary

let of_operand_info arch oi =
  let open Frame.Operand_info in
  match oi.operand_info_specific with
  | `mem_operand mo ->
    of_mem_operand arch mo oi.operand_usage oi.bit_length oi.value
  | `reg_operand ro ->
    of_reg_operand arch ro oi.operand_usage oi.bit_length oi.value

let of_operand_value_list arch ovl =
  List.concat @@ List.map ~f:(of_operand_info arch) ovl

let of_mode mode = [EF.mode mode]

let of_std_frame context arch frm =
  let open Frame.Std_frame in
  List.concat [of_new_frame context arch frm.address frm.thread_id;
               Option.value_map frm.mode ~default:[] ~f:(of_mode);
               [EF.code_exec arch frm.address frm.rawbytes];
               of_operand_value_list arch frm.operand_pre_list;
               Option.value_map frm.operand_post_list ~default:[]
                 ~f:(of_operand_value_list arch)]

let of_syscall_frame context arch frm =
  let open Frame.Syscall_frame in
  (of_new_frame context arch frm.address frm.thread_id) @
  [EF.syscall ~number:frm.number frm.argument_list]

let of_exception_frame context arch frm =
  let open Frame.Exception_frame in
  let exn_event = EF.exn arch frm.exception_number
      ~from_addr:frm.from_addr
      ~to_addr:frm.to_addr in
  match frm.thread_id with
  | Some tid when context tid -> [EF.context_switch tid;  exn_event]
  | _ -> [exn_event]

let of_modload_frame arch frm =
  let open Frame.Modload_frame in
  [EF.modload arch frm.module_name frm.low_address frm.high_address]


let of_frame ~context ?arch = function
  | `std_frame frm -> of_std_frame context arch frm
  | `syscall_frame frm ->
    of_syscall_frame context arch frm
  | `exception_frame frm -> of_exception_frame context arch frm
  | `taint_intro_frame frm -> []
  | `modload_frame frm -> of_modload_frame arch frm
  | `key_frame frm -> []
  | `meta_frame _ -> []
