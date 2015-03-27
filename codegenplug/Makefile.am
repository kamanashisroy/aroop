NULL =

BUILT_SOURCES = 

noinst_LTLIBRARIES = \
	libcodegenplug.la \
	$(NULL)

libcodegenplug_la_CFLAGS = \
        $(GLIB_CFLAGS) \
        $(GEE_CFLAGS) \
        $(VALA_CFLAGS) \
	$(NULL)

libcodegenplug_la_LIBADD = \
        $(GLIB_LIBS) \
        $(GEE_LIBS) \
        $(VALA_LIBS) \
        $(NULL)

libcodegenplug_la_VALAFLAGS = \
        --pkg gee-1.0 \
        --pkg $(VALA_PACKAGE) \
        --vapidir $(top_srcdir)/shotodolplug \
        --pkg shotodolplug \
        --vapidir $(top_srcdir)/codegenplug \
	--vapi=codegenplug.vapi \
	--use-header --header=codegenplug.h \
	$(NULL)

libcodegenplug_la_SOURCES = \
	valaccodebasemodule.vala \
	aroopcodegenerator.vala \
	compilermodule.vala \
	csymbolresolve.vala \
	structmodule.vala \
	elementmodule.vala \
	objectmodule.vala \
	$(NULL)

EXTRA_DIST = 

MAINTAINERCLEANFILES = \
	codegenplug.vapi \
	codegenplug.h \
	$(libcodegenplug_la_SOURCES:.vala=.c) \
	$(NULL)
