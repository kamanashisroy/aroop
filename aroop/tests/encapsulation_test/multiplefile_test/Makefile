
VHEADER_FILE=inc/multiple.h
INCLUDES+=-Iinc

export VHEADER_FILE
export INCLUDES

all:
	$(MAKE) -f ../../valamake.mk genvapi
	$(MAKE) -f ../../valamake.mk test.bin

clean:
	$(MAKE) -f ../../valamake.mk clean

