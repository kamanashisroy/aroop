NULL =

BUILT_SOURCES = 

noinst_LTLIBRARIES = \
	libshotodolplug.la \
	$(NULL)

libshotodolplug_la_CFLAGS = \
        $(GLIB_CFLAGS) \
        $(GEE_CFLAGS) \
        $(VALA_CFLAGS) \
	$(NULL)

libshotodolplug_la_LIBADD = \
        $(GLIB_LIBS) \
        $(GEE_LIBS) \
        $(VALA_LIBS) \
        $(NULL)

libshotodolplug_la_VALAFLAGS = \
        --vapidir $(top_srcdir)/shotodolplug \
        --pkg gee-1.0 \
        --pkg $(VALA_PACKAGE) \
	--vapi=shotodolplug.vapi \
	--use-header --header=shotodolplug.h \
	$(NULL)

libshotodolplug_la_SOURCES = \
	module.vala \
	extension.vala \
	hookextension.vala \
	compositeextension.vala \
	plugin.vala \
	$(NULL)

EXTRA_DIST = 

MAINTAINERCLEANFILES = \
	shotodolplug.vapi \
	shotodolplug.h \
	$(libshotodolplug_la_SOURCES:.vala=.c) \
	$(NULL)
