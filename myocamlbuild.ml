(* OASIS_START *)
(* OASIS_STOP *)
let oasis_env =
  BaseEnvLight.load
    ~filename:MyOCamlbuildBase.env_filename
    ~allow_empty:true
    ()
let nonempty = function (A s) -> String.length s != 0 | _ -> true
let expand s = BaseEnvLight.var_expand s oasis_env;;

rule "piqic: piqi -> .ml & _ext.ml"
  ~prods:["%_piqi.ml"; "%_piqi_ext.ml"]
  ~deps:["%.piqi"]
  (fun env _ ->
     Cmd(S (List.filter nonempty [A (expand "${piqic}"); A (expand "${piqic_flags}"); A "-I"; A ".."; A (env "%.piqi"); A"--multi-format"])));;

Ocamlbuild_plugin.dispatch dispatch_default;;
