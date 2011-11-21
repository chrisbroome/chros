#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.68])
AC_INIT([Chros], [0.01], [https://github.com/chrisbroome/chros/issues])

# initialize automake
AM_INIT_AUTOMAKE([silent-rules])

# Checks for programs.
AX_PROG_FASM
AC_PROG_CC([gcc])

# Checks for libraries.

# Checks for header files.

# Checks for typedefs, structures, and compiler characteristics.

# Checks for library functions.
AC_CONFIG_FILES([Makefile
                 src/Makefile])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_SRCDIR([src/kmain.c])

AM_PROG_CC_C_O

AC_OUTPUT
