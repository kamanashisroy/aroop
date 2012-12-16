
VALA_HOME=../../../
VALAC=$(VALA_HOME)/aroop/compiler/aroopc
VAPI= --vapidir $(VALA_HOME)/vapi --vapidir $(VALA_HOME)/aroop/vapi

VSOURCES=$(wildcard vsrc/*.vala)
VSOURCE_BASE=$(basename $(notdir $(VSOURCES)))
CSOURCES=$(addprefix vsrc/, $(addsuffix .c,$(VSOURCE_BASE)))
OBJECTS=$(addprefix vsrc/, $(addsuffix .o,$(VSOURCE_BASE)))

INCLUDES+=-I$(VALA_HOME)/aroop/core/inc
LIBS+=-L$(VALA_HOME)/aroop/core/ -laroop_core

ifeq ($(VLIBRARY_FILE),)
VLIBRARY=
else
VLIBRARY=--library $(VLIBRARY_FILE)
endif

ifeq ($(VHEADER_FILE),)
VHEADER=
else
VHEADER=--use-header --header=$(VHEADER_FILE)
endif

CC+=-ggdb -ggdb3

genvapi:
	$(VALAC) --profile=aroop -D POSIX -C $(VAPI) --vapidir ../../vapi --vapidir vapi $(TESTVAPI) $(VLIBRARY) $(VHEADER) $(VSOURCES)

.c.o:
	$(CC) $(CFLAGS) -c $(INCLUDES) $< -o $@

test.bin:$(OBJECTS)
	$(CC) $(OBJECTS) $(LIBS) -o $@

clean:
	$(RM) $(CSOURCES)
	$(RM) $(VHEADER_FILE)
	$(RM) $(VLIBRARY_FILE).vapi
	$(RM) $(GEN_HEADER)
	$(RM) test.bin
	$(RM) $(OBJECTS)

