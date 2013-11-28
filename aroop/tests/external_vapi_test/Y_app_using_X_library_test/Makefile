
TESTVAPI=--vapidir ../X_library_test/vsrc --pkg XX
VHEADER_FILE=vsrc/Y.h 
VLIBRARY_FILE=vsrc/Y
INCLUDES+=-Ivsrc -I../X_library_test/vsrc

export TESTVAPI
export VLIBRARY_FILE
export VHEADER_FILE
export INCLUDES

all:
	$(MAKE) -f ../../valamake.mk genvapi
	$(MAKE) -f ../../valamake.mk libs

clean:
	$(MAKE) -f ../../valamake.mk clean

