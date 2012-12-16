NULL =

vapidir = $(pkgdatadir)/vapi

libvala@PACKAGE_SUFFIX@.vapi: ../gee/gee.vapi ../ccode/ccode.vapi ../vala/vala.vapi ../aroop/codegen/codegen.vapi
	cat $^ > $@

dist_vapi_DATA = \
	aroop-1.0.vapi \
	aroop-1.0.deps \
	aroop_core-1.0.vapi \
	aroop_core-1.0.deps \
	aroop_pthread-0.1.vapi \
	aroop_pthread-0.1.deps \
	$(NULL)

dist_noinst_DATA = \
	$(NULL)

BINDINGS = aroop-1.0 aroop_core-1.0 aroop_pthread-0.1

VAPIGEN = $(top_builddir)/vapigen/vapigen
VAPIGENFLAGS = --vapidir $(srcdir)
GENVAPI = $(VAPIGEN) $(VAPIGENFLAGS)
METADATADIR = $(srcdir)/metadata
PACKAGESDIR = $(srcdir)/packages
GIRDIR = $$($(PKG_CONFIG) gobject-introspection-1.0 --variable=girdir)
GEDIT_GIRDIR=$$($(PKG_CONFIG) gedit --variable=prefix)/share/gedit/gir-1.0

.PHONY: all-bindings $(BINDINGS)

all-bindings: $(BINDINGS)

atk:
	$(GENVAPI) --library $(srcdir)/atk --metadatadir $(METADATADIR) $(METADATADIR)/Atk-1.0-custom.vala $(GIRDIR)/Atk-1.0.gir

clutter-1.0:
	$(GENVAPI) --library $(srcdir)/clutter-1.0 --metadatadir $(METADATADIR) $(METADATADIR)/Clutter-1.0-custom.vala --pkg atk --pkg cairo --pkg pango --pkg cogl-1.0 --pkg json-glib-1.0 $(GIRDIR)/Clutter-1.0.gir

clutter-gtk-0.10:
	$(GENVAPI) --library $(srcdir)/clutter-gtk-0.10 $(PACKAGESDIR)/clutter-gtk-0.10/clutter-gtk-0.10.gi

clutter-gtk-1.0:
	$(GENVAPI) --library $(srcdir)/clutter-gtk-1.0 $(PACKAGESDIR)/clutter-gtk-1.0/clutter-gtk-1.0.gi

cogl-1.0:
	$(GENVAPI) --library $(srcdir)/cogl-1.0 $(PACKAGESDIR)/cogl-1.0/cogl-1.0-custom.vala $(PACKAGESDIR)/cogl-1.0/cogl-1.0.gi

gconf-2.0:
	$(GENVAPI) --library $(srcdir)/gconf-2.0 $(PACKAGESDIR)/gconf-2.0/gconf-2.0.gi

gdk-2.0:
	$(GENVAPI) --library $(srcdir)/gdk-2.0 $(PACKAGESDIR)/gdk-2.0/gdk-2.0-custom.vala $(PACKAGESDIR)/gdk-2.0/gdk-2.0.gi

gdk-3.0:
	$(GENVAPI) --library $(srcdir)/gdk-3.0 --pkg gio-2.0 --metadatadir $(METADATADIR) $(METADATADIR)/Gdk-3.0-custom.vala $(GIRDIR)/Gdk-3.0.gir

gdk-pixbuf-2.0:
	$(GENVAPI) --library $(srcdir)/gdk-pixbuf-2.0 --pkg gio-2.0 --metadatadir $(METADATADIR) $(METADATADIR)/GdkPixbuf-2.0-custom.vala $(GIRDIR)/GdkPixbuf-2.0.gir

gdk-x11-2.0:
	$(GENVAPI) --library $(srcdir)/gdk-x11-2.0 $(PACKAGESDIR)/gdk-x11-2.0/gdk-x11-2.0.gi

gdk-x11-3.0:
	$(GENVAPI) --library $(srcdir)/gdk-x11-3.0 $(PACKAGESDIR)/gdk-x11-3.0/gdk-x11-3.0.gi

gdl-1.0:
	$(GENVAPI) --library $(srcdir)/gdl-1.0 $(PACKAGESDIR)/gdl-1.0/gdl-1.0-custom.vala $(PACKAGESDIR)/gdl-1.0/gdl-1.0.gi

gdu:
	$(GENVAPI) --library $(srcdir)/gdu $(PACKAGESDIR)/gdu/gdu.gi

gdu-gtk:
	$(GENVAPI) --library $(srcdir)/gdu-gtk $(PACKAGESDIR)/gdu-gtk/gdu-gtk.gi

gedit-2.20:
	$(GENVAPI) --library $(srcdir)/gedit-2.20 $(PACKAGESDIR)/gedit-2.20/gedit-2.20.gi

gedit:
	$(GENVAPI) --library $(srcdir)/gedit --metadatadir $(METADATADIR) $(GEDIT_GIRDIR)/Gedit-3.0.gir

gio-2.0:
	$(GENVAPI) --library $(srcdir)/gio-2.0 $(PACKAGESDIR)/gio-2.0/gio-2.0-custom.vala $(PACKAGESDIR)/gio-2.0/gio-2.0.gi

gio-unix-2.0:
	$(GENVAPI) --library $(srcdir)/gio-unix-2.0 $(PACKAGESDIR)/gio-unix-2.0/gio-unix-2.0-custom.vala $(PACKAGESDIR)/gio-unix-2.0/gio-unix-2.0.gi

gnome-desktop-2.0:
	$(GENVAPI) --library $(srcdir)/gnome-desktop-2.0 $(PACKAGESDIR)/gnome-desktop-2.0/gnome-desktop-2.0.gi

gnome-keyring-1:
	$(GENVAPI) --library $(srcdir)/gnome-keyring-1 $(PACKAGESDIR)/gnome-keyring-1/gnome-keyring-1-custom.vala $(PACKAGESDIR)/gnome-keyring-1/gnome-keyring-1.gi

gnome-vfs-2.0:
	$(GENVAPI) --library $(srcdir)/gnome-vfs-2.0 $(PACKAGESDIR)/gnome-vfs-2.0/gnome-vfs-2.0-custom.vala $(PACKAGESDIR)/gnome-vfs-2.0/gnome-vfs-2.0.gi

goocanvas:
	$(GENVAPI) --library $(srcdir)/goocanvas $(PACKAGESDIR)/goocanvas/goocanvas-custom.vala $(PACKAGESDIR)/goocanvas/goocanvas.gi

gstreamer-0.10:
	$(GENVAPI) --library $(srcdir)/gstreamer-0.10 $(PACKAGESDIR)/gstreamer-0.10/gstreamer-0.10-custom.vala $(PACKAGESDIR)/gstreamer-0.10/gstreamer-0.10.gi

gstreamer-app-0.10:
	$(GENVAPI) --library $(srcdir)/gstreamer-app-0.10 $(PACKAGESDIR)/gstreamer-app-0.10/gstreamer-app-0.10.gi

gstreamer-audio-0.10:
	$(GENVAPI) --library $(srcdir)/gstreamer-audio-0.10 $(PACKAGESDIR)/gstreamer-audio-0.10/gstreamer-audio-0.10.gi

gstreamer-base-0.10:
	$(GENVAPI) --library $(srcdir)/gstreamer-base-0.10 $(PACKAGESDIR)/gstreamer-base-0.10/gstreamer-base-0.10-custom.vala $(PACKAGESDIR)/gstreamer-base-0.10/gstreamer-base-0.10.gi

gstreamer-cdda-0.10:
	$(GENVAPI) --library $(srcdir)/gstreamer-cdda-0.10 $(PACKAGESDIR)/gstreamer-cdda-0.10/gstreamer-cdda-0.10-custom.vala $(PACKAGESDIR)/gstreamer-cdda-0.10/gstreamer-cdda-0.10.gi

gstreamer-check-0.10:
	$(GENVAPI) --library $(srcdir)/gstreamer-check-0.10 $(PACKAGESDIR)/gstreamer-check-0.10/gstreamer-check-0.10.gi

gstreamer-controller-0.10:
	$(GENVAPI) --library $(srcdir)/gstreamer-controller-0.10 $(PACKAGESDIR)/gstreamer-controller-0.10/gstreamer-controller-0.10-custom.vala $(PACKAGESDIR)/gstreamer-controller-0.10/gstreamer-controller-0.10.gi

gstreamer-dataprotocol-0.10:
	$(GENVAPI) --library $(srcdir)/gstreamer-dataprotocol-0.10 $(PACKAGESDIR)/gstreamer-dataprotocol-0.10/gstreamer-dataprotocol-0.10-custom.vala $(PACKAGESDIR)/gstreamer-dataprotocol-0.10/gstreamer-dataprotocol-0.10.gi

gstreamer-fft-0.10:
	$(GENVAPI) --library $(srcdir)/gstreamer-fft-0.10 $(PACKAGESDIR)/gstreamer-fft-0.10/gstreamer-fft-0.10.gi

gstreamer-interfaces-0.10:
	$(GENVAPI) --library $(srcdir)/gstreamer-interfaces-0.10 $(PACKAGESDIR)/gstreamer-interfaces-0.10/gstreamer-interfaces-0.10-custom.vala $(PACKAGESDIR)/gstreamer-interfaces-0.10/gstreamer-interfaces-0.10.gi

gstreamer-net-0.10:
	$(GENVAPI) --library $(srcdir)/gstreamer-net-0.10 $(PACKAGESDIR)/gstreamer-net-0.10/gstreamer-net-0.10.gi

gstreamer-netbuffer-0.10:
	$(GENVAPI) --library $(srcdir)/gstreamer-netbuffer-0.10 $(PACKAGESDIR)/gstreamer-netbuffer-0.10/gstreamer-netbuffer-0.10.gi

gstreamer-pbutils-0.10:
	$(GENVAPI) --library $(srcdir)/gstreamer-pbutils-0.10 $(PACKAGESDIR)/gstreamer-pbutils-0.10/gstreamer-pbutils-0.10-custom.vala $(PACKAGESDIR)/gstreamer-pbutils-0.10/gstreamer-pbutils-0.10.gi

gstreamer-riff-0.10:
	$(GENVAPI) --library $(srcdir)/gstreamer-riff-0.10 $(PACKAGESDIR)/gstreamer-riff-0.10/gstreamer-riff-0.10.gi

gstreamer-rtp-0.10:
	$(GENVAPI) --library $(srcdir)/gstreamer-rtp-0.10 $(PACKAGESDIR)/gstreamer-rtp-0.10/gstreamer-rtp-0.10.gi

gstreamer-rtsp-0.10:
	$(GENVAPI) --library $(srcdir)/gstreamer-rtsp-0.10 $(PACKAGESDIR)/gstreamer-rtsp-0.10/gstreamer-rtsp-0.10-custom.vala $(PACKAGESDIR)/gstreamer-rtsp-0.10/gstreamer-rtsp-0.10.gi

gstreamer-sdp-0.10:
	$(GENVAPI) --library $(srcdir)/gstreamer-sdp-0.10 $(PACKAGESDIR)/gstreamer-sdp-0.10/gstreamer-sdp-0.10.gi

gstreamer-tag-0.10:
	$(GENVAPI) --library $(srcdir)/gstreamer-tag-0.10 $(PACKAGESDIR)/gstreamer-tag-0.10/gstreamer-tag-0.10.gi

gstreamer-video-0.10:
	$(GENVAPI) --library $(srcdir)/gstreamer-video-0.10 $(PACKAGESDIR)/gstreamer-video-0.10/gstreamer-video-0.10-custom.vala $(PACKAGESDIR)/gstreamer-video-0.10/gstreamer-video-0.10.gi

gtk+-2.0:
	$(GENVAPI) --library $(srcdir)/gtk+-2.0 $(PACKAGESDIR)/gtk+-2.0/gtk+-2.0-custom.vala $(PACKAGESDIR)/gtk+-2.0/gtk+-2.0.gi

gtk+-3.0:
	$(GENVAPI) --library $(srcdir)/gtk+-3.0 $(PACKAGESDIR)/gtk+-3.0/gtk+-3.0-custom.vala $(PACKAGESDIR)/gtk+-3.0/gtk+-3.0.gi

gtksourceview-2.0:
	$(GENVAPI) --library $(srcdir)/gtksourceview-2.0 $(PACKAGESDIR)/gtksourceview-2.0/gtksourceview-2.0.gi

gtksourceview-3.0:
	$(GENVAPI) --library $(srcdir)/gtksourceview-3.0 --pkg atk --pkg gdk-3.0 --pkg gdk-pixbuf-2.0 --pkg gio-2.0 --pkg gtk+-3.0 --pkg pango --pkg cairo --metadatadir $(METADATADIR) $(GIRDIR)/GtkSource-3.0.gir

gudev-1.0:
	$(GENVAPI) --library $(srcdir)/gudev-1.0 --metadatadir $(METADATADIR) $(METADATADIR)/GUdev-1.0-custom.vala $(GIRDIR)/GUdev-1.0.gir

hildon-1:
	$(GENVAPI) --library $(srcdir)/hildon-1 $(PACKAGESDIR)/hildon-1/hildon-1-custom.vala $(PACKAGESDIR)/hildon-1/hildon-1.gi

hildon-fm-2:
	$(GENVAPI) --library $(srcdir)/hildon-fm-2 $(PACKAGESDIR)/hildon-fm-2/hildon-fm-2.gi

json-glib-1.0:
	$(GENVAPI) --library $(srcdir)/json-glib-1.0 --metadatadir $(METADATADIR) $(METADATADIR)/Json-1.0-custom.vala --pkg gio-2.0 $(GIRDIR)/Json-1.0.gir

libepc-1.0:
	$(GENVAPI) --library $(srcdir)/libepc-1.0 $(PACKAGESDIR)/libepc-1.0/libepc-1.0.gi

libgda-4.0:
	$(GENVAPI) --library $(srcdir)/libgda-4.0 $(PACKAGESDIR)/libgda-4.0/libgda-4.0-custom.vala $(PACKAGESDIR)/libgda-4.0/libgda-4.0.gi

libgda-report-4.0:
	$(GENVAPI) --library $(srcdir)/libgda-report-4.0 $(PACKAGESDIR)/libgda-report-4.0/libgda-report-4.0.gi

libgdata:
	$(GENVAPI) --library $(srcdir)/libgdata --metadatadir $(METADATADIR) $(GIRDIR)/GData-0.0.gir

libglade-2.0:
	$(GENVAPI) --library $(srcdir)/libglade-2.0 $(PACKAGESDIR)/libglade-2.0/libglade-2.0.gi

libgnome-2.0:
	$(GENVAPI) --library $(srcdir)/libgnome-2.0 $(PACKAGESDIR)/libgnome-2.0/libgnome-2.0.gi

libgnome-menu:
	$(GENVAPI) --library $(srcdir)/libgnome-menu $(PACKAGESDIR)/libgnome-menu/libgnome-menu-custom.vala $(PACKAGESDIR)/libgnome-menu/libgnome-menu.gi

libgnomeui-2.0:
	$(GENVAPI) --library $(srcdir)/libgnomeui-2.0 $(PACKAGESDIR)/libgnomeui-2.0/libgnomeui-2.0-custom.vala $(PACKAGESDIR)/libgnomeui-2.0/libgnomeui-2.0.gi

libgsf-1:
	$(GENVAPI) --library $(srcdir)/libgsf-1 $(PACKAGESDIR)/libgsf-1/libgsf-1-custom.vala $(PACKAGESDIR)/libgsf-1/libgsf-1.gi

libnotify:
	$(GENVAPI) --library $(srcdir)/libnotify $(PACKAGESDIR)/libnotify/libnotify.gi

liboobs-1:
	$(GENVAPI) --library $(srcdir)/liboobs-1 $(PACKAGESDIR)/liboobs-1/liboobs-1.gi

libpeas-1.0:
	$(GENVAPI) --library $(srcdir)/libpeas-1.0 --metadatadir $(METADATADIR) $(GIRDIR)/Peas-1.0.gir

librsvg-2.0:
	$(GENVAPI) --library $(srcdir)/librsvg-2.0 $(PACKAGESDIR)/librsvg-2.0/librsvg-2.0.gi

libsexy:
	$(GENVAPI) --library $(srcdir)/libsexy $(PACKAGESDIR)/libsexy/libsexy.gi

libsoup-2.2:
	$(GENVAPI) --library $(srcdir)/libsoup-2.2 $(PACKAGESDIR)/libsoup-2.2/libsoup-2.2.gi

libsoup-2.4:
	$(GENVAPI) --library $(srcdir)/libsoup-2.4 --metadatadir $(METADATADIR) $(METADATADIR)/Soup-2.4-custom.vala --pkg gio-2.0 $(GIRDIR)/Soup-2.4.gir

libwnck-1.0:
	$(GENVAPI) --library $(srcdir)/libwnck-1.0 $(PACKAGESDIR)/libwnck-1.0/libwnck-1.0.gi

libwnck-3.0:
	$(GENVAPI) --library $(srcdir)/libwnck-3.0 --metadatadir $(METADATADIR) --pkg gio-2.0 --pkg gtk+-3.0 $(GIRDIR)/Wnck-3.0.gir

loudmouth-1.0:
	$(GENVAPI) --library $(srcdir)/loudmouth-1.0 $(PACKAGESDIR)/loudmouth-1.0/loudmouth-1.0-custom.vala $(PACKAGESDIR)/loudmouth-1.0/loudmouth-1.0.gi

mx-1.0:
	$(GENVAPI) --library $(srcdir)/mx-1.0 --metadatadir $(METADATADIR) $(METADATADIR)/Mx-1.0-custom.vala $(GIRDIR)/Mx-1.0.gir

pango:
	$(GENVAPI) --library $(srcdir)/pango $(PACKAGESDIR)/pango/pango-custom.vala $(PACKAGESDIR)/pango/pango.gi

pangocairo:
	$(GENVAPI) --library $(srcdir)/pangocairo --metadatadir $(METADATADIR) $(GIRDIR)/PangoCairo-1.0.gir

poppler-glib:
	$(GENVAPI) --library $(srcdir)/poppler-glib $(PACKAGESDIR)/poppler-glib/poppler-glib.gi

purple:
	$(GENVAPI) --library $(srcdir)/purple $(PACKAGESDIR)/purple/purple-custom.vala $(PACKAGESDIR)/purple/purple.gi

rest-0.6:
	$(GENVAPI) --library $(srcdir)/rest-0.6 $(PACKAGESDIR)/rest-0.6/rest-0.6-custom.vala $(PACKAGESDIR)/rest-0.6/rest-0.6.gi

rest-extras-0.6:
	$(GENVAPI) --library $(srcdir)/rest-extras-0.6 $(PACKAGESDIR)/rest-extras-0.6/rest-extras-0.6-custom.vala $(PACKAGESDIR)/rest-extras-0.6/rest-extras-0.6.gi

rest-0.7:
	$(GENVAPI) --library $(srcdir)/rest-0.7 --metadatadir $(METADATADIR) $(GIRDIR)/Rest-0.7.gir

tracker-indexer-module-1.0:
	$(GENVAPI) --library $(srcdir)/tracker-indexer-module-1.0 $(PACKAGESDIR)/tracker-indexer-module-1.0/tracker-indexer-module-1.0-custom.vala $(PACKAGESDIR)/tracker-indexer-module-1.0/tracker-indexer-module-1.0.gi

twitter-glib-1.0:
	$(GENVAPI) --library $(srcdir)/twitter-glib-1.0 $(PACKAGESDIR)/twitter-glib-1.0/twitter-glib-1.0.gi

unique-1.0:
	$(GENVAPI) --library $(srcdir)/unique-1.0 $(PACKAGESDIR)/unique-1.0/unique-1.0.gi

vte:
	$(GENVAPI) --library $(srcdir)/vte $(PACKAGESDIR)/vte/vte.gi

vte-2.90:
	$(GENVAPI) --library $(srcdir)/vte-2.90 --metadatadir $(METADATADIR) --pkg atk --pkg gdk-3.0 --pkg gtk+-3.0 --pkg gio-2.0 --pkg pango $(GIRDIR)/Vte-2.90.gir $(METADATADIR)/Vte-2.90-custom.vala

webkit-1.0:
	$(GENVAPI) --library $(srcdir)/webkit-1.0 $(PACKAGESDIR)/webkit-1.0/webkit-1.0.gi
