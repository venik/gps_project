/*
 *
 * Description: rs232 dumper - dump realtime gps-data from rs232 to a output file.
 *
 * Developer: Alex Nikiforov nikiforov.al [at] gmail.com
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdint.h>
#include <string.h>

#include <termios.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <sys/socket.h>
#include <netinet/in.h>

#include <errno.h>

#include "rs232_dumper.h"

#include "rs232_main_mode.h"
#include "rs232_test_mode.h"

FILE *I;

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
	close(rs232data->sock);
	close(rs232data->fd);
}

void rs232_set_reg(rs232_data_t *rs232data)
{
	printf("[%s] set register mode", __FUNCTION__);

	if( rs232data->addr > 7 ) {
		printf("Address must be between 0 and 7\n");
		return;
	}

	if( rs232data->reg > 268435455 ) {		// 268435455 = (2^28 - 1)
		printf("Register value must be between 0 and 268435455\n");
		return;
	}

	/* create payload for request */ 
	//printf("before [0x%llx] \n", rs232data.comm_req);
	rs232data->comm_req |= ( (rs232data->addr << 1) | (rs232data->reg << 5) );
	printf("command for sending  [0x%016llx] \n", rs232data->comm_req);

	/* FIXME - add network part */

	return;
}

int rs232_fsm_connection(rs232_data_t *rs232data)
{
	fprintf(I, "[%s] waiting for connection\n", __FUNCTION__);
	rs232data->csock = accept(rs232data->sock, NULL, NULL);
	rs232data->todo = strlen(CONNECTION_CMD);
	rs232data->done = 0;

	return IDLE;
}

int rs232_fsm_say_ack(rs232_data_t *rs232data) 
{
	size_t	res;
	size_t 	real_todo = strlen(CONNECTION_ACK);
	

	res = write(rs232data->csock, CONNECTION_ACK, real_todo);
	
	fprintf(I, "[%s] wrote [%d] bytes\n", __FUNCTION__, res);

	return 0;
}

int rs232_fsm_idle(rs232_data_t *rs232data)
{
	size_t	res;
	size_t 	real_todo = strlen(CONNECTION_CMD);
	
	res = read(rs232data->csock, rs232data->recv_buf + rs232data->done, rs232data->todo);

	rs232data->done += res;
	if( rs232data->done == real_todo ) {
		fprintf(I, "all data sucessful received =] \n");
		rs232_fsm_say_ack(rs232data);
		/* FIXME to next state */
		return BREAK;
	}

	return IDLE;
}

int rs232_fsm(rs232_data_t *rs232data)
{
	uint8_t		state = CONNECTION;

	while(1) {
		switch(state) {
		case CONNECTION:
			state = rs232_fsm_connection(rs232data);
			break;

		case IDLE:
			fprintf(I, "[%s] IDLE\n", __FUNCTION__);
			state = rs232_fsm_idle(rs232data);
			break;

		case BREAK:
			close(rs232data->csock);
			return -1;

		default:
			fprintf(I, "[%s] unknown state\n", __FUNCTION__);

		} // switch(state)
	} // while(1)

	return 0;
}

int main(int argc, char **argv)
{
	rs232_data_t	rs232data = {};
	struct	sockaddr_in	sin = {};
	socklen_t	len = sizeof(sin);
	int	ret = 0;
	
	rs232data.port = 1234;

	I = stdout;

	rs232data.sock = socket(AF_INET/* inet */, SOCK_STREAM/*2-way stream*/, 0);
	if( rs232data.sock < 0) {
		fprintf(I, "[%s] error during create socket. errno %s", __FUNCTION__, strerror(errno));
		return -1;
	}

	sin.sin_family = AF_INET;
	sin.sin_port = htons(rs232data.port);			// FIXME
	sin.sin_addr.s_addr = htonl(INADDR_ANY);	// listen on every interface

	ret = bind(rs232data.sock, (struct sockaddr *)&sin, len);
	if( ret < 0 ) {
		fprintf(I, "[%s] error during bind the socket on port [%d]", __FUNCTION__, rs232data.port);
		close(rs232data.sock);
		return -1;
	}

	ret = listen(rs232data.sock, 2);
	if( ret < 0 ) {
		fprintf(I, "[%s] error during listen() the socket on port [%d]", __FUNCTION__, rs232data.port);
		close(rs232data.sock);
		return -1;
	}
	
	rs232_fsm(&rs232data);

	/* predefine some values for a test purposes */
	//rs232data.comm_req = UINT32_MAX;
	//rs232data.addr = UINT32_MAX;

#if 0
	while ( (res = getopt(argc,argv,"hp:tgs:a:")) != -1){
		switch (res) {
		case 'h':
			rs232_banner();
			return -1;
		case 'p':
			printf("\t rs232 port set to [%s]\n", optarg);
			snprintf(rs232data.name, MAXLINE, "%s", optarg);
			break;
		case 't':
			rs232data.comm_req = RS232_TEST_MEMORY;
			break;
		case 'g':
			printf("\t gps mode\n");
			rs232data.comm_req |= RS232_GPS_START;
			break;

		/* set register */
		case 's':
			rs232data.comm_req = RS232_SET_REG;
			rs232data.reg = atoll(optarg);
			printf("\t gps mode\n");
			break;
		case 'a':
			rs232data.addr = atoll(optarg);
			printf("\t address [0x%llx]\n", rs232data.addr);
			break;

		default:
			return -1;
        	};
	};

	/* open COM - port */
	errno = 0;
	rs232data.fd = rs232_open_device(rs232data.name); 
	if( rs232data.fd == 0 )
		return -1;

	printf("\nHello, this is rs232 dumper for GPS-project \n");

	/* craft command for the board */
	switch( rs232data.comm_req ) {
	case RS232_SET_REG:
		rs232_set_reg(&rs232data);
		break;

	case RS232_TEST_MEMORY:
		rs232_test_memory(&rs232data);
		break;

	case RS232_GPS_START:
		printf("Not implement yet\n");
		return -1;

	default:
		printf("Unknown mode. Exit... \n");
		return -1;

	} // switch( rs232data.comm_req )
#endif

	/* free memory and close all fd's */
	rs232_destroy(&rs232data);

	return 0;
}
