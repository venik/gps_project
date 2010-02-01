CC = gcc
ROOT = ../../software
INCLUDE = -I. -I$(ROOT)/include
CFLAGS += -Wall -g $(INCLUDE)

all: rs232_ttool.o
	$(CC) $(CFLAGS) -o rs232_ttool rs232_ttool.o

rs232_ttool.o: rs232_ttool.c

clean:
	rm rs232_ttool rs232_ttool.o flush tags

tags:
	ctags -R --exclude=doc --exclude=,, --exclude=++
