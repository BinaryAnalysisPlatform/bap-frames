open Core_kernel

module type Enumerated = sig
  type t
  val rank : t -> int
  val all : t list
end

(** Replaces [@@deriving enum] interface from ppx_deriving, that
    treats variants with argument-less constructors as
    enumerations with an integer value assigned to every constructor. *)
module type Enumerable = sig
  type t

  val to_enum : t -> int
  val of_enum : int -> t option
  val max : int
  val min : int
end

module type Substitution = sig
  include Enumerated

  (** [subs] is a list of substitions [ (t, ind); ... ], where
      an explicit index [ind] is set to a particular variant [t]. *)
  val subs : (t * int) list
end

module Make(A : Enumerated) : Enumerable with type t := A.t
module Make_substitute(S : Substitution) : Enumerable with type t := S.t
