
TESTVAPI=vsrc/X.vapi
VHEADER_FILE=include/A.h 
VLIBRARY_FILE=vapi/Y
INCLUDES+=-Iinclude

export TESTVAPI
export VLIBRARY_FILE
export VHEADER_FILE
export INCLUDES

all:
	$(MAKE) -f ../../valamake.mk genvapi
	$(MAKE) -f ../../valamake.mk libs

clean:
	$(MAKE) -f ../../valamake.mk clean

