CC = gcc
CFLAGS += -Wall -g

all: rs232_dumper.o
	$(CC) $(CFLAGS) -o rs232_dumper rs232_dumper.o

rs232_dumper.o: rs232_dumper.c

clean:
	rm rs232_dumper rs232_dumper.o

tags:
	ctags -R --exclude=doc --exclude=,, --exclude=++
