open Core_kernel.Std
open OUnit2
open Frame_enum

type t = A | B | C [@@deriving enumerate]

module E = struct
  include Make(struct
      type nonrec t = t [@@deriving enumerate]
    end)
end

module S = struct
  include Make_substitute(struct
      type nonrec t = t [@@deriving enumerate]
      let subs = [B, 42;]
    end)
end

let check x ctxt = assert_bool "test_enum failed" x

let suite () =
  "Frame_enum"  >::: [
    "of_enum 0" >:: check (E.of_enum 0 = Some A);
    "of_enum 1" >:: check (E.of_enum 1 = Some B);
    "of_enum 2" >:: check (E.of_enum 2 = Some C);
    "of_enum 3" >:: check (E.of_enum 3 = None);
    "max"       >:: check (E.max = 2);
    "min"       >:: check (E.min = 0);
    "to_enum A" >:: check (E.to_enum A = 0);
    "to_enum B" >:: check (E.to_enum B = 1);
    "to_enum C" >:: check (E.to_enum C = 2);
    "substitute.of_enum 0" >:: check (S.of_enum 0 = Some A);
    "substitute.of_enum 1" >:: check (S.of_enum 42 = Some B);
    "substitute.of_enum 2" >:: check (S.of_enum 2 = Some C);
    "substitute.of_enum 3" >:: check (S.of_enum 1 = None);
    "substitute.max"       >:: check (S.max = 42);
    "substitute.min"       >:: check (S.min = 0);
    "substitute.to_enum A" >:: check (S.to_enum A = 0);
    "substitute.to_enum B" >:: check (S.to_enum B = 42);
    "substitute.to_enum C" >:: check (S.to_enum C = 2);
  ]
