module I386 = struct
  type t =
    | Unknown
    | I386
    | I8086
    | I386_intel
    | X86_64
    | X86_64_intel
  [@@deriving enumerate]

  include Frame_enum.Make_substitute(struct
      type nonrec t = t [@@deriving enumerate]
      let subs = [X86_64, 64]
    end)
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
  [@@deriving enumerate]

  include Frame_enum.Make(struct
      type nonrec t = t [@@deriving enumerate]
    end)

end

module Mips = struct
  type t =
    |  Unknown
    |  Isa32
    |  Isa32r2
    |  Isa64
    |  Isa64r2
  [@@deriving enumerate]

  include Frame_enum.Make_substitute(struct
      type nonrec t = t [@@deriving enumerate]
      let subs = [Isa32, 32; Isa64, 64]
    end)
end

module Ppc = struct
  type t =
    |  Unknown
    |  Ppc32
    |  Ppc64
  [@@deriving enumerate]

  include Frame_enum.Make_substitute(struct
      type nonrec t = t [@@deriving enumerate]
      let subs = [Ppc32, 32; Ppc64, 64]
    end)
end

module Sparc = struct
  type t =
    |  Unknown
    |  Sparc
    |  V9
    |  V9a
    |  V9b
  [@@deriving enumerate]

  include Frame_enum.Make_substitute(struct
      type nonrec t = t [@@deriving enumerate]
      let subs = [V9, 7]
    end)
end
