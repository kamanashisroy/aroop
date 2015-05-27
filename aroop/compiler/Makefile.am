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
	$(top_srcdir)/shotodolplug/libshotodolplug.la \
	$(top_srcdir)/codegenplug/libcodegenplug.la \
        $(NULL)

aroopc@PACKAGE_SUFFIX@_CFLAGS = \
        $(GLIB_CFLAGS) \
        $(GEE_CFLAGS) \
        $(VALA_CFLAGS) \
	-DVAPI_INSTALL_PREFIX=\"@datadir@/aroop@PACKAGE_SUFFIX@/vapi\" \
	-DC_INCLUDE_DIR=\"@includedir@/aroop_core@PACKAGE_SUFFIX@\" \
	-DC_LIB_DIR=\"@libdir@\" \
	-I$(top_srcdir)/shotodolplug/ \
	-I$(top_srcdir)/codegenplug/ \
        $(NULL)


aroopc@PACKAGE_SUFFIX@_VALAFLAGS = \
        --vapidir $(top_srcdir)/shotodolplug --pkg shotodolplug \
        --vapidir $(top_srcdir)/codegenplug --pkg codegenplug \
        --vapidir $(top_srcdir)/aroop/compiler --pkg config \
        --pkg $(VALA_PACKAGE) \
        -g \
        $(NULL)


#EXTRA_DIST = $(aroopc@PACKAGE_SUFFIX@_VALASOURCES)
EXTRA_DIST=config.vapi

MAINTAINERCLEANFILES = \
	$(aroopc@PACKAGE_SUFFIX@_SOURCES:.vala=.c) \
	$(NULL)

