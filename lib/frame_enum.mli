open Core_kernel.Std

module type Enumerated = sig
  type t [@@deriving enumerate]
end

(** Replaces [@@deriving enum] interface from ppx_deriving. *)
module type Enumerable = sig
  include Enumerated

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


module Make(A : Enumerated)  : Enumerable with type t := A.t

module Make_substitute(S : Substitution) : Enumerable with type t := S.t
