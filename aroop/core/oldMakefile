
include config.mk

VSOURCES=$(wildcard vsrc/*.vala)

DIRS+=src vsrc

INCLUDES+=-Iinc
SOURCES=$(wildcard $(addsuffix /*.c,$(DIRS)))
OBJECTS=$(addsuffix .o, $(basename $(SOURCES)))
TARGET_O=libaroop_core.o
TARGET_BASIC_O=libaroop_core_basic.o
TARGET_AR=libaroop_core.a
TARGETS=$(TARGET_O) $(TARGET_BASIC_O) $(TARGET_AR)

ifndef ECHO
ECHO=echo
endif


AROOP_CONCATENATED_FILE=single_file_aroop_core.c

#./platform/linux/inc/linux_config.h \
./platform/linux/inc/linux_graphics.h

SINGLE_FILE_HEADER_SEQUENCE= \
./inc/aroop_core_type_conversion.h \
./inc/core/decorator.h \
./platform/linux/inc/linux_logger.h \
./inc/core/config.h \
./inc/core/logger.h \
./inc/core/thread.h \
./inc/core/memory.h \
./inc/opp/opp_factory_types.h \
./inc/opp/opp_rbtree_internal.h \
./inc/opp/opp_factory.h \
./inc/opp/opp_iterator.h \
./inc/opp/opp_factory_profiler.h \
./inc/opp/opp_salt.h \
./inc/opp/opp_indexed_list.h \
./inc/aroop_core.h \
./inc/opp/opp_queue.h \
./inc/opp/opp_str2.h \
./inc/opp/opp_list.h \
./inc/opp/opp_hash_table.h \
./inc/core/txt.h \
./inc/opp/opp_type.h \
./inc/opp/opp_io.h \
./inc/opp/opp_thread_main.h \
./inc/opp/opp_watchdog.h \
./inc/opp/opp_hash.h \
./inc/opp/opp_any_obj.h \
./inc/aroop_error.h \
./inc/aroop_assignment.h \
./inc/aroop_factory.h \
./inc/aroop_memory_profiler.h \
./inc/aroop_core_type_info.h 


CC+=-ggdb3
#CC+=-O2

all:$(TARGET_AR) $(TARGET_O) $(TARGET_BASIC_O)

$(TARGET_AR):$(OBJECTS)
	$(AR) crv $(TARGET_AR) $(OBJECTS)

#$(TARGET_O):$(OBJECTS)
#	$(CC) $(CFLAGS) -c $(INCLUDES) $(SOURCES) -o $@

.c.o:
	$(CC) $(CFLAGS) -c $(INCLUDES) $< -o $@

clean:
	$(RM) $(OBJECTS) $(TARGETS) $(AROOP_CONCATENATED_FILE)

$(AROOP_CONCATENATED_FILE):$(SOURCES)
	$(ECHO) "#define AROOP_CONCATENATED_FILE\n"  > $@
	cat $(SINGLE_FILE_HEADER_SEQUENCE) >> $@
	cat $(SOURCES) >> $@

$(TARGET_O):$(AROOP_CONCATENATED_FILE)
	$(CC) $(CFLAGS) -c $< -o $@

$(TARGET_BASIC_O):$(AROOP_CONCATENATED_FILE)
	$(CC) $(CFLAGS) -DAROOP_BASIC -c $< -o $@

nogenvapi:
	$(VALAC) --profile=aroop -D POSIX -C  --vapidir $(VAPI_DIR) --vapidir=vapi --pkg=posix  --pkg=opp --pkg=aroop_core $(VSOURCES) --library aroop_array --vapi=vapi/aroop_array.vapi --use-header --header=inc/aroop_array.h

