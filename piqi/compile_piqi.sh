#!/bin/sh

cd piqi/bil
piqic-ocaml --multi-format stmt.piqi

cd ../trace
piqic-ocaml --multi-format frame.piqi
mv frame_piqi.ml frame_piqi_ext.ml ocaml/
