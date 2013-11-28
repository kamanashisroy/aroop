
TESTVAPI=vsrc/X.vapi
VHEADER_FILE=vsrc/A.h 
VLIBRARY_FILE=vsrc/XX
INCLUDES+=-Ivsrc

export TESTVAPI
export VLIBRARY_FILE
export VHEADER_FILE
export INCLUDES

all:
	$(MAKE) -f ../../valamake.mk genvapi
	$(MAKE) -f ../../valamake.mk libs

clean:
	$(MAKE) -f ../../valamake.mk clean

