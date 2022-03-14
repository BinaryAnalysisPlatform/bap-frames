open Core_kernel

(** Type definitions from BFD library.

    Note: this definitions are taken from a correspoind
    libtrace/arch.hpp header file and doesn't correspond to
    a most recent version of the BFD library.

    A enum [X_Y_Z] in general maps to [X.Y.Z] constructor,
    with the following caveats:
    - [X],[Y] and [Z] are capitalized
    - sometimes, BFD break there own naming scheme, so [X.Y]
    sometimes maps to [X._.Y], e.g., [bfd_mach_arm] maps to
    [Bfd.Mach.Arm.Arm], c.f., a more correct [bfd_mach_i386_i386],
    that maps to [Bfd.Mach.I386.I386]

    The [enum] processor will derive the following functions:
    - [to_enum : t -> int]
    - [of_enum : int -> t option]
    - [max, min]
*)
type t =
  | Unknown
  | Obscure
  | M68k
  | Vax
  | I960
  | Or32
  | Sparc
  | Spu
  | Mips
  | I386
  | L1om
  | We32k
  | Tahoe
  | I860
  | I370
  | Romp
  | Convex
  | M88k
  | M98k
  | Pyramid
  | H8300
  | Pdp11
  | Plugin
  | Powerpc
  | Rs6000
  | Hppa
  | D10v
  | D30v
  | Dlx
  | M68hc11
  | M68hc12
  | Z8k
  | H8500
  | Sh
  | Alpha
  | Arm
  | Ns32k
  | W65
  | Tic30
  | Tic4x
  | Tic54x
  | Tic6x
  | Tic80
  | V850
  | Arc
  | M32c
  | M32r
  | Mn10200
  | Mn10300
  | Fr30
  | Frv
  | Moxie
  | Mcore
  | Mep
  | Ia64
  | Ip2k
  | Iq2000
  | Mt
  | Pj
  | Avr
  | Bfin
  | Cr16
  | Cr16c
  | Crx
  | Cris
  | Rx
  | S390
  | Score
  | Openrisc
  | Mmix
  | Xstormy16
  | Msp430
  | Xc16x
  | Xtensa
  | Z80
  | Lm32
  | Microblaze
  | M6502
  | AArch64
  | Last
[@@deriving enumerate, variants]

include Frame_enum.Make(struct
    type nonrec t = t
    let rank = Variants.to_rank
    let all = all
  end)
