NULL =

AM_CPPFLAGS = \
	$(COVERAGE_CFLAGS) \
	-I$(top_srcdir)/gee \
	-I$(top_srcdir)/ccode \
	-I$(top_srcdir)/vala \
	$(GLIB_CFLAGS) \
	$(NULL)

BUILT_SOURCES = codegen.vala.stamp

lib_LTLIBRARIES = \
	libaroop@PACKAGE_SUFFIX@.la
	$(NULL)

libaroop_la_VALASOURCES = \
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
	valaaroopvaluemodule.vala \
	valaarooperrormodule.vala \
	valaclassregisterfunction.vala \
	valaenumregisterfunction.vala \
	valainterfaceregisterfunction.vala \
	valastructregisterfunction.vala \
	valatyperegisterfunction.vala \
	$(NULL)

libaroop@PACKAGE_SUFFIX@_la_SOURCES = \
	codegen.vala.stamp \
	$(libaroop_la_VALASOURCES:.vala=.c) \
	$(NULL)

codegenincludedir = $(includedir)/vala@PACKAGE_SUFFIX@

codegeninclude_HEADERS = \
	valacodegen.h \
	$(NULL)

codegen.vapi codegen.vala.stamp: $(libaroop_la_VALASOURCES)
	$(VALA_V)$(VALAC) $(COVERAGE_VALAFLAGS) $(VALAFLAGS) -C --vapidir $(top_srcdir)/vapi --pkg gobject-2.0 --vapidir $(top_srcdir)/gee --pkg gee --vapidir $(top_srcdir)/ccode --pkg ccode --vapidir $(top_srcdir)/vala --pkg vala -H valacodegen.h --library codegen $^
	@touch $@

libaroop@PACKAGE_SUFFIX@_la_LDFLAGS = -no-undefined

libaroop@PACKAGE_SUFFIX@_la_LIBADD = \
	$(COVERAGE_LIBS) \
	$(GLIB_LIBS) \
	$(top_srcdir)/vala/libvalacore.la \
	$(top_srcdir)/ccode/libvalaccode.la \
	$(NULL)

EXTRA_DIST = $(libaroop_la_VALASOURCES) codegen.vapi codegen.vala.stamp

MAINTAINERCLEANFILES = \
	codegen.vapi \
	valacodegen.h \
	$(libaroop_la_VALASOURCES:.vala=.c) \
	$(NULL)

VALA_V = $(VALA_V_$(V))
VALA_V_ = $(VALA_V_$(AM_DEFAULT_VERBOSITY))
VALA_V_0 = @echo "  VALAC " $^;

