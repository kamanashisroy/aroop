
VALA_HOME=../../../../
VALAC=$(VALA_HOME)/aroop/compiler/aroopc-0.1.0 --module-debug .error.
VAPI= --vapidir $(VALA_HOME)/vapi --vapidir $(VALA_HOME)/aroop/vapi

VSOURCES=$(wildcard vsrc/*.vala)
VSOURCE_BASE=$(basename $(notdir $(VSOURCES)))
CSOURCES=$(addprefix vsrc/, $(addsuffix .c,$(VSOURCE_BASE)))
OBJECTS+=$(addprefix vsrc/, $(addsuffix .o,$(VSOURCE_BASE)))

INCLUDES+=-I$(VALA_HOME)/aroop/core
#LIBS+=-L$(VALA_HOME)/aroop/core/ -laroop_core
LIBS+=$(VALA_HOME)/aroop/core/libaroop_core_debug.a

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

CC+=-ggdb3 -D AROOP_MODULE_NAME=\"Aroop\ Test\" -DAROOP_OPP_PROFILE -DAROOP_OPP_DEBUG

genvapi:
	$(VALAC) --profile=aroop -D POSIX -C $(VAPI) --vapidir ../../vapi --vapidir vapi $(TESTVAPI) $(VLIBRARY) $(VHEADER) $(VSOURCES)

.c.o:
	$(CC) $(CFLAGS) -c $(INCLUDES) $< -o $@

test.bin:$(OBJECTS)
	$(CC) $(OBJECTS) $(LIBS) -o $@

libs:$(OBJECTS)

clean:
	$(RM) $(CSOURCES)
	$(RM) $(VHEADER_FILE)
	$(RM) $(VLIBRARY_FILE).vapi
	$(RM) $(GEN_HEADER)
	$(RM) test.bin
	$(RM) $(OBJECTS)

