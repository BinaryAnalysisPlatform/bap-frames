# Overview
`Frames` is a format for storing execution traces. This repository contains:
- A description in [piqi](http://piqi.org/) language of the `frames` format;
- A `C++` library for writing data in the `frames` format
- An `OCaml` library `bap-frames` for reading data in the `frames` format
- A BAP plugin `frame` that provides `frames` format reader for the `bap-plugins` library

# Build and install

## OCaml bap-frames library
### From sources
```
  oasis setup
  ./configure --prefix=`opam config var prefix`
  make
  make install
```

### From opam

1. Add our opam repository if you don't have one

   ```
   opam repository add bap git://github.com/BinaryAnalysisPlatform/opam-repository.git
   ```
2. install

   ```
   opam install bap-frames
   ```

## C++ `libtrace` library

1. Install [piqi](https://piqi.org/downloads/) so you have the `piqi` binary in `PATH`.

2. Install `protobuf-devel` (Debian: `libprotobuf-dev`).

3. Generate configuration files
   ```
   cd libtrace
   ./autogen.sh
   ```

4. Configure (use configuration options to your taste)
   ```
   ./configure
   ```

5. Compile and install
   ```
   make
   make install
   ```
