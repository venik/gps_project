#ifndef _RS232_DUMPER_H
#define _RS232_DUMPER_H

#define MAXLINE		255
#define BUF_SIZE	1024*1024	// 1 Mb

enum rs232_comm_request {
	RS232_SET_REG		= 1<<0,
	RS232_TEST_MEMORY	= 1<<1,
	RS232_GPS_START		= 1<<2
};

/* FIXME */
enum rs232_comm_response {
	BOARD_NOT_ACK		= 1<<0,
};

typedef struct rs232_data_s rs232_data_t;

typedef int (*rs232_dumper_cb)(rs232_data_t *);

struct rs232_data_s {

	char		name[MAXLINE];
	int		fd;
	uint8_t 	recv_buf[BUF_SIZE];	

	uint64_t	comm_req;			// request comm

	/* set register part */
	uint64_t	reg;				/* register 27 bits */
	uint64_t	addr;				/* address of register 4 bits */

};

#endif /* _RS232_DUMPER_H */
