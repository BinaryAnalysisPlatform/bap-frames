open Bap.Std

type t
type frame = Frame_piqi.frame


exception Parse_error of string


val create : Uri.t -> t

val meta : t -> dict

val version : t -> int

val arch : t -> arch option

val next_frame : t -> frame option
