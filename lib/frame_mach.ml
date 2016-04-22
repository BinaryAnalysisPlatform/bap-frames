module I386 = struct
  type t =
    | Unknown
    | I386          [@value 1]
    | I8086
    | I386_intel
    | X86_64        [@value 64]
    | X86_64_intel
    [@@deriving enum]
end

module Arm = struct
  type t =
    |  Unknown
    |  V2
    |  V2a
    |  V3
    |  V3M
    |  V4
    |  V4T
    |  V5
    |  V5T
    |  V5TE
    |  XScale
    |  Ep9312
    |  Iwmmxt
    |  Iwmmxt2
    [@@deriving enum]
end

module Mips = struct
  type t =
    |  Unknown [@value  0]
    |  Isa32   [@value 32]
    |  Isa32r2
    |  Isa64   [@value 64]
    |  Isa64r2
    [@@deriving enum]
end

module Ppc = struct
  type t =
    |  Unknown   [@value  0]
    |  Ppc32     [@value 32]
    |  Ppc64     [@value 64]
    [@@deriving enum]
end

module Sparc = struct
  type t =
    |  Unknown [@value 0]
    |  Sparc   [@value 1]
    |  V9      [@value 7]
    |  V9a
    |  V9b
    [@@deriving enum]
end
