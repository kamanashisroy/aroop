
VALA_HOME=../../../
VALAC=$(VALA_HOME)/compiler/valac
VAPI=$(VALA_HOME)/vapi

VSOURCES=$(wildcard vsrc/*.vala)
VSOURCE_BASE=$(basename $(notdir $(VSOURCES)))
CSOURCES=$(addprefix vsrc/, $(addsuffix .c,$(VSOURCE_BASE)))
OBJECTS=$(addsuffix .o, $(basename $(CSOURCES)))

GEN_HEADER=inc/zoo.h

INCLUDES+=-I../../inc
LIBS+=-L../../ -laroop_core

CC+=-ggdb -ggdb3

all:test


genvapi:
	$(VALAC) --profile=aroop -D POSIX -C  --vapidir $(VAPI) --vapidir ../../vapi --pkg=aroop_core --vapidir vapi $(VSOURCES) --library zoo --vapi=zoo.vapi --use-header --header=$(GEN_HEADER)

.c.o:
	$(CC) $(CFLAGS) -c $(INCLUDES) $< -o $@

test:genvapi $(OBJECTS)
	$(CC) $(OBJECTS) $(LIBS) -o test.bin

clean:
	$(RM) vsrc/*.c
	$(RM) zoo.vapi
	$(RM) $(GEN_HEADER)
	$(RM) test.bin
	$(RM) $(OBJECTS)
