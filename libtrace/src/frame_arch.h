#ifndef _FRAME_ARCH_H
#define _FRAME_ARCH_H

/** Defines a wiring protocol for architectures and machine types. Any
    change to this types definitions should preserve backward
    compatibility, i.e., new architectures should added to the end of
    the enum, machine numbers should be changed.


    History: this file was orignally extracted from some version of BFD library,
    but since that time the BFD library changed their own definitions several
    times. Moreover, in BFD it was never designed with a binary compatibility in
    mind and actually is generated every time with a configure script. So even the
    same versions may have different values, depending on configure option.

    We renamed the namespace prefix from `bfd_` to `frame_` to avoid confusion with
    the values defined in BFD architecture.

    Note: QEMU itself has a similiar file in their codebase, it was copied from GDB
    at 1999, and never changed since that time. But they have definitions, that are
    incompatible with this file.

 */

enum frame_architecture
{
  frame_arch_unknown,   /* File arch not known.  */
  frame_arch_obscure,   /* Arch known, not one of these.  */
  frame_arch_m68k,      /* Motorola 68xxx */
#define frame_mach_m68000 1
#define frame_mach_m68008 2
#define frame_mach_m68010 3
#define frame_mach_m68020 4
#define frame_mach_m68030 5
#define frame_mach_m68040 6
#define frame_mach_m68060 7
#define frame_mach_cpu32  8
#define frame_mach_fido   9
#define frame_mach_mcf_isa_a_nodiv 10
#define frame_mach_mcf_isa_a 11
#define frame_mach_mcf_isa_a_mac 12
#define frame_mach_mcf_isa_a_emac 13
#define frame_mach_mcf_isa_aplus 14
#define frame_mach_mcf_isa_aplus_mac 15
#define frame_mach_mcf_isa_aplus_emac 16
#define frame_mach_mcf_isa_b_nousp 17
#define frame_mach_mcf_isa_b_nousp_mac 18
#define frame_mach_mcf_isa_b_nousp_emac 19
#define frame_mach_mcf_isa_b 20
#define frame_mach_mcf_isa_b_mac 21
#define frame_mach_mcf_isa_b_emac 22
#define frame_mach_mcf_isa_b_float 23
#define frame_mach_mcf_isa_b_float_mac 24
#define frame_mach_mcf_isa_b_float_emac 25
#define frame_mach_mcf_isa_c 26
#define frame_mach_mcf_isa_c_mac 27
#define frame_mach_mcf_isa_c_emac 28
#define frame_mach_mcf_isa_c_nodiv 29
#define frame_mach_mcf_isa_c_nodiv_mac 30
#define frame_mach_mcf_isa_c_nodiv_emac 31
  frame_arch_vax,       /* DEC Vax */
  frame_arch_i960,      /* Intel 960 */
    /* The order of the following is important.
       lower number indicates a machine type that
       only accepts a subset of the instructions
       available to machines with higher numbers.
       The exception is the "ca", which is
       incompatible with all other machines except
       "core".  */

#define frame_mach_i960_core      1
#define frame_mach_i960_ka_sa     2
#define frame_mach_i960_kb_sb     3
#define frame_mach_i960_mc        4
#define frame_mach_i960_xa        5
#define frame_mach_i960_ca        6
#define frame_mach_i960_jx        7
#define frame_mach_i960_hx        8

  frame_arch_or32,      /* OpenRISC 32 */

  frame_arch_sparc,     /* SPARC */
#define frame_mach_sparc                 1
/* The difference between v8plus and v9 is that v9 is a true 64 bit env.  */
#define frame_mach_sparc_sparclet        2
#define frame_mach_sparc_sparclite       3
#define frame_mach_sparc_v8plus          4
#define frame_mach_sparc_v8plusa         5 /* with ultrasparc add'ns.  */
#define frame_mach_sparc_sparclite_le    6
#define frame_mach_sparc_v9              7
#define frame_mach_sparc_v9a             8 /* with ultrasparc add'ns.  */
#define frame_mach_sparc_v8plusb         9 /* with cheetah add'ns.  */
#define frame_mach_sparc_v9b             10 /* with cheetah add'ns.  */
/* Nonzero if MACH has the v9 instruction set.  */
#define frame_mach_sparc_v9_p(mach) \
  ((mach) >= frame_mach_sparc_v8plus && (mach) <= frame_mach_sparc_v9b \
   && (mach) != frame_mach_sparc_sparclite_le)
/* Nonzero if MACH is a 64 bit sparc architecture.  */
#define frame_mach_sparc_64bit_p(mach) \
  ((mach) >= frame_mach_sparc_v9 && (mach) != frame_mach_sparc_v8plusb)
  frame_arch_spu,       /* PowerPC SPU */
#define frame_mach_spu           256
  frame_arch_mips,      /* MIPS Rxxxx */
#define frame_mach_mips3000              3000
#define frame_mach_mips3900              3900
#define frame_mach_mips4000              4000
#define frame_mach_mips4010              4010
#define frame_mach_mips4100              4100
#define frame_mach_mips4111              4111
#define frame_mach_mips4120              4120
#define frame_mach_mips4300              4300
#define frame_mach_mips4400              4400
#define frame_mach_mips4600              4600
#define frame_mach_mips4650              4650
#define frame_mach_mips5000              5000
#define frame_mach_mips5400              5400
#define frame_mach_mips5500              5500
#define frame_mach_mips6000              6000
#define frame_mach_mips7000              7000
#define frame_mach_mips8000              8000
#define frame_mach_mips9000              9000
#define frame_mach_mips10000             10000
#define frame_mach_mips12000             12000
#define frame_mach_mips14000             14000
#define frame_mach_mips16000             16000
#define frame_mach_mips16                16
#define frame_mach_mips5                 5
#define frame_mach_mips_loongson_2e      3001
#define frame_mach_mips_loongson_2f      3002
#define frame_mach_mips_sb1              12310201 /* octal 'SB', 01 */
#define frame_mach_mips_octeon           6501
#define frame_mach_mips_xlr              887682   /* decimal 'XLR'  */
#define frame_mach_mipsisa32             32
#define frame_mach_mipsisa32r2           33
#define frame_mach_mipsisa64             64
#define frame_mach_mipsisa64r2           65
  frame_arch_i386,      /* Intel 386 */
#define frame_mach_i386_i386 1
#define frame_mach_i386_i8086 2
#define frame_mach_i386_i386_intel_syntax 3
#define frame_mach_x86_64 64
#define frame_mach_x86_64_intel_syntax 65
  frame_arch_l1om,   /* Intel L1OM */
#define frame_mach_l1om 66
#define frame_mach_l1om_intel_syntax 67
  frame_arch_we32k,     /* AT&T WE32xxx */
  frame_arch_tahoe,     /* CCI/Harris Tahoe */
  frame_arch_i860,      /* Intel 860 */
  frame_arch_i370,      /* IBM 360/370 Mainframes */
  frame_arch_romp,      /* IBM ROMP PC/RT */
  frame_arch_convex,    /* Convex */
  frame_arch_m88k,      /* Motorola 88xxx */
  frame_arch_m98k,      /* Motorola 98xxx */
  frame_arch_pyramid,   /* Pyramid Technology */
  frame_arch_h8300,     /* Renesas H8/300 (formerly Hitachi H8/300) */
#define frame_mach_h8300    1
#define frame_mach_h8300h   2
#define frame_mach_h8300s   3
#define frame_mach_h8300hn  4
#define frame_mach_h8300sn  5
#define frame_mach_h8300sx  6
#define frame_mach_h8300sxn 7
  frame_arch_pdp11,     /* DEC PDP-11 */
  frame_arch_plugin,
  frame_arch_powerpc,   /* PowerPC */
#define frame_mach_ppc           32
#define frame_mach_ppc64         64
#define frame_mach_ppc_403       403
#define frame_mach_ppc_403gc     4030
#define frame_mach_ppc_405       405
#define frame_mach_ppc_505       505
#define frame_mach_ppc_601       601
#define frame_mach_ppc_602       602
#define frame_mach_ppc_603       603
#define frame_mach_ppc_ec603e    6031
#define frame_mach_ppc_604       604
#define frame_mach_ppc_620       620
#define frame_mach_ppc_630       630
#define frame_mach_ppc_750       750
#define frame_mach_ppc_860       860
#define frame_mach_ppc_a35       35
#define frame_mach_ppc_rs64ii    642
#define frame_mach_ppc_rs64iii   643
#define frame_mach_ppc_7400      7400
#define frame_mach_ppc_e500      500
#define frame_mach_ppc_e500mc    5001
#define frame_mach_ppc_e500mc64  5005
#define frame_mach_ppc_titan     83
  frame_arch_rs6000,    /* IBM RS/6000 */
#define frame_mach_rs6k          6000
#define frame_mach_rs6k_rs1      6001
#define frame_mach_rs6k_rsc      6003
#define frame_mach_rs6k_rs2      6002
  frame_arch_hppa,      /* HP PA RISC */
#define frame_mach_hppa10        10
#define frame_mach_hppa11        11
#define frame_mach_hppa20        20
#define frame_mach_hppa20w       25
  frame_arch_d10v,      /* Mitsubishi D10V */
#define frame_mach_d10v          1
#define frame_mach_d10v_ts2      2
#define frame_mach_d10v_ts3      3
  frame_arch_d30v,      /* Mitsubishi D30V */
  frame_arch_dlx,       /* DLX */
  frame_arch_m68hc11,   /* Motorola 68HC11 */
  frame_arch_m68hc12,   /* Motorola 68HC12 */
#define frame_mach_m6812_default 0
#define frame_mach_m6812         1
#define frame_mach_m6812s        2
  frame_arch_z8k,       /* Zilog Z8000 */
#define frame_mach_z8001         1
#define frame_mach_z8002         2
  frame_arch_h8500,     /* Renesas H8/500 (formerly Hitachi H8/500) */
  frame_arch_sh,        /* Renesas / SuperH SH (formerly Hitachi SH) */
#define frame_mach_sh            1
#define frame_mach_sh2        0x20
#define frame_mach_sh_dsp     0x2d
#define frame_mach_sh2a       0x2a
#define frame_mach_sh2a_nofpu 0x2b
#define frame_mach_sh2a_nofpu_or_sh4_nommu_nofpu 0x2a1
#define frame_mach_sh2a_nofpu_or_sh3_nommu 0x2a2
#define frame_mach_sh2a_or_sh4  0x2a3
#define frame_mach_sh2a_or_sh3e 0x2a4
#define frame_mach_sh2e       0x2e
#define frame_mach_sh3        0x30
#define frame_mach_sh3_nommu  0x31
#define frame_mach_sh3_dsp    0x3d
#define frame_mach_sh3e       0x3e
#define frame_mach_sh4        0x40
#define frame_mach_sh4_nofpu  0x41
#define frame_mach_sh4_nommu_nofpu  0x42
#define frame_mach_sh4a       0x4a
#define frame_mach_sh4a_nofpu 0x4b
#define frame_mach_sh4al_dsp  0x4d
#define frame_mach_sh5        0x50
  frame_arch_alpha,     /* Dec Alpha */
#define frame_mach_alpha_ev4  0x10
#define frame_mach_alpha_ev5  0x20
#define frame_mach_alpha_ev6  0x30
  frame_arch_arm,       /* Advanced Risc Machines ARM.  */
#define frame_mach_arm_unknown   0
#define frame_mach_arm_2         1
#define frame_mach_arm_2a        2
#define frame_mach_arm_3         3
#define frame_mach_arm_3M        4
#define frame_mach_arm_4         5
#define frame_mach_arm_4T        6
#define frame_mach_arm_5         7
#define frame_mach_arm_5T        8
#define frame_mach_arm_5TE       9
#define frame_mach_arm_XScale    10
#define frame_mach_arm_ep9312    11
#define frame_mach_arm_iWMMXt    12
#define frame_mach_arm_iWMMXt2   13
  frame_arch_ns32k,     /* National Semiconductors ns32000 */
  frame_arch_w65,       /* WDC 65816 */
  frame_arch_tic30,     /* Texas Instruments TMS320C30 */
  frame_arch_tic4x,     /* Texas Instruments TMS320C3X/4X */
#define frame_mach_tic3x         30
#define frame_mach_tic4x         40
  frame_arch_tic54x,    /* Texas Instruments TMS320C54X */
  frame_arch_tic6x,     /* Texas Instruments TMS320C6X */
  frame_arch_tic80,     /* TI TMS320c80 (MVP) */
  frame_arch_v850,      /* NEC V850 */
#define frame_mach_v850          1
#define frame_mach_v850e         'E'
#define frame_mach_v850e1        '1'
#define frame_mach_v850e2        0x4532
#define frame_mach_v850e2v3      0x45325633
  frame_arch_arc,       /* ARC Cores */
#define frame_mach_arc_5         5
#define frame_mach_arc_6         6
#define frame_mach_arc_7         7
#define frame_mach_arc_8         8
 frame_arch_m32c,     /* Renesas M16C/M32C.  */
#define frame_mach_m16c        0x75
#define frame_mach_m32c        0x78
  frame_arch_m32r,      /* Renesas M32R (formerly Mitsubishi M32R/D) */
#define frame_mach_m32r          1 /* For backwards compatibility.  */
#define frame_mach_m32rx         'x'
#define frame_mach_m32r2         '2'
  frame_arch_mn10200,   /* Matsushita MN10200 */
  frame_arch_mn10300,   /* Matsushita MN10300 */
#define frame_mach_mn10300               300
#define frame_mach_am33          330
#define frame_mach_am33_2        332
  frame_arch_fr30,
#define frame_mach_fr30          0x46523330
  frame_arch_frv,
#define frame_mach_frv           1
#define frame_mach_frvsimple     2
#define frame_mach_fr300         300
#define frame_mach_fr400         400
#define frame_mach_fr450         450
#define frame_mach_frvtomcat     499     /* fr500 prototype */
#define frame_mach_fr500         500
#define frame_mach_fr550         550
  frame_arch_moxie,       /* The moxie processor */
#define frame_mach_moxie         1
  frame_arch_mcore,
  frame_arch_mep,
#define frame_mach_mep           1
#define frame_mach_mep_h1        0x6831
#define frame_mach_mep_c5        0x6335
  frame_arch_ia64,      /* HP/Intel ia64 */
#define frame_mach_ia64_elf64    64
#define frame_mach_ia64_elf32    32
  frame_arch_ip2k,      /* Ubicom IP2K microcontrollers. */
#define frame_mach_ip2022        1
#define frame_mach_ip2022ext     2
 frame_arch_iq2000,     /* Vitesse IQ2000.  */
#define frame_mach_iq2000        1
#define frame_mach_iq10          2
  frame_arch_mt,
#define frame_mach_ms1           1
#define frame_mach_mrisc2        2
#define frame_mach_ms2           3
  frame_arch_pj,
  frame_arch_avr,       /* Atmel AVR microcontrollers.  */
#define frame_mach_avr1          1
#define frame_mach_avr2          2
#define frame_mach_avr25         25
#define frame_mach_avr3          3
#define frame_mach_avr31         31
#define frame_mach_avr35         35
#define frame_mach_avr4          4
#define frame_mach_avr5          5
#define frame_mach_avr51         51
#define frame_mach_avr6          6
  frame_arch_bfin,        /* ADI Blackfin */
#define frame_mach_bfin          1
  frame_arch_cr16,       /* National Semiconductor CompactRISC (ie CR16). */
#define frame_mach_cr16          1
  frame_arch_cr16c,       /* National Semiconductor CompactRISC. */
#define frame_mach_cr16c         1
  frame_arch_crx,       /*  National Semiconductor CRX.  */
#define frame_mach_crx           1
  frame_arch_cris,      /* Axis CRIS */
#define frame_mach_cris_v0_v10   255
#define frame_mach_cris_v32      32
#define frame_mach_cris_v10_v32  1032
  frame_arch_rx,        /* Renesas RX.  */
#define frame_mach_rx            0x75
  frame_arch_s390,      /* IBM s390 */
#define frame_mach_s390_31       31
#define frame_mach_s390_64       64
  frame_arch_score,     /* Sunplus score */
#define frame_mach_score3         3
#define frame_mach_score7         7
  frame_arch_openrisc,  /* OpenRISC */
  frame_arch_mmix,      /* Donald Knuth's educational processor.  */
  frame_arch_xstormy16,
#define frame_mach_xstormy16     1
  frame_arch_msp430,    /* Texas Instruments MSP430 architecture.  */
#define frame_mach_msp11          11
#define frame_mach_msp110         110
#define frame_mach_msp12          12
#define frame_mach_msp13          13
#define frame_mach_msp14          14
#define frame_mach_msp15          15
#define frame_mach_msp16          16
#define frame_mach_msp21          21
#define frame_mach_msp31          31
#define frame_mach_msp32          32
#define frame_mach_msp33          33
#define frame_mach_msp41          41
#define frame_mach_msp42          42
#define frame_mach_msp43          43
#define frame_mach_msp44          44
  frame_arch_xc16x,     /* Infineon's XC16X Series.               */
#define frame_mach_xc16x         1
#define frame_mach_xc16xl        2
#define frame_mach_xc16xs         3
  frame_arch_xtensa,    /* Tensilica's Xtensa cores.  */
#define frame_mach_xtensa        1
  frame_arch_z80,
#define frame_mach_z80strict      1 /* No undocumented opcodes.  */
#define frame_mach_z80            3 /* With ixl, ixh, iyl, and iyh.  */
#define frame_mach_z80full        7 /* All undocumented instructions.  */
#define frame_mach_r800           11 /* R800: successor with multiplication.  */
  frame_arch_lm32,      /* Lattice Mico32 */
#define frame_mach_lm32      1
  frame_arch_microblaze,/* Xilinx MicroBlaze. */
  frame_arch_6502,/* MOS Technology 6502. */
  frame_arch_last
  };

#endif
