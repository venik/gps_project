/*
 * Private property of IT6-DSPLAB group. 
 *
 * Description: rs232 dumper - dump realtime gps-data from rs232 to a output file.
 *
 * Developer: Alex Nikiforov nikiforov.al [at] gmail.com
 *
 */

#include <stdio.h>
#include <unistd.h>
#include <stdint.h>
#include <string.h>

#include <termios.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <errno.h>

#define MAXLINE 255

typedef struct rs232_data_s {
	char	name[MAXLINE];
	int	fd;
	uint8_t	buf[1024];			// FIXME - correct buffer
} rs232_data_t;

/*
 * Description: open rs232 interface with name dev_name
 * Return: filedescriptor or 0 if failed
 */
int rs232_open_device(char *dev_name)
{
	int fd;
	struct termios options;

	fd = open(dev_name, (O_RDWR | O_NOCTTY/* | O_NONBLOCK*/));

	if( fd == -1 ) {
		printf("[ERR] cannot open rs232 device [%s]. errno %s\n", dev_name, strerror(errno));
		return 0;
	}

	errno = 0;
	if( tcgetattr(fd, &options) == -1 ) {
		printf("[ERR] cannot get rs232 options. errno %s\n", strerror(errno));
		return 0;
	}
	
	/* set port speed */
	cfsetispeed(&options, B115200);
	cfsetospeed(&options, B115200);

	/* Set into raw, no echo mode */
	options.c_iflag = IGNBRK;
	options.c_lflag = 0;
	options.c_oflag = 0;
	options.c_cflag |= CLOCAL | CREAD;

	options.c_cc[VMIN] = 1;
	options.c_cc[VTIME] = 5;

	/* 8N1 */
	options.c_cflag = (options.c_cflag & ~CSIZE) | CS8;    /* mask the character size bits
								* and  select 8 data bits */
	options.c_cflag &= ~(PARENB | PARODD);	/* no parity */
	options.c_cflag &= ~CSTOPB;		/* 1 stop bit (not 2)*/

	options.c_cflag &= ~CRTSCTS;		/* no flow control*/

	options.c_iflag &= ~(IXON|IXOFF|IXANY);

	/* tcflush(fd, TCIFLUSH); */
	if (tcsetattr(fd, TCSANOW, &options) == -1) {
		printf("Error, can't set rs232 attributes. errno %s", strerror(errno));
		return 0;
	}

	return fd;
}

int rs232_receive(rs232_data_t	*rs232data)
{
	int res, todo = 10;		// FIXME - fix todo

	printf("[%s] block while receiving\n", __FUNCTION__);

	errno = 0;
	res = read(rs232data->fd, rs232data->buf, todo);

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

int rs232_send(rs232_data_t	*rs232data)
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

void rs232_destroy(rs232_data_t	*rs232data)
{
	close(rs232data->fd);
}

int main(int argc, char **argv)
{
	rs232_data_t	rs232data = {};
	
	if( argc < 3 ) {
		printf("\n[ERR] wrong parameters, use like this \n#rs232_dumper -p /dev/rs232_port\nExiting...\n\n");
		return -1;
	}

	printf("\nHello, this is rs232 dumper for GPS-project \n");

	/* check parameters via getopt or something else */
	//printf("try to copy [%s] \n", argv[2]);
	snprintf(rs232data.name, MAXLINE, "%s", argv[2]);

	errno = 0;
	rs232data.fd = rs232_open_device(rs232data.name); 
	if( rs232data.fd == 0 )
		return -1;

	/* send command */
	if ( rs232_send(&rs232data) < 1 )
		return -1;

	/* receive data */
	rs232_receive(&rs232data);

	/* free memory and close all fd's */
	rs232_destroy(&rs232data);

	return 0;
}
