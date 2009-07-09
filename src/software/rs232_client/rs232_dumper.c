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

#include "rs232_main_mode.h"
#include "rs232_test_mode.h"

/*
 * Description: print banner 
 * Return:  	nothing	
 */
void rs232_banner()
{
	printf("Hello this is rs232 dumper for gps-board project by DSP-lab. This is real cool banner\n");
	printf("Usage: rs232_client [options]\n");
	printf("Options:\n");
	printf("  -p:	give the rs232 port name, something like this /dev/ttyS0\n");
	printf("  -t:	board test mode\n");
	printf("  -h:	display this information\n");
}

/*
 * Description: open rs232 interface with name dev_name
 * Return: 	filedescriptor or 0 if failed
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

void rs232_destroy(rs232_data_t	*rs232data)
{
	close(rs232data->fd);
}

int main(int argc, char **argv)
{
	rs232_data_t	rs232data = {};
	int res;

	/* init defaults */
	rs232data.cb = &rs232_main_mode;

	/* parse command-line options */
	while ( (res = getopt(argc,argv,"hp:t")) != -1){
		switch (res) {
		case 'h':
			rs232_banner();
			return -1;
		case 'p':
			printf("rs232 port set to [%s]\n", optarg);
			snprintf(rs232data.name, MAXLINE, "%s", optarg);
			break;
		case 't':
			printf("test mode\n");
			rs232data.cb = &rs232_test_mode;
			break;
		default:
			return -1;
        	};
	};

	errno = 0;
	rs232data.fd = rs232_open_device(rs232data.name); 
	if( rs232data.fd == 0 )
		return -1;

	printf("\nHello, this is rs232 dumper for GPS-project \n");

	rs232data.cb(&rs232data);

	/* free memory and close all fd's */
	rs232_destroy(&rs232data);

	return 0;
}
