#ifndef __RS232_TEST_
#define __RS232_TEST_

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

int rs232_test_prepare(rs232_data_t *rs232data)
{
	int fd, res;
	
	printf("[%s] prepare data\n", __FUNCTION__);

	fd = open("/dev/urandom", (O_RDONLY) );
	
	if( fd == -1 ) {
		printf("[ERR] cannot open urandom while generete test file. errno %s\n", strerror(errno));
		return -1;
	}

	res = read(fd, rs232data->send_buf, BUF_SIZE);
	
	if(res != BUF_SIZE) {
		printf("[ERR] cannot read from urandom [%d] bytes. errno %s\n", BUF_SIZE, strerror(errno));
		return -1;
	}

	close(fd);

	return 0;
}

int rs232_test_receive(rs232_data_t *rs232data)
{
	int res, todo = 1;		// FIXME - fix todo

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

int rs232_test_send(rs232_data_t *rs232data)
{
	int 		res, todo = 1;		// FIXME - fix to BUF_SIZE 

	printf("[%s] block while sending\n", __FUNCTION__);

	errno = 0;
	res = write(rs232data->fd, rs232data->send_buf, todo);

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

int rs232_test_mode(rs232_data_t *rs232data)
{
	int res;

	printf("[%s] testing mode\n", __FUNCTION__);

	res = rs232_test_prepare(rs232data);
	if( res < 0) {
		printf("[ERR] test failed during prepare - problem on client side, not he board\n");
		return -1;
	}

	rs232_test_send(rs232data);
	printf("  send [%x] %c\n", rs232data->send_buf[0], rs232data->send_buf[0]);

	rs232_test_receive(rs232data);
	printf("  recv [%x]\n", rs232data->recv_buf[0]);

	return 0;
}

#endif /* __RS232_TEST_ */
