open Core_kernel.Std

module type E = sig
  type t [@@deriving enumerate]
end

module type Enum = sig
  include E

  val to_enum : t -> int
  val of_enum : int -> t option
  val max : int
  val min : int
end

module type L = sig
  include E
  val list : (int * t) list
end

module Make_list(A : E) = struct
  include A
  let list = List.mapi all ~f:(fun i x -> i, x)
end

module Make_enum(A : L) : Enum with type t := A.t = struct
  include A

  let sorted = List.sort ~cmp:(fun (i,_) (j,_) -> compare i j) list

  let to_enum t =
    fst @@ List.find_exn ~f:(fun (_,x) -> x = t) list

  let of_enum i =
    List.find ~f:(fun (x,_) -> x = i) list |>
    Option.value_map ~f:(fun x -> Some (snd x)) ~default:None

  let max = fst @@ List.last_exn sorted
  let min = fst @@ List.hd_exn sorted
end

module type Substitute = sig
  include E
  val subs : (t * int) list
end

module Make_substitution(S : Substitute) = struct
  include S

  let list =
    List.map2_exn all
      (List.init (List.length all) ~f:ident)
      ~f:(fun t ind ->
          match List.Assoc.find S.subs ~equal:(=) t with
          | None -> ind, t
          | Some ind -> ind, t)
end

module Make(A : E) = struct
  module L = Make_list(A)
  include Make_enum(L)
end

module Make_substitute(S : Substitute) = struct
  module L = Make_substitution(S)
  include Make_enum(L)
end
