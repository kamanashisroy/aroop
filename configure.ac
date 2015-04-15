# please refer to https://wiki.gnome.org/Projects/Vala/GameDevelopmentSeries/Setup

m4_define([aroop_major], [0])
m4_define([aroop_minor], [1])
m4_define([aroop_micro], [0])

m4_define([aroop_version], [aroop_major.aroop_minor.aroop_micro])
m4_define([aroop_suffix], [-aroop_version])
m4_define([aroop_api_version], [0.1])

m4_define([aroop_name], [aroop])

AC_PREREQ([2.64])
AC_INIT([Aroop], [aroop_version], [kamanashisroy@github.com])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_MACRO_DIR([m4])
AM_INIT_AUTOMAKE([dist-bzip2 subdir-objects])
AM_MAINTAINER_MODE

AROOP_MAJOR_VERSION=aroop_major
AROOP_MINOR_VERSION=aroop_minor
AROOP_MICRO_VERSION=aroop_micro
AROOP_VERSION=aroop_version
AROOP_API_VERSION=aroop_api_version
PACKAGE_SUFFIX=aroop_suffix
AC_SUBST(PACKAGE_SUFFIX)
AC_SUBST(AROOP_MAJOR_VERSION)
AC_SUBST(AROOP_MINOR_VERSION)
AC_SUBST(AROOP_MICRO_VERSION)
AC_SUBST(AROOP_VERSION)
AC_SUBST(AROOP_API_VERSION)

m4_ifdef([AM_SILENT_RULES],[AM_SILENT_RULES([yes])])


# Checks for header files.
AC_CHECK_HEADERS([stdlib.h string.h])


# Checks for programs.
AC_PROG_CC
AM_PROG_CC_C_O
AC_PROG_INSTALL
AC_PROG_LIBTOOL
AC_PROG_RANLIB


# get vala sources and libraries
VALA_REQUIRED=0.26
PKG_CHECK_MODULES(VALA, libvala-0.26 >= $VALA_REQUIRED)
AC_SUBST(VALA_CFLAGS)
AC_SUBST(VALA_LIBS)

# get valac compiler binary
AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)

GLIB_REQUIRED=2.12.0
GEE_REQUIRED=0.1.3

PKG_CHECK_MODULES(GEE, gee-1.0 >= $GEE_REQUIRED)
AC_SUBST(GEE_CFLAGS)
AC_SUBST(GEE_LIBS)
PKG_CHECK_MODULES(GLIB, glib-2.0 >= $GLIB_REQUIRED)
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)

AC_CHECK_SIZEOF([int])

AROOP_CORE_CFLAGS=
if $ac_cv_sizeof_int eq 64 ; then
AROOP_CORE_CFLAGS=-DSYNC_BIT64 -DAROOP_BIT64
fi
AC_SUBST(AROOP_CORE_CFLAGS)


# XXX we do not do anything with VALA_PACKAGE
# AC_SUBST(VALA_PACKAGE)

AC_CONFIG_FILES([Makefile
           libaroop.pc
           aroop/codegen/Makefile
           aroop/compiler/Makefile
           aroop/core/Makefile
	   aroop/core/aroop_core.pc
           aroop/vapi/Makefile])

AC_OUTPUT
