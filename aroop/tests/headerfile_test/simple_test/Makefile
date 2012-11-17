
VHEADER_FILE=vinc/orchard.h
INCLUDES+=-Ivinc
TESTVAPI=--pkg orchard

export TESTVAPI
export VHEADER_FILE
export INCLUDES

all:
	$(MAKE) -f ../../valamake.mk genvapi
	$(MAKE) -f ../../valamake.mk test.bin

clean:
	$(MAKE) -f ../../valamake.mk clean

