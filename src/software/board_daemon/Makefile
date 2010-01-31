CC = gcc
CFLAGS += -Wall -g

all: board_daemon.o
	$(CC) $(CFLAGS) -o board_daemon board_daemon.o

board_daemon.o: board_daemon.c board_daemon.h

clean:
	rm board_daemon board_daemon.o 

tags:
	ctags -R --exclude=doc --exclude=,, --exclude=++
