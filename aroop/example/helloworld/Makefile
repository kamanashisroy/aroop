
VALA_HOME=../../../
VALAC=$(VALA_HOME)/compiler/valac
VAPI=$(VALA_HOME)/vapi

VSOURCES=$(wildcard vsrc/*.vala)
VSOURCE_BASE=$(basename $(notdir $(VSOURCES)))
CSOURCES=$(addprefix gsrc/, $(addsuffix .c,$(VSOURCE_BASE)))

INCLUDES+=-I../../inc
LIBS+=-L../../ -laroop_core

all:test

genvapi:
	$(VALAC) --profile=aroop -D POSIX -C  --vapidir $(VAPI) --vapidir vapi $(VSOURCES) --library zoo --vapi=zoo.vapi --use-header --header=zoo.h

test:genvapi
	$(CC) $(INCLUDES) vsrc/*.c -o test.bin

clean:
	$(RM) vsrc/*.c
	$(RM) zoo.vapi
	$(RM) zoo.h
	$(RM) test.bin
