TESTVAPI=--vapidir ../X_library_test/vsrc --pkg XX
TESTVAPI+=--vapidir ../Y_app_using_X_library_test/vsrc/ --pkg Y
INCLUDES+=-I../X_library_test/vsrc
INCLUDES+=-I../Y_app_using_X_library_test/vsrc
OBJECTS+=../X_library_test/vsrc/A.o
OBJECTS+=../Y_app_using_X_library_test/vsrc/D.o

export TESTVAPI
export INCLUDES
export OBJECTS

all:
	$(MAKE) -f ../../valamake.mk genvapi
	$(MAKE) -f ../../valamake.mk test.bin
	./test.bin

clean:
	$(MAKE) -f ../../valamake.mk clean

