NULL =

bin_PROGRAMS = \
	aroopc@PACKAGE_SUFFIX@ \
	$(NULL)

aroopc@PACKAGE_SUFFIX@_SOURCES = \
	aroopcompiler.vala \
	$(NULL)

aroopc@PACKAGE_SUFFIX@_LDADD = \
        $(GLIB_LIBS) \
        $(GEE_LIBS) \
        $(VALA_LIBS) \
	$(top_srcdir)/aroop/codegen/libaroopcodegen.la \
        $(NULL)

aroopc@PACKAGE_SUFFIX@_CFLAGS = \
        $(GLIB_CFLAGS) \
        $(GEE_CFLAGS) \
        $(VALA_CFLAGS) \
	-DVAPI_INSTALL_PREFIX=\"@datadir@/aroop@PACKAGE_SUFFIX@/vapi\" \
	-DC_INCLUDE_DIR=\"@includedir@/aroop_core@PACKAGE_SUFFIX@\" \
	-DC_LIB_DIR=\"@libdir@\" \
	-I$(top_srcdir)/aroop/codegen/ \
        $(NULL)


aroopc@PACKAGE_SUFFIX@_VALAFLAGS = \
        --vapidir $(top_srcdir)/aroop/codegen --pkg codegen \
        --pkg config \
        --pkg gee-1.0 \
        --pkg $(VALA_PACKAGE) \
        -g \
        $(NULL)


#EXTRA_DIST = $(aroopc@PACKAGE_SUFFIX@_VALASOURCES)

MAINTAINERCLEANFILES = \
	$(aroopc@PACKAGE_SUFFIX@_SOURCES:.vala=.c) \
	$(NULL)

