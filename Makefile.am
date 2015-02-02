NULL =

SUBDIRS = \
	aroop/codegen \
	aroop/compiler \
	aroop/vapi \
	aroop/core \
	$(NULL)

DIST_SUBDIRS = \
	aroop/codegen \
	aroop/compiler \
	aroop/vapi \
	aroop/core \
	$(NULL)

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = libaroop@PACKAGE_SUFFIX@.pc

libaroop@PACKAGE_SUFFIX@.pc: libaroop.pc
	cp $< $@

