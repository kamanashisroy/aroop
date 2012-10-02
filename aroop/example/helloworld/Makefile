
include ../valamake.mk

all:test.bin

genvapi_old:
	$(VALAC) --profile=aroop -D POSIX -C  --vapidir $(VAPI) --vapidir vapi $(VSOURCES) --library zoo --vapi=zoo.vapi --use-header --header=$(GEN_HEADER)
