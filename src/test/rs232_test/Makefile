CC = gcc
CFLAGS += -Wall -g

all: rs232_ttool.o
	$(CC) $(CFLAGS) -o rs232_ttool rs232_ttool.o

rs232_ttool.o: rs232_ttool.c gps_registers.h

clean:
	rm rs232_ttool rs232_ttool.o

tags:
	ctags -R --exclude=doc --exclude=,, --exclude=++
