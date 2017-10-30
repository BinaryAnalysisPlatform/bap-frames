open Core_kernel.Std

module type Enumerated = sig
  type t [@@deriving enumerate]
end

module type Enumerable = sig
  include Enumerated

  val to_enum : t -> int
  val of_enum : int -> t option
  val max : int
  val min : int
end

module type Tabulated = sig
  include Enumerated
  val list : (int * t) list
end

module Tabulate(A : Enumerated) : Tabulated with type t = A.t = struct
  include A
  let list = List.mapi all ~f:(fun i x -> i, x)
end

module Enumerate(A : Tabulated) : Enumerable with type t := A.t = struct
  include A

  let to_enum t =
    fst @@ List.find_exn ~f:(fun (_,x) -> x = t) list

  let of_enum i =
    List.find ~f:(fun (x,_) -> x = i) list |>
    Option.value_map ~f:(fun x -> Some (snd x)) ~default:None

  let max = match List.hd (List.rev list) with
    | None -> 0
    | Some x -> fst x

  let min = match List.hd list with
    | None -> 0
    | Some x -> fst x
end

module type Substitution = sig
  include Enumerated
  val subs : (t * int) list
end

module Substitute(S : Substitution) = struct
  include S

  let list =
    List.rev @@
    fst @@
    List.fold all
      ~init:([],0)
      ~f:(fun (acc, ind) t ->
          let subs_ind = List.Assoc.find S.subs ~equal:(=) t in
          let ind = Option.value ~default:ind subs_ind in
          (ind, t) :: acc, ind + 1)
end

module Make(A : Enumerated) = struct
  module L = Tabulate(A)
  include Enumerate(L)
end

module Make_substitute(S : Substitution) = struct
  module L = Substitute(S)
  include Enumerate(L)
end
