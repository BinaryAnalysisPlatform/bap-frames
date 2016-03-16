plugin:
	touch frames.ml
	bapbuild -package bap-plugin-frames frames.plugin
	bapbundle update -desc "`ocamlfind query -format "%D" bap-plugin-frames`" frames.plugin
	bapbundle install frames.plugin
	bapbuild -clean
	rm frames.ml
