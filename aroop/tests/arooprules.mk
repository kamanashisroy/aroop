
all:
	$(MAKE) -f ../../valamake.mk genvapi
	$(MAKE) -f ../../valamake.mk test.bin

clean:
	$(MAKE) -f ../../valamake.mk clean

