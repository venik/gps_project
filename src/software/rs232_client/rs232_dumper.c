/* Developer: Alex Nikiforov nikiforov.al [at] gmail.com */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdint.h>
#include <string.h>

#include <termios.h>
#include <signal.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <sys/socket.h>
#include <netinet/in.h>

#include <errno.h>

#include "rs232_dumper.h"


/*
 * Description: print banner 
 * Return:  	nothing	
 */
void rs232_banner()
{
	printf("Hello this is rs232 dumper for gps-board project by DSP-lab. This is real cool banner\n");
	printf("Usage: rs232_client [options]\n");
	printf("Options:\n");
	printf("  -p:	listen port\n");
	printf("  -h:	display this information\n");
}

/*
 * Description: open rs232 interface with name dev_name
 * Return: 	filedescriptor or 0 if failed
 */
int rs232_open_device(rs232_data_t *rs232data)
{
	int fd;
	struct termios options;
	char 	msg[MAXLINE];

	fd = open(rs232data->name, (O_RDWR | O_NOCTTY/* | O_NONBLOCK*/));

	if( fd == -1 ) {
		snprintf(msg, MAXLINE, "cannot open rs232 device [%s]", rs232data->name);
		fprintf(I, "[%s] %s. errno: %s\n", __FUNCTION__, msg, strerror(errno));
		rs232_fsm_say_err_errno(rs232data, msg);

		return 0;
	}

	errno = 0;
	if( tcgetattr(fd, &options) == -1 ) {
		snprintf(msg, MAXLINE, "[ERR] cannot get rs232 options");
		fprintf(I, "[%s] %s. errno: %s\n", __FUNCTION__, msg, strerror(errno));
		rs232_fsm_say_err_errno(rs232data, msg);
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
		snprintf(msg, MAXLINE, "Error, can't set rs232 attributes. errno");
		fprintf(I, "[%s] %s. errno: %s\n", __FUNCTION__, msg, strerror(errno));
		rs232_fsm_say_err_errno(rs232data, msg);
		return 0;
	}

	return fd;
}

static void rs232_destroy(rs232_data_t	*rs232data)
{
	close(rs232data->client[0].fd);
	close(rs232data->client[1].fd);
	close(rs232data->client[2].fd);
}

int rs232_connection(rs232_data_t *rs232data)
{
	fprintf(I, "[%s]\n", __func__);
	rs232data->client[GUI_FD].fd = accept(rs232data->client[LISTEN_FD].fd, NULL, NULL);

	return 0;
}

int rs232_fsm_say_ack(rs232_data_t *rs232data) 
{
	size_t 	real_todo = strlen(ACK);

	strcpy((char *)rs232data->send_buf, ACK);
	
	if( rs232_poll_write(rs232data, 1, real_todo) ) {
		/* error occur */
		return -1;
	}
	
	return 0;
}

static void rs232_fsm_say_err(rs232_data_t *rs232data) 
{
	//snprintf((char *)rs232data->send_buf, MAXLINE, "ERR: [%s]", rs232data->recv_buf);
	snprintf((char *)rs232data->send_buf, MAXLINE, "ERR: unknown command");
	size_t 	real_todo = strlen((char *)rs232data->send_buf);

	rs232_poll_write(rs232data, 1, real_todo);
}

static void rs232_fsm_say_err_errno(rs232_data_t *rs232data, char *str) 
{
	snprintf((char *)rs232data->send_buf, MAXLINE, "ERR: %s. errno: %s", str, strerror(errno));
	size_t 	real_todo = strlen((char *)rs232data->send_buf);

	rs232_poll_write(rs232data, 1, real_todo);
}

int rs232_get_command(rs232_data_t *rs232data) {

	size_t	res;
	size_t 	real_todo;
	int	i = 0;
	
	fprintf(I, "[%s]\n", __func__);

	do {
		res = 	strlen(rs232_commands[i]);
		real_todo = strncmp((const char *)rs232data->recv_buf, rs232_commands[i], res);

		if(real_todo == res ) {
			fprintf(I, "Yahooo\n");	
		}

		i++;
	} while(res != 0);

	return 0;
}

int rs232_fsm_set_port(rs232_data_t *rs232data)
{
	size_t	res;
	size_t 	real_todo = strlen(SET_PORT_CMD);

	/* comm + "len=" */
	if( rs232_poll_read(rs232data, 1, real_todo + 4) < 0 ) {
		/* error occur */
		return BREAK;
	}
	
	res = strncmp((const char *)rs232data->recv_buf, (const char *)SET_PORT_CMD, real_todo);

	//printf("[%s] incomming [%s]\n", __FUNCTION__, rs232data->recv_buf);

	if( res == 0 ) {
		fprintf(I, "[%s] RS232_PORT command identified =] \n", __FUNCTION__);

		/* convert len form the packet */
		rs232data->recv_buf[real_todo + 4] = '\0';
		
		real_todo = atoi((char *)&rs232data->recv_buf[real_todo]);

		if( real_todo == 0 ) {
			/* error occur */
			fprintf(I, "Bad size [%s] in the packet from GUI\n", (char *)(rs232data->recv_buf + real_todo));
			return BREAK;
		}

		/* name + 0x0d + 0x0a */
		if( rs232_poll_read(rs232data, 1, real_todo + 2) < 0 ) {
			/* error occur */
			return BREAK;
		}

		rs232data->recv_buf[real_todo] = '\0';
		strncpy(rs232data->name, (char *)rs232data->recv_buf, MAXLINE);

		fprintf(I, "[%s] payload [%s] size [%d]\n",
			__FUNCTION__,
			rs232data->recv_buf,
			real_todo
			);

		rs232data->client[2].fd = rs232_open_device(rs232data); 
		if( rs232data->client[2].fd == 0 )
			return BREAK;

		if( rs232_fsm_say_ack(rs232data) < 0 )
			return BREAK;
		
		fprintf(I, "[%s] the COM-port succsseful opened =] \n", __FUNCTION__);

		return TEST_RS232; 

	} 

	rs232data->recv_buf[real_todo] = '\0';
	fprintf(I, "ERROR: unknown command, we expect %s, but receive %s \n",
			SET_PORT_CMD,
			rs232data->recv_buf
		);

	rs232_fsm_say_err(rs232data);

	return BREAK; 
}

int rs232_idle(rs232_data_t *rs232data)
{
	int	res;

	need_exit = 1;

	while(need_exit) {
		res = rs232_poll_read(rs232data, GUI_FD, 255);
		if( res > 0 ) {
			/* data in the client socket - need parse it */
			rs232_get_command(rs232data);
		} else if( res == -1 ){
			rs232_connection(rs232data);
		}
	}
	
	return 0;
}


int rs232_make_net(rs232_data_t* rs232data)
{
	struct	sockaddr_in	sin = {};
	socklen_t		len = sizeof(sin);
	struct pollfd		*listen_socket = &rs232data->client[LISTEN_FD];

	listen_socket->fd = socket(AF_INET/* inet */, SOCK_STREAM/*2-way stream*/, 0);
	if( listen_socket->fd < 0) {
		fprintf(I, "[%s] [err] during create socket. errno %s\n", __FUNCTION__, strerror(errno));
		return -1;
	}

	sin.sin_family = AF_INET;
	sin.sin_port = htons(rs232data->port);		// FIXME
	sin.sin_addr.s_addr = htonl(INADDR_ANY);	// listen on every interface

	if( bind(listen_socket->fd, (struct sockaddr *)&sin, len) < 0 ) {
		fprintf(I, "[%s] [err] during bind the socket on port [%d]. errno %s\n",
				__func__,
				rs232data->port,
				strerror(errno)
			);

		close(listen_socket->fd);
		return -1;
	}

	if( listen(listen_socket->fd, 2) ) {
		fprintf(I, "[%s] error during listen() the socket on port [%d]. errno [%s]",
			__func__, rs232data->port, strerror(errno));

		close(listen_socket->fd);
		return -1;
	}

	return 0;
}

int rs232_check_opts(rs232_data_t* rs232data)
{
	if( (rs232data->port < 1) || (rs232data->port > 65535) ) {
		fprintf(I, "[err] port must be between 1 and 65535\n");
		return -1;
	}
	
	return 0;

}

int main(int argc, char **argv)
{
	rs232_data_t		rs232data = {};
	int 			res;
	
	I = stdout;

	while ( (res = getopt(argc,argv,"hp:")) != -1){
		switch (res) {
		case 'h':
			rs232_banner();
			return -1;
		
		case 'p':
			fprintf(I, "Set listen port to [%s]\n", optarg);
			rs232data.port = atoi(optarg);
			break;
		
		default:
			return -1;
        	};
	};

	if( rs232_check_opts(&rs232data) != 0 )
		return -1;

	if( rs232_make_net(&rs232data) != 0 )
		return -1;

	if( rs232_make_signals(&rs232data) != 0 )
		return -1;
	
	/* protocol handler */
	rs232_connection(&rs232data);
	rs232_idle(&rs232data);
	//rs232_fsm(&rs232data);

	/* free memory and close all fd's */
	rs232_destroy(&rs232data);

	return 0;
}
