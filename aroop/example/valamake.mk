
VALA_HOME=../../../
VALAC=$(VALA_HOME)/aroop/compiler/aroopc
VAPI=$(VALA_HOME)/vapi

VSOURCES=$(wildcard vsrc/*.vala)
VSOURCE_BASE=$(basename $(notdir $(VSOURCES)))
CSOURCES=$(addprefix vsrc/, $(addsuffix .c,$(VSOURCE_BASE)))
OBJECTS=$(addprefix vsrc/, $(addsuffix .o,$(VSOURCE_BASE)))

INCLUDES+=-I$(VALA_HOME)/aroop/core/inc
LIBS+=-L$(VALA_HOME)/aroop/core/ -laroop_core

CC+=-ggdb -ggdb3

genvapi:
	$(VALAC) --profile=aroop -D POSIX -C  --vapidir $(VAPI) --vapidir ../../vapi --vapidir vapi $(VSOURCES)

.c.o:
	$(CC) $(CFLAGS) -c $(INCLUDES) $< -o $@

test.bin:genvapi $(OBJECTS)
	$(CC) $(OBJECTS) $(LIBS) -o $@

clean:
	$(RM) $(CSOURCES)
	$(RM) $(GEN_HEADER)
	$(RM) test.bin
	$(RM) $(OBJECTS)

