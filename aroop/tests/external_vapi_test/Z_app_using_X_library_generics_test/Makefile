TESTVAPI=--vapidir ../X_library_test/vapi --pkg Y --vapidir ../X_library_test/vsrc/
INCLUDES+=-I../X_library_test/include
OBJECTS+=../X_library_test/vsrc/A.o

export TESTVAPI
export INCLUDES
export OBJECTS

all:
	$(MAKE) -f ../../valamake.mk genvapi
	$(MAKE) -f ../../valamake.mk test.bin
	./test.bin

clean:
	$(MAKE) -f ../../valamake.mk clean

