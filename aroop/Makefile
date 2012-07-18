
include config.mk

VSOURCES=$(wildcard vsrc/*.vala)

DIRS+=src vsrc

INCLUDES+=-Iinc
SOURCES=$(wildcard $(addsuffix /*.c,$(DIRS)))
OBJECTS=$(addsuffix .o, $(basename $(SOURCES)))
TARGET_O=libaroop_core.o
TARGET_AR=libaroop_core.a

CC+=-ggdb3

all:$(TARGET_AR)

$(TARGET_AR):$(OBJECTS)
	$(AR) crv $(TARGET_AR) $(OBJECTS)

#$(TARGET_O):$(OBJECTS)
#	$(CC) $(CFLAGS) -c $(INCLUDES) $(SOURCES) -o $@

.c.o:
	$(CC) $(CFLAGS) -c $(INCLUDES) $< -o $@

clean:
	$(RM) $(OBJECTS) $(TARGET_AR)

genvapi:
	$(VALAC) --profile=aroop -D POSIX -C  --vapidir $(VAPI_DIR) --vapidir=vapi --pkg=posix  --pkg=opp --pkg=aroop_core $(VSOURCES) --library aroop_array --vapi=vapi/aroop_array.vapi --use-header --header=inc/aroop_array.h

