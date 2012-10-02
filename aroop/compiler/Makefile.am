NULL =

AM_CPPFLAGS = \
	$(COVERAGE_CFLAGS) \
	-I$(top_srcdir)/gee \
	-I$(top_srcdir)/ccode \
	-I$(top_srcdir)/vala \
	-I$(top_srcdir)/aroop/codegen \
	$(GLIB_CFLAGS) \
	-DPACKAGE_DATADIR=\"$(pkgdatadir)\" \
	$(NULL)

BUILT_SOURCES = aroopc.vala.stamp

bin_PROGRAMS = \
	aroopc \
	$(NULL)

aroopc_VALASOURCES = \
	aroopcompiler.vala \
	$(NULL)

aroopc_SOURCES = \
	aroopc.vala.stamp \
	$(aroopc_VALASOURCES:.vala=.c) \
	$(NULL)

aroopc.vala.stamp: $(aroopc_VALASOURCES)
	$(VALA_V)$(VALAC) $(COVERAGE_VALAFLAGS) $(VALAFLAGS) -C --vapidir $(top_srcdir)/vapi --pkg gobject-2.0 --vapidir $(top_srcdir)/gee --pkg gee --vapidir $(top_srcdir)/ccode --pkg ccode --vapidir $(top_srcdir)/vala --pkg vala --vapidir $(top_srcdir)/aroop/codegen --pkg codegen --pkg config $^
	@touch $@

aroopc_LDADD = \
	$(COVERAGE_LIBS) \
	$(GLIB_LIBS) \
	$(top_srcdir)/aroop/codegen/libvala@PACKAGE_SUFFIX@.la \
	$(NULL)

EXTRA_DIST = $(aroopc_VALASOURCES) aroopc.vala.stamp

install-exec-hook:
	cd $(DESTDIR)$(bindir) && $(LN_S) -f aroopc@PACKAGE_SUFFIX@$(EXEEXT) vala@PACKAGE_SUFFIX@$(EXEEXT)
if ENABLE_UNVERSIONED
	cd $(DESTDIR)$(bindir) && $(LN_S) -f aroopc@PACKAGE_SUFFIX@$(EXEEXT) aroopc$(EXEEXT)
	cd $(DESTDIR)$(bindir) && $(LN_S) -f vala@PACKAGE_SUFFIX@$(EXEEXT) vala$(EXEEXT)
endif

MAINTAINERCLEANFILES = \
	$(aroopc_VALASOURCES:.vala=.c) \
	$(NULL)

VALA_V = $(VALA_V_$(V))
VALA_V_ = $(VALA_V_$(AM_DEFAULT_VERBOSITY))
VALA_V_0 = @echo "  VALAC " $^;
