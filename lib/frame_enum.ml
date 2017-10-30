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
  val alli : (int * t) list
end

module type Substitution = sig
  include Enumerated
  val subs : (t * int) list
end

let substitute xs ys =
  List.rev @@ fst @@
  List.fold xs
    ~init:([], 0) ~f:(fun (acc, ind) t ->
        let subs_ind = List.Assoc.find ys ~equal:(=) t in
        let ind = Option.value ~default:ind subs_ind in
        (ind, t) :: acc, ind + 1)

module Enumerate(A : Tabulated) : Enumerable with type t := A.t = struct
  include A

  let to_enum t =
    fst @@ List.find_exn ~f:(fun (_,x) -> x = t) alli

  let of_enum i =
    List.find ~f:(fun (x,_) -> x = i) alli |>
    Option.value_map ~f:(fun x -> Some (snd x)) ~default:None

  let max = Option.value_map ~default:0 ~f:fst (List.last alli)
  let min = Option.value_map ~default:0 ~f:fst (List.hd alli)
end

module Make(A : Enumerated) : Enumerable with type t := A.t = struct
  module Tabulated = struct
    include A
    let alli = List.mapi ~f:(fun i x -> i,x) all
  end

  include Enumerate(Tabulated)
end

module Make_substitute(S : Substitution) : Enumerable with type t := S.t = struct
  module Substituted = struct
    include S
    let alli = substitute all subs
  end

  include Enumerate(Substituted)
end
