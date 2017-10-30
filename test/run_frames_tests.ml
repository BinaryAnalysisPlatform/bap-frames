
open OUnit2

let suite () =
  "Bap-frames" >::: [
    Test_enum.suite ();
  ]

let () = run_test_tt_main (suite ())
