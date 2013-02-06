
TESTVAPI+=--vapidir=../base_test/ --pkg shotodol_base
VLIBRARY_FILE=shotodol_io
VHEADER_FILE=include/shotodol_io.h
INCLUDES+=-Iinclude
INCLUDES+=-I../base_test/include
OBJECTS+=$(wildcard ../base_test/vsrc/*.o)

export TESTVAPI
export VLIBRARY_FILE
export VHEADER_FILE
export INCLUDES
export OBJECTS

all:
	$(MAKE) -f ../../valamake.mk genvapi
	$(MAKE) -f ../../valamake.mk test.bin

test.bin:
	$(MAKE) -f ../../valamake.mk test.bin

clean:
	$(MAKE) -f ../../valamake.mk clean

