open Core_kernel.Std

module V = Var
open Bil
open Stmt_piqi
open Type

type program = Bil.stmt list

let casttype_to_piqi : Type.cast_type -> Stmt_piqi.cast_type = function
  | CAST_UNSIGNED -> `cast_unsigned
  | CAST_SIGNED -> `cast_signed
  | CAST_HIGH -> `cast_high
  | CAST_LOW -> `cast_low

let unop_to_piqi : Type.unop_type -> Stmt_piqi.unop_type = function
  | NEG -> `uneg
  | NOT -> `unot

let binop_to_piqi : Type.binop_type -> Stmt_piqi.binop_type = function
  | PLUS -> `plus
  | MINUS -> `minus
  | TIMES -> `times
  | DIVIDE -> `divide
  | SDIVIDE -> `sdivide
  | MOD -> `modbop
  | SMOD -> `smod
  | LSHIFT -> `lshift
  | RSHIFT -> `rshift
  | ARSHIFT -> `arshift
  | AND -> `andbop
  | OR -> `orbop
  | XOR -> `xor
  | EQ -> `eq
  | NEQ -> `neq
  | LT -> `lt
  | LE -> `le
  | SLT -> `slt
  | SLE -> `sle

let rec type_to_piqi : Type.typ -> Stmt_piqi.typ = function
  | Reg n -> `reg n
  | TMem (t, t') -> `tmem ({Tmem.index_type=type_to_piqi t; element_type=type_to_piqi t';})

let var_to_piqi v : Stmt_piqi.var =
  {Var.name=V.name v; Var.id=V.hash v; Var.typ = type_to_piqi (V.typ v)}

let endianness_to_piqi : Bil.endian -> Stmt_piqi.endian = function
  | LittleEndian -> `little_endian
  | BigEndian -> `big_endian

let rec exp_to_piqi : Bil.exp -> Stmt_piqi.exp = function
  | Load (m, i, e, t) ->
    let m = exp_to_piqi m in
    let i = exp_to_piqi i in
    let e = endianness_to_piqi e in
    let t = type_to_piqi t in
    `load {Load.memory=m; Load.address=i; Load.endian=e; Load.typ=t;}
  | Store (m, i, v, e, t) ->
    let m = exp_to_piqi m in
    let i = exp_to_piqi i in
    let v = exp_to_piqi v in
    let e = endianness_to_piqi e in
    let t = type_to_piqi t in
    `store {Store.memory=m; Store.address=i; Store.value=v; Store.endian=e; Store.typ=t;}
  | BinOp (bop, e1, e2) ->
    let bop = binop_to_piqi bop in
    let e1 = exp_to_piqi e1 in
    let e2 = exp_to_piqi e2 in
    `binop {Binop.op=bop; Binop.lexp=e1; Binop.rexp=e2;}
  | UnOp (uop, e) ->
    let uop = unop_to_piqi uop in
    let e = exp_to_piqi e in
    `unop {Unop.op=uop; Unop.exp=e}
  | Var v ->
    `var (var_to_piqi v)
  | Int i ->
    let i = String.of_char_list (Bitvector.bytes_of i) in
    `inte {Inte.int=i;}
  | Cast (ct, t, e) ->
    let ct = casttype_to_piqi ct in
    let t = type_to_piqi t in
    let e = exp_to_piqi e in
    `cast {Cast.cast_type=ct; Cast.new_type=t; Cast.exp=e}
  | Let (v, e, e') ->
    let v = var_to_piqi v in
    let e = exp_to_piqi e in
    let e' = exp_to_piqi e' in
    `let_exp {Let_exp.bound_var=v; Let_exp.definition=e; Let_exp.open_exp=e'}
  | Unknown (s, t) ->
    let t = type_to_piqi t in
    `unknown {Unknown.descr=s; Unknown.typ=t}
  | Ite (e, te, fe) ->
    let e = exp_to_piqi e in
    let te = exp_to_piqi te in
    let fe = exp_to_piqi fe in
    `ite({Ite.condition=e; Ite.iftrue=te; Ite.iffalse=fe})
  | Extract (h, l, e) ->
    let e = exp_to_piqi e in
    `extract {Extract.hbit=h; Extract.lbit=l; Extract.exp=e}
  | Concat(e1, e2) ->
    let e1 = exp_to_piqi e1 in
    let e2 = exp_to_piqi e2 in
    `concat {Concat.lexp=e1; Concat.rexp=e2}

let rec stmt_to_piqi : Bil.stmt -> Stmt_piqi.stmt = function
  | Move(v, e) ->
    let v = var_to_piqi v in
    let e = exp_to_piqi e in
    `move {Move.lvar=v; rexp=e}
  | Jmp targ ->
    let targ = exp_to_piqi targ in
    `jmp {Jmp.target=targ}
  | Special s -> `special s
  | While (e, stmts) ->
    let e = exp_to_piqi e in
    let stmts = prog_to_piqi stmts in
    `while_stmt {While_stmt.cond=e; loop_body=stmts}
  | If (e, then_branch, else_branch) ->
    let e = exp_to_piqi e in
    let then_branch = prog_to_piqi then_branch in
    let else_branch = prog_to_piqi else_branch in
    `if_stmt {If_stmt.cond=e; true_branch=then_branch; false_branch=else_branch}
  | CpuExn n -> `cpuexn {Cpuexn.errno=n}

and prog_to_piqi l = List.map ~f:stmt_to_piqi l

let to_pb p = Stmt_piqi_ext.gen_stmt_list (prog_to_piqi p) `pb
let to_json p = Stmt_piqi_ext.gen_stmt_list (prog_to_piqi p) `json
let to_xml p = Stmt_piqi_ext.gen_stmt_list (prog_to_piqi p) `xml
