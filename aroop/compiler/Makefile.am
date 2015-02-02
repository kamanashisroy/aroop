NULL =

BUILT_SOURCES = aroopc.vala.stamp

bin_PROGRAMS = \
	aroopc \
	$(NULL)

aroopc_VALASOURCES = \
	aroopcompiler.vala \
	$(NULL)

aroopc_SOURCES = \
	$(aroopc_VALASOURCES:.vala=.c) \
	$(NULL)

aroopc_LDADD = \
        $(GLIB_LIBS) \
        $(GEE_LIBS) \
        $(VALA_LIBS) \
	$(top_srcdir)/aroop/codegen/libaroop@PACKAGE_SUFFIX@.la \
        $(NULL)

aroopc_VALAFLAGS = \
        --vapidir $(top_srcdir)/aroop/codegen \
        --pkg config \
        --pkg gee-1.0 \
        --pkg $(VALA_PACKAGE) \
        -g \
        $(NULL)


EXTRA_DIST = $(aroopc_VALASOURCES)

MAINTAINERCLEANFILES = \
	$(aroopc_VALASOURCES:.vala=.c) \
	$(NULL)

