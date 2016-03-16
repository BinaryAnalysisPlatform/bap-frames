# Overview
`Frames` is a format for storing execution traces. This repository contains:
- A description in [piqi](http://piqi.org/) language of the `frames` format;
- A `C` library for writing data in the `frames` format
- An `OCaml` library `bap-frames` for reading data in the `frames` format
- A BAP plugin `frame` that provides `frames` format reader for the `bap-plugins` library
- A playground `test/tracedump` to inspect the traces

# Build and install

## From sources 
```
  oasis setup
  ./configure --prefix=`opam config var prefix`
  make 
  make install
```

## From opam

1. Add our opam repository if you don't have one
   ```
   opam repository add bap git://github.com/BinaryAnalysisPlatform/bap.git
   ```
2. install 
   ```
   opam install bap-frames
   ```
