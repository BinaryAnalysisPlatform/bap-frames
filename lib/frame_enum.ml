open Core_kernel

module type Enumerated = sig
  type t
  val rank : t -> int
  val all : t list
end

module type Enumerable = sig
  type t
  val to_enum : t -> int
  val of_enum : int -> t option
  val max : int
  val min : int
end

let make_values rank xs =
  List.fold ~init:Int.Map.empty
    ~f:(fun vals x -> Map.set vals ~key:(rank x) ~data:x) xs

module type Substitution = sig
  include Enumerated
  val subs : (t * int) list
end

module Substitute(S : Substitution) : Enumerated with type t = S.t  = struct
  include S

  let new_rank =
    let values = make_values rank all in
    let xs = Map.to_alist values in
    let subs = List.map ~f:(fun (x, ind) -> rank x, ind) subs in
    let values, _ =
      List.fold xs ~init:(Int.Map.empty,0) ~f:(fun (vals,ind') (ind, x) ->
          match List.find ~f:(fun (old_ind, new_ind) -> old_ind = ind) subs  with
          | None ->
            Map.set vals ~key:ind ~data:(ind', x), ind' + 1
          | Some (_, new_ind) ->
            Map.set vals ~key:ind ~data:(new_ind, x), new_ind + 1) in
    fun x -> fst @@ Map.find_exn values (rank x)

  let rank = new_rank
end

module Make(E : Enumerated) : Enumerable with type t := E.t  = struct
  include E

  let values = make_values rank all
  let of_enum i = Map.find values i
  let to_enum x = rank x
  let max = Option.value_map ~default:0 ~f:fst (Map.max_elt values)
  let min = Option.value_map ~default:0 ~f:fst (Map.min_elt values)
end

module Make_substitute(S : Substitution) : Enumerable with type t := S.t  = struct
  module E = Substitute(S)
  include Make(E)
end
