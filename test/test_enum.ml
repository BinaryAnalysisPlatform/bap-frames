open Core_kernel.Std
open OUnit2
open Frame_enum

type t = A | B | C | D | E [@@deriving enumerate, variants]

module E = struct
  include Make(struct
      type nonrec t = t
      let rank = Variants.to_rank
      let all = all
    end)
end

module S = struct
  include Make_substitute(struct
      type nonrec t = t
      let subs = [B, 42; D, 56;]
      let rank = Variants.to_rank
      let all = all
    end)
end

let check x ctxt = assert_bool "test_enum failed" x

let suite () =
  "Frame_enum"  >::: [
    "of_enum 0" >:: check (E.of_enum 0 = Some A);
    "of_enum 1" >:: check (E.of_enum 1 = Some B);
    "of_enum 2" >:: check (E.of_enum 2 = Some C);
    "of_enum 3" >:: check (E.of_enum 3 = Some D);
    "of_enum 4" >:: check (E.of_enum 4 = Some E);
    "of_enum 5" >:: check (E.of_enum 5 = None);
    "max"       >:: check (E.max = 4);
    "min"       >:: check (E.min = 0);
    "to_enum A" >:: check (E.to_enum A = 0);
    "to_enum B" >:: check (E.to_enum B = 1);
    "to_enum C" >:: check (E.to_enum C = 2);
    "to_enum D" >:: check (E.to_enum D = 3);
    "to_enum E" >:: check (E.to_enum E = 4);
    "substitute.of_enum 0" >:: check (S.of_enum 0 = Some A);
    "substitute.of_enum 42" >:: check (S.of_enum 42 = Some B);
    "substitute.of_enum 43" >:: check (S.of_enum 43 = Some C);
    "substitute.of_enum 56" >:: check (S.of_enum 56 = Some D);
    "substitute.of_enum 57" >:: check (S.of_enum 57 = Some E);
    "substitute.of_enum 3" >:: check (S.of_enum 1 = None);
    "substitute.max"       >:: check (S.max = 57);
    "substitute.min"       >:: check (S.min = 0);
    "substitute.to_enum A" >:: check (S.to_enum A = 0);
    "substitute.to_enum B" >:: check (S.to_enum B = 42);
    "substitute.to_enum C" >:: check (S.to_enum C = 43);
    "substitute.to_enum D" >:: check (S.to_enum D = 56);
    "substitute.to_enum E" >:: check (S.to_enum E = 57);
  ]
