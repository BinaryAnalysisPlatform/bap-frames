#!/bin/sh

cd piqi/trace/
piqic-ocaml --multi-format frame.piqi
mv frame_piqi.ml frame_piqi_ext.ml ocaml/
