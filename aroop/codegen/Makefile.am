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
        --pkg gee-1.0 \
        --pkg $(VALA_PACKAGE) \
	--vapi=codegen.vapi \
	--use-header --header=valacodegen.h \
        -g \
        $(NULL)

lib_LTLIBRARIES = \
	libaroopcodegen.la
	$(NULL)

libaroopcodegen_la_SOURCES = \
	valaccodearraymodule.vala \
	valaccodeassignmentmodule.vala \
	valaccodeattribute.vala \
	valaccodebasemodule.vala \
	valaccodecompiler.vala \
	valaccodecontrolflowmodule.vala \
	valaccodedelegatemodule.vala \
	valaccodememberaccessmodule.vala \
	valaccodemethodcallmodule.vala \
	valaccodemethodmodule.vala \
	valaccodestructmodule.vala \
	valactype.vala \
	valaarooparraymodule.vala \
	valaaroopassignmentmodule.vala \
	valaaroopbasemodule.vala \
	valaaroopccodegenimpl.vala \
	valaaroopcontrolflowmodule.vala \
	valaaroopdelegatemodule.vala \
	valaaroopmemberaccessmodule.vala \
	valaaroopmethodcallmodule.vala \
	valaaroopmethodmodule.vala \
	valaaroopobjectmodule.vala \
	valaaroopstructmodule.vala \
	valaaroopblockmodule.vala \
	valaaroopvaluemodule.vala \
	valaarooperrormodule.vala \
	valaclassregisterfunction.vala \
	valaenumregisterfunction.vala \
	valainterfaceregisterfunction.vala \
	valastructregisterfunction.vala \
	valatyperegisterfunction.vala \
	$(NULL)

libaroopcodegen_la_LDFLAGS = -no-undefined

EXTRA_DIST = $(libaroopcodegen_la_VALASOURCES) codegen.vapi

MAINTAINERCLEANFILES = \
	codegen.vapi \
	valacodegen.h \
	$(libaroopcodegen_la_VALASOURCES:.vala=.c) \
	$(NULL)


