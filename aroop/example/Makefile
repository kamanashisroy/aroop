

VALAMAKE=$(MAKE) -f ../valamake.mk

all:
	$(VALAMAKE) -C helloworld genvapi
	$(VALAMAKE) -C helloworld test.bin
	helloworld/test.bin

clean:
	$(VALAMAKE) -C helloworld clean
