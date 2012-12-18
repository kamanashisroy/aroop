
TESTVAPI=vsrc/X.vapi
INCLUDES=-Ivinc

export TESTVAPI
export INCLUDES

all:
	$(MAKE) -f ../../valamake.mk genvapi
	$(MAKE) -f ../../valamake.mk test.bin
	./test.bin

clean:
	$(MAKE) -f ../../valamake.mk clean

