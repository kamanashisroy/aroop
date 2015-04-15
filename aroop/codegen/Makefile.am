NULL =

libaroopcodegen_la_CFLAGS = \
        $(GLIB_CFLAGS) \
        $(GEE_CFLAGS) \
        $(VALA_CFLAGS) \
        $(NULL)

libaroopcodegen_la_LIBADD = \
        $(GLIB_LIBS) \
        $(GEE_LIBS) \
        $(VALA_LIBS) \
        $(NULL)

libaroopcodegen_la_VALAFLAGS = \
        --vapidir $(top_srcdir)/aroop/codegen \
        --pkg $(VALA_PACKAGE) \
	--vapi=codegen.vapi \
	--use-header --header=aroopcodegen.h \
        -g \
        $(NULL)

lib_LTLIBRARIES = \
	libaroopcodegen.la
	$(NULL)

libaroopcodegen_la_SOURCES = \
	valaccodeattribute.vala \
	valaccodebasemodule.vala \
	valaccodecompiler.vala \
	arooparraymodule.vala \
	aroopassignmentmodule.vala \
	aroopbasemodule.vala \
	aroopccodegenimpl.vala \
	aroopcontrolflowmodule.vala \
	aroopdelegatemodule.vala \
	aroopmemberaccessmodule.vala \
	aroopmethodcallmodule.vala \
	aroopmethodmodule.vala \
	aroopobjectmodule.vala \
	aroopstructmodule.vala \
	aroopblockmodule.vala \
	aroopvaluemodule.vala \
	arooperrormodule.vala \
	$(NULL)

libaroopcodegen_la_LDFLAGS = -no-undefined

EXTRA_DIST = codegen.vapi config.vapi

MAINTAINERCLEANFILES = \
	codegen.vapi \
	aroopcodegen.h \
	$(libaroopcodegen_la_SOURCES:.vala=.c) \
	$(NULL)


