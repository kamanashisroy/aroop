
TARGET_O=libaroop_core.o
TARGET_BASIC_O=libaroop_core_basic.o
TARGET_LAR=libaroop_core.la
TARGET_AR=libaroop_core_static.a libaroop_core_debug.a
bin_PROGRAMS=$(TARGET_O) $(TARGET_BASIC_O)
lib_LTLIBRARIES=$(TARGET_LAR)
lib_LIBRARIES=$(TARGET_AR)
AROOP_CORE_SOURCE_FILES = \
src/aroop_core.c     src/opp_any_obj.c           src/opp_hash.c          src/opp_list.c             src/opp_salt.c         src/opp_watchdog.c \
src/aroop_factory.c  src/opp_factory.c           src/opp_hash_table.c    src/opp_queue.c            src/opp_str2.c \
src/aroop_txt.c      src/opp_factory_profiler.c  src/opp_indexed_list.c  src/opp_rbtree_internal.c

pkgincludedir=$(includedir)/aroop_core-1.0
nobase_pkginclude_HEADERS= \
aroop/aroop_array.h       aroop/aroop_core.h                  aroop/aroop_core_type_info.h  aroop/aroop_factory.h \
aroop/aroop_assignment.h  aroop/aroop_core_type_conversion.h  aroop/aroop_error.h           aroop/aroop_memory_profiler.h  \
aroop/opp/opp_any_obj.h  aroop/opp/opp_factory_profiler.h  aroop/opp/opp_hash.h        aroop/opp/opp_indexed_list.h  aroop/opp/opp_iterator.h  aroop/opp/opp_queue.h            aroop/opp/opp_salt.h  aroop/opp/opp_thread_main.h  aroop/opp/opp_watchdog.h \
aroop/opp/opp_factory.h  aroop/opp/opp_factory_types.h     aroop/opp/opp_hash_table.h  aroop/opp/opp_io.h            aroop/opp/opp_list.h      aroop/opp/opp_rbtree_internal.h  aroop/opp/opp_str2.h  aroop/opp/opp_type.h \
aroop/core/config.h  aroop/core/decorator.h  aroop/core/logger.h  aroop/core/memory.h  aroop/core/thread.h  aroop/core/xtring.h \
aroop/platform/linux/inc/linux_config.h  aroop/platform/linux/inc/linux_graphics.h  aroop/platform/linux/inc/linux_logger.h

AROOP_CORE_INCLUDES=-Iaroop

libaroop_core_la_SOURCES = $(AROOP_CORE_SOURCE_FILES)
libaroop_core_la_CPPFLAGS = $(AROOP_CORE_INCLUDES)
libaroop_core_static_a_SOURCES = $(AROOP_CORE_SOURCE_FILES)
libaroop_core_static_a_CPPFLAGS = $(AROOP_CORE_INCLUDES)
libaroop_core_debug_a_SOURCES = $(AROOP_CORE_SOURCE_FILES)
libaroop_core_debug_a_CPPFLAGS = -ggdb3 $(AROOP_CORE_INCLUDES)
libaroop_core_o_SOURCES = $(AROOP_CORE_SOURCE_FILES)
libaroop_core_o_CPPFLAGS = $(AROOP_CORE_INCLUDES)
libaroop_core_basic_o_SOURCES = $(AROOP_CORE_SOURCE_FILES)
libaroop_core_basic_o_CPPFLAGS=-DAROOP_BASIC $(AROOP_CORE_INCLUDES)


pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = aroop_core-1.0.pc

