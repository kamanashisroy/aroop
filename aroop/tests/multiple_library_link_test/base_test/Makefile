
VLIBRARY_FILE=shotodol_base
VHEADER_FILE=include/shotodol_base.h
INCLUDES+=-Iinclude

export VLIBRARY_FILE
export VHEADER_FILE
export INCLUDES

all:
	$(MAKE) -f ../../valamake.mk genvapi
	$(MAKE) -f ../../valamake.mk libs

clean:
	$(MAKE) -f ../../valamake.mk clean

