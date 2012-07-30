
SOURCES=$(wildcard src/*.c)
OBJECTS=$(addsuffix .o, $(basename $(SOURCES)))


INCLUDES+=-I../../inc
LIBS+=-L../../ -laroop_core -lpthread

CC+=-ggdb -ggdb3

all:test

test:$(OBJECTS)
	$(CC) $(OBJECTS) $(LIBS) -o test.bin

.c.o:
	$(CC) $(CFLAGS) -c $(INCLUDES) $< -o $@
clean:
	$(RM) test.bin
	$(RM) $(OBJECTS)
