#ifndef __RS232_MAIN_
#define __RS232_MAIN_

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
	int 		res;
	size_t		todo = sizeof(rs232data->comm_req);

	printf("[%s] block while sending\n", __FUNCTION__);

	errno = 0;
	res = write(rs232data->fd, &rs232data->comm_req, todo);

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

int rs232_main_mode(rs232_data_t *rs232data)
{
	printf("[%s] main mode\n", __FUNCTION__);

	/* send command */
	if ( rs232_send(rs232data) < 1 )
		return -1;

	/* receive data */
	rs232_receive(rs232data);

	return 0;
}

#endif /* __RS232_MAIN_ */
