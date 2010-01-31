#include "rs232_dumper.h"

/*
 * Description: open rs232 interface with name dev_name
 * Return: 	filedescriptor or 0 if failed
 */
int rs232_open_device(rs232_data_t *rs232data)
{
	int fd;
	struct termios options;

	fprintf(I, "[%s]\n", __func__);

	fd = open(rs232data->name, (O_RDWR | O_NOCTTY/* | O_NONBLOCK*/));

	if( fd < 0 ) {
		snprintf((char *)rs232data->send_buf, MAXLINE, "[%s] ERR during open rs232 [%s]. errno: %s\n",
			__func__, rs232data->name, strerror(errno));

		fprintf(I, "%s", rs232data->send_buf);
		return fd;
	}

	if( tcgetattr(fd, &options) == -1 ) {
		snprintf((char *)rs232data->send_buf, MAXLINE, "[%s] [ERR] can't get rs232 options. errno %s",
			__func__, strerror(errno));

		fprintf(I,"%s\n", (char *)rs232data->send_buf);
		return -1;
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
		snprintf((char *)rs232data->send_buf, MAXLINE, "[%s] [ERR] can't set rs232 attributes. errno %s",
			__func__, strerror(errno));

		fprintf(I, "%s\n", (char *)rs232data->send_buf);
		return -1;
	}

	fprintf(I, "[%s] [%d] fd = [%d]\n", __func__, __LINE__, fd);

	return fd;
}
