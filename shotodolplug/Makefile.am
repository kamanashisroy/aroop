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
	--pkg $(VALA_PACKAGE) \
        --vapidir $(top_srcdir)/shotodolplug \
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

libshotodolplug_la_LDFLAGS = -no-undefined

EXTRA_DIST = shotodolplug.vapi shotodolplug.h

MAINTAINERCLEANFILES = \
	shotodolplug.vapi \
	shotodolplug.h \
	$(libshotodolplug_la_SOURCES:.vala=.c) \
	$(NULL)
