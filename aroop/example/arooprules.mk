
all:
	$(MAKE) -f ../../valamake.mk genvapi
	$(MAKE) -f ../../valamake.mk example.bin
	./example.bin

clean:
	$(MAKE) -f ../../valamake.mk clean

