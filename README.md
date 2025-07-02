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

1. Generate configuration files
   ```
   cd libtrace
   ./autogen.sh
   ```

2. Configure (use configuration options to your taste)
   ```
   ./configure
   ```

3. Compile and install
   ```
   make
   make install
   ```

## Trace format

The trace consists of three parts: the header,
a table of contents (TOC) holding the frames, and an index into the TOC.

A fixed number of frames are considered _one entry_ in the TOC.
Frames in each entry starts with the size of the frame, followed by the actual frame data.
Then the next frame size followed by the frame data and so forth.

The TOC index is stored at the end.

[!IMPORTANT]
The last TOC entry might holds less than `m` frames.

For specifics about the frame contents, please check the definitions in the [piqi](piqi/) directory.

**Format**

| Offset | Type | Field | Note |
|--------|------|-------|------|
|    0x0    | uint64_t | magic number (7456879624156307493LL) | Header begin |
|    0x8    | uint64_t | trace version number | |
|    0x10    | uint64_t | frame_architecture | |
|    0x18    | uint64_t | frame_machine, 0 for unspecified. | |
|    0x20    | uint64_t | n = total number of frames in trace. | |
|    0x28    | uint64_t | T = offset to TOC index. | |
|    0x30    | uint64_t | sizeof(frame_0) | TOC begin  |
|    0x38    | meta_frame   | frame_0 | |
|    0x40    | uint64_t     | sizeof(frame_1) | |
|    0x48    | type(frame_1) | frame_1 | |
|    ...     | ...          | ... | |
|    T-0x10  | uint64_t     | sizeof(frame_n-1) | |
|    T-0x8   | type(frame_n-1) | frame_n-1 | |
|    T+0     | uint64_t     | m = maximum number of frames per TOC entry | TOC index begin |
|    T+0x8   | uint64_t     | offset toc_entry(0) | |
|    T+0x10  | uint64_t     | offset toc_entry(1) | |
|    ...     | ...          | ... | |
|    T+0x8+(0x8*ceil(n/m))   | uint64_t     | offset toc_entry(ceil(n/m)) | |
