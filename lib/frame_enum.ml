open Core_kernel.Std

module type Enum = sig
  type t [@@deriving enumerate]

  val to_enum : t -> int
  val of_enum : int -> t option
  val max : int
  val min : int
end

module type E = sig
  type t [@@deriving enumerate]
end

module type Substitute = sig
  include E
  val subs : (t * int) list
end

module type L = sig
  include E
  val list : (int * t) list
end

module Make_list(A : E) = struct
  include A
  let list = List.mapi all ~f:(fun i x -> i, x)
end

module Substitute(S : Substitute) = struct
  include S

  let list =
    List.map2_exn all
      (List.init (List.length all) ~f:ident)
      ~f:(fun t ind ->
          match List.Assoc.find S.subs ~equal:(=) t with
          | None -> ind, t
          | Some ind -> ind, t)
end

module Make_general(A : L) : Enum with type t := A.t = struct
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

module Make(A : E) = struct
  module L = Make_list(A)
  include Make_general(L)
end

module Make_substitute(S : Substitute) = struct
  module L = Substitute(S)
  include Make_general(L)
end


module Test = struct

  type t = A | B | C [@@deriving enumerate]

  include Make(struct
      type nonrec t = t [@@deriving enumerate]
    end)

  let check lab = function
    | false -> printf "%s failed\n" lab
    | true  -> printf "%s ok\n" lab

  let () = check "#1" (of_enum 0 = Some A)
  let () = check "#2" (of_enum 1 = Some B)
  let () = check "#3" (of_enum 2 = Some C)
  let () = check "#4" (of_enum 3 = None)
  let () = check "#5" (max = 2)
  let () = check "#6" (min = 0)
  let () = check "#7" (to_enum A = 0)
  let () = check "#8" (to_enum B = 1)
  let () = check "#9" (to_enum C = 2)
  let () = check "#10" (to_enum C = 2)
end


module Test_s = struct

  type t = A | B | C [@@deriving enumerate]

  include Make_substitute(struct
      type nonrec t = t [@@deriving enumerate]
      let subs = [B, 42;]
    end)

  let check = Test.check

  let () = check "#10" (of_enum 0 = Some A)
  let () = check "#11" (of_enum 42 = Some B)
  let () = check "#12" (of_enum 2 = Some C)
  let () = check "#13" (of_enum 1 = None)
  let () = check "#14" (max = 42)
  let () = check "#15" (min = 0)
  let () = check "#16" (to_enum A = 0)
  let () = check "#17" (to_enum B = 42)
  let () = check "#18" (to_enum C = 2)
end
