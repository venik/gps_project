#ifndef _RS232_DUMPER_H
#define _RS232_DUMPER_H

#define MAXLINE		255
#define BUF_SIZE	1024*1024	// 1 Mb

enum rs232_comm_request {
	RS232_TEST_MEMORY	= 1<<0,
	RS232_GPS_START		= 1<<1
};

enum rs232_comm_response {
	BOARD_MEMORY_OK		= 1<<4,
	BOARD_MEMORY_FAULT	= 0<<4 
};

typedef struct rs232_data_s rs232_data_t;

typedef int (*rs232_dumper_cb)(rs232_data_t *);

struct rs232_data_s {
	char		name[MAXLINE];
	int		fd;
	uint8_t 	recv_buf[BUF_SIZE];	
	uint64_t	comm_req;			// request comm

	//rs232_dumper_cb	cb;			// work callback
};

#endif /* _RS232_DUMPER_H */
