#ifndef __RS232_MAIN_
#define __RS232_MAIN_

#define MAXLINE		255
#define BUF_SIZE	1024*1024	// 1 Mb

typedef struct rs232_data_s rs232_data_t;

typedef int (*rs232_dumper_cb)(rs232_data_t *);

struct rs232_data_s {
	char	name[MAXLINE];
	int	fd;
	uint8_t	send_buf[BUF_SIZE];
	uint8_t recv_buf[BUF_SIZE];	

	rs232_dumper_cb	cb;			// work callback
};

int rs232_receive(rs232_data_t	*rs232data)
{
	int res, todo = 10;		// FIXME - fix todo

	printf("[%s] block while receiving\n", __FUNCTION__);

	errno = 0;
	res = read(rs232data->fd, rs232data->recv_buf, todo);

	if( res < 0 ) {
		if( errno != EAGAIN ) {
			printf("[ERR] error occur while in data receiving. errno %s\n", strerror(errno));
			return -1;
		}

		printf("[WARN] EAGAIN occur while reading, need to do something =] \n");
	}

	if( todo != res ) {
		printf("[WARN] need [%d], but receive [%d]\n", todo, res);
		return 0;
	}

	return res;
}

int rs232_send(rs232_data_t *rs232data)
{
	uint8_t		comm = 0;
	int 		res, todo = sizeof(comm);		// FIXME - fix todo

	printf("[%s] block while sending\n", __FUNCTION__);

	errno = 0;
	res = write(rs232data->fd, &comm, todo);

	if( res < 0 ) {
		if( errno != EAGAIN ) {
			printf("[ERR] error occur while in data sending. errno %s\n", strerror(errno));
			return -1;
		}

		printf("[WARN] EAGAIN occur while sending, need to do something =] \n");
	}

	if( todo != res ) {
		printf("[WARN] need [%d], but send [%d]\n", todo, res);
		return 0; 
	}

	return res;
}

#endif /* __RS232_MAIN_ */
