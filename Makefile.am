NULL =

SUBDIRS = \
	shotodolplug/ \
	codegenplug/ \
	aroop/compiler \
	aroop/vapi \
	aroop/core \
	$(NULL)

DIST_SUBDIRS = \
	shotodolplug/ \
	codegenplug/ \
	aroop/compiler \
	aroop/vapi \
	aroop/core \
	$(NULL)

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = libaroop@PACKAGE_SUFFIX@.pc

libaroop@PACKAGE_SUFFIX@.pc: libaroop.pc
	cp $< $@

