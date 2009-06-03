/*
 * Private property of IT6-DSPLAB group. 
 *
 * Description: rs232 dumper - dump realtime gps-data from rs232 to file.
 *
 * Mainteiner: Alex Nikiforov nikiforov.al@gmail.com
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
} rs232_data_t;

/*
 * 
 * Description: open rs232 interface with name dev_name
 * Return: filedescriptor or 0 if failed
 */
int rs232_open_device(char *dev_name)
{
	int fd;
	struct termios options;

	fd = open(dev_name, (O_RDWR | O_NOCTTY | O_NONBLOCK) );

	if( fd == -1 ) {
		printf("Error, cannot open rs232 device [%s]. errno %s\n", dev_name, strerror(errno));
		return 0;
	}

	errno = 0;
	if( tcgetattr(fd, &options) == -1 ) {
		printf("Error, cannot get rs232 options. errno %s\n", strerror(errno));
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

	options.c_iflag &= ~(IXON|IXOFF|IXANY);
	
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

void rs232_destroy(rs232_data_t	*rs232data)
{
	close(rs232data->fd);
}

int main()
{
	rs232_data_t	rs232data = {};
	
	printf("Hello, this is rs232 dumper for GPS-project \n");

	errno = 0;
	rs232data.fd = rs232_open_device("/dev/ttyS0"); 
	if( rs232data.fd == 0 ) {
		return -1;
	}

	rs232_destroy(&rs232data);

	return 0;
}
