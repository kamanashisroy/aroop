NULL =

BUILT_SOURCES = 

noinst_LTLIBRARIES = \
	libcodegenplug.la \
	$(NULL)

libcodegenplug_la_CFLAGS = \
        $(GLIB_CFLAGS) \
        $(GEE_CFLAGS) \
        $(VALA_CFLAGS) \
	-I$(top_srcdir)/shotodolplug/ \
	$(NULL)

libcodegenplug_la_LIBADD = \
        $(GLIB_LIBS) \
        $(GEE_LIBS) \
        $(VALA_LIBS) \
	$(top_srcdir)/shotodolplug/libshotodolplug.la \
        $(NULL)

libcodegenplug_la_VALAFLAGS = \
        --vapidir $(top_srcdir)/shotodolplug \
	--pkg $(VALA_PACKAGE) \
        --pkg shotodolplug \
	--vapi=codegenplug.vapi \
	--use-header --header=codegenplug.h \
        -g \
	$(NULL)

libcodegenplug_la_SOURCES = \
	valaccodebasemodule.vala \
	valaccodecompiler.vala \
	generator/aroopcodegenerator.vala \
	tempvariablemodule.vala \
	sourceemittermodule.vala \
	generator/csymbolresolve.vala \
	symbols/structmodule.vala \
	symbols/stringmodule.vala \
	symbols/expressionmodule.vala \
	symbols/elementmodule.vala \
	symbols/memberaccessmodule.vala \
	symbols/parametermodule.vala \
	symbols/methodmodule.vala \
	symbols/methodcallmodule.vala \
	symbols/blockmodule.vala \
	symbols/cleanupmodule.vala \
	symbols/objectmodule.vala \
	symbols/delegatemodule.vala \
	symbols/valuemodule.vala \
	symbols/localvariablemodule.vala \
	symbols/controlflowmodule.vala \
	symbols/errormodule.vala \
	symbols/sourcefilemodule.vala \
	$(NULL)

libcodegenplug_la_LDFLAGS = -no-undefined

EXTRA_DIST = codegenplug.vapi codegenplug.h

MAINTAINERCLEANFILES = \
	codegenplug.vapi \
	codegenplug.h \
	$(libcodegenplug_la_SOURCES:.vala=.c) \
	$(NULL)

