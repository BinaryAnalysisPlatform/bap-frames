#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.64])
AC_INIT([libtrace], [1.0], [https://github.com/BinaryAnalysisPlatform/bap-frames])
AC_CONFIG_SRCDIR([src/trace.container.hpp])
AC_CONFIG_HEADERS([src/config.h])

AM_INIT_AUTOMAKE([foreign])

AC_SUBST(INCDIRS)

# Checks for programs.
AC_PROG_CXX
AC_PROG_CC
AC_PROG_CPP
AC_PROG_RANLIB

# Checks for libraries.
# FIXME: Replace `main' with a function in `-lpthread':
AC_CHECK_LIB([pthread], [main])
AC_CHECK_LIB([protobuf], [main])

# Checks for header files.
AC_CHECK_HEADERS([stdint.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_HEADER_STDBOOL
AC_C_INLINE
AC_TYPE_SIZE_T
AC_TYPE_UINT64_T
AC_SYS_LARGEFILE
AC_FUNC_FSEEKO

# Checks for library functions.
AC_CHECK_FUNCS([memset])

AC_CONFIG_FILES([Makefile
                 src/Makefile])
AC_OUTPUT
