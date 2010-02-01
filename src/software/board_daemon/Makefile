CC = gcc
ROOT = ../
INCLUDE = -I. -I$(ROOT)/include
CFLAGS += -Wall -g -lpthread $(INCLUDE)

all: board_daemon.o
	$(CC) $(CFLAGS) -o board_daemon board_daemon.o

board_daemon.o: board_daemon.c board_daemon.h rs232_dumper.h gui_server.h

clean:
	rm board_daemon board_daemon.o 

tags:
	ctags -R --exclude=doc --exclude=,, --exclude=++
