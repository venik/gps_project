#ifndef __RS232_TEST_
#define __RS232_TEST_

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

int rs232_test_receive(rs232_data_t *rs232data)
{
	uint64_t	comm = 0;
	int		res, todo = sizeof(comm);

	printf("[%s] block while receiving\n", __FUNCTION__);

	errno = 0;
	res = read(rs232data->fd, &comm, todo);

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

	/* the board response handler */
	if( comm & BOARD_NOT_ACK ) {
		printf("[%s] memoryon board is  corrupt =( \n", __FUNCTION__);
		return -1;
	}

	return res;
}

int rs232_test_send(rs232_data_t *rs232data)
{
	int 		res, todo = sizeof(rs232data->comm_req);

	printf("[%s] block while sending command \n", __FUNCTION__);

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
		return -1; 
	}

	return res;
}

static int rs232_test_memory(rs232_data_t *rs232data)
{
	printf("[%s] testing mode\n", __FUNCTION__);

	if( rs232_test_send(rs232data) < 0 )
		return -1;

	if( rs232_test_receive(rs232data) < 0 ) 
		return -1;

	return 0;
}

#endif /* __RS232_TEST_ */
