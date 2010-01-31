#ifndef __RS232_DUMPER_
#define __RS232_DUMPER_

#include "rs232_dumper.h"

/********************************************************************************************
 * Description: open rs232 interface with name dev_name
 ********************************************************************************************/
int rs232_open_device(bd_data_t *bd_data)
{
	struct termios options;
	struct pollfd	*pfd = &bd_data->client[BOARD_FD];

	//TRACE(0, "[%s]\n", __func__);

	pfd->fd = open(bd_data->name, (O_RDWR | O_NOCTTY/* | O_NONBLOCK*/));

	if( pfd->fd < 0 ) {
		snprintf((char *)bd_data->send_buf, MAXLINE, "[%s] ERR during open rs232 [%s]. errno: %s\n",
			__func__, bd_data->name, strerror(errno));

		TRACE(0, "%s", bd_data->send_buf);
		return pfd->fd;
	}

	if( tcgetattr(pfd->fd, &options) == -1 ) {
		snprintf((char *)bd_data->send_buf, MAXLINE, "[%s] [ERR] can't get rs232 options. errno %s",
			__func__, strerror(errno));

		TRACE(0,"%s\n", (char *)bd_data->send_buf);

		close(pfd->fd);
		pfd->fd = -1;

		return pfd->fd;
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
	if (tcsetattr(pfd->fd, TCSANOW, &options) == -1) {
		snprintf((char *)bd_data->send_buf, MAXLINE, "[%s] [ERR] can't set rs232 attributes. errno %s",
			__func__, strerror(errno));

		TRACE(0, "%s\n", (char *)bd_data->send_buf);
		
		close(pfd->fd);
		pfd->fd = -1;

		return pfd->fd;
	}

	TRACE(0, "[%s] succsessfully opened fd = [%d]\n", __func__, pfd->fd);

	return pfd->fd;
}

void *rs232_process(void *priv)
{
	bd_data_t *bd_data = (bd_data_t *)priv;
	
	rs232_open_device(bd_data);

	while(bd_data->need_exit) {
		TRACE(0, "[%s] Process...\n", __func__);

		if( bd_data->client[BOARD_FD].fd < 0 ) {
			TRACE(0, "[%s] Warning. Board not connected!!!\n", __func__);
		}

		usleep(3000000);
	}

	return NULL;
}

#endif /* __RS232_DUMPER_ */
