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
#include <signal.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <sys/socket.h>
#include <netinet/in.h>

#include <errno.h>

#include "rs232_dumper.h"

//#include "rs232_main_mode.h"
//#include "rs232_test_mode.h"

FILE 		*I;
uint8_t		need_exit;

/* signal handlers */
static void rs232_sig_INT(int sig)
{
        need_exit = 0;
        signal(15, SIG_IGN);
}

/*
 * Description: print banner 
 * Return:  	nothing	
 */
void rs232_banner()
{
	printf("Hello this is rs232 dumper for gps-board project by DSP-lab. This is real cool banner\n");
	printf("Usage: rs232_client [options]\n");
	printf("Options:\n");
	printf("  -r:	give the rs232 port name, something like this /dev/ttyS0\n");
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
		fprintf(I, "[%s] %s\n", __FUNCTION__, msg);
		rs232_fsm_say_err_errno(rs232data, msg);

		return 0;
	}

	errno = 0;
	if( tcgetattr(fd, &options) == -1 ) {
		snprintf(msg, MAXLINE, "[ERR] cannot get rs232 options");
		fprintf(I, "[%s] %s\n", __FUNCTION__, msg);
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
		fprintf(I, "[%s] %s\n", __FUNCTION__, msg);
		rs232_fsm_say_err_errno(rs232data, msg);
		return 0;
	}

	return fd;
}

void rs232_destroy(rs232_data_t	*rs232data)
{
	close(rs232data->client[0].fd);
	close(rs232data->fd);
}

#if 0
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
#endif

int rs232_poll_read(rs232_data_t *rs232data, size_t todo)
{
	int nready, res;
	struct pollfd	*pfd = &rs232data->client[1];

	pfd->events = POLLIN;

	nready = poll(pfd, 1, TIMEOUT);

	if( nready < 1 ) {
		fprintf(I, "[err] there is no data in the client socket, disconnect...\n");
		/* client not ready */
		return -1;
	}

	if( rs232data->client[1].revents & POLLIN ) {
		
		res = read(pfd->fd, rs232data->recv_buf, todo);
		if( res <= 0 ) {
			/* error occur */
			fprintf(I, "[err] while reading. errno [%s]\n", strerror(errno));
			return -1;

		} else if( res != todo ) {
			fprintf(I, "[%s] fd = [%d] res = [%d] todo = [%d]",
				__FUNCTION__,
				pfd->fd,
				res,
				todo
				);

			return -1;
		}

		return 0;

	}
			
	return -1;
}

int rs232_poll_write(rs232_data_t *rs232data, size_t todo)
{
	int nready, res;
	struct pollfd	*pfd = &rs232data->client[1];

	pfd->events = POLLOUT;

	nready = poll(pfd, 1, TIMEOUT);

	if( nready < 1 ) {
		fprintf(I, "[err] the GUI not ready, disconnect...\n");
		/* client not ready */
		return -1;
	}

	if( rs232data->client[1].revents & POLLOUT ) {
		
		res = write(pfd->fd, rs232data->send_buf, todo);
		if( res <= 0 ) {
			/* error occur */
			fprintf(I, "[err] while writing. errno [%s]\n", strerror(errno));
			return -1;

		} else if( res != todo ) {
			fprintf(I, "[%s] fd = [%d] res = [%d] todo = [%d]",
				__FUNCTION__,
				pfd->fd,
				res,
				todo
				);

			return -1;
		}

		fprintf(I, "[%s] wrote [%d] bytes\n", __FUNCTION__, res);

		return 0;

	}
			
	return -1;
}

int rs232_fsm_connection(rs232_data_t *rs232data)
{
	rs232data->client[1].fd = accept(rs232data->client[0].fd, NULL, NULL);

	return WAIT_FOR_HELLO;
}

int rs232_fsm_say_ack(rs232_data_t *rs232data) 
{
	size_t 	real_todo = strlen(ACK);

	strcpy((char *)rs232data->send_buf, ACK);
	
	if( rs232_poll_write(rs232data, real_todo) ) {
		/* error occur */
		return -1;
	}
	
	return 0;
}

static void rs232_fsm_say_err(rs232_data_t *rs232data) 
{
	snprintf((char *)rs232data->send_buf, MAXLINE, "ERR: unexpecting request [%s]", rs232data->recv_buf);
	size_t 	real_todo = strlen((char *)rs232data->send_buf);

	rs232_poll_write(rs232data, real_todo);
}

static void rs232_fsm_say_err_errno(rs232_data_t *rs232data, char *str) 
{
	snprintf((char *)rs232data->send_buf, MAXLINE, "ERR: %s. errno: %s", str, strerror(errno));
	size_t 	real_todo = strlen((char *)rs232data->send_buf);

	rs232_poll_write(rs232data, real_todo);
}

int rs232_fsm_hello(rs232_data_t *rs232data)
{
	size_t	res;
	size_t 	real_todo = strlen(CONNECTION_CMD);
	
	if( rs232_poll_read(rs232data, real_todo) < 0 ) {
		/* error occur */
		return BREAK;
	}
	
	res = strcmp((const char *)rs232data->recv_buf, (const char *)CONNECTION_CMD);

	if( res == 0 ) {
		fprintf(I, "[%s] GUI successfully identified =] \n", __FUNCTION__);
		if( rs232_fsm_say_ack(rs232data) < 0 )
			return BREAK;

		return SET_PORT; 

	} 

	rs232data->recv_buf[real_todo] = '\0';
	fprintf(I, "ERROR: unknown command, we expect %s, but receive %s \n",
			CONNECTION_CMD,
			rs232data->recv_buf
		);

	rs232_fsm_say_err(rs232data);

	return BREAK;
		
}

int rs232_fsm_set_port(rs232_data_t *rs232data)
{
	size_t	res;
	size_t 	real_todo = strlen(SET_PORT_CMD);

	/* comm + "len=" */
	if( rs232_poll_read(rs232data, real_todo + 4) < 0 ) {
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


		/* name + 0x0d + 0x0a */
		if( rs232_poll_read(rs232data, real_todo + 2) < 0 ) {
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

		rs232data->fd = rs232_open_device(rs232data); 
		if( rs232data->fd == 0 )
			return BREAK;

		if( rs232_fsm_say_ack(rs232data) < 0 )
			return BREAK;
		
		fprintf(I, "[%s] the COM-port succsseful opened =] \n", __FUNCTION__);

		return BREAK; 

	} 

	rs232data->recv_buf[real_todo] = '\0';
	fprintf(I, "ERROR: unknown command, we expect %s, but receive %s \n",
			SET_PORT_CMD,
			rs232data->recv_buf
		);

	rs232_fsm_say_err(rs232data);

	return BREAK; 
}

int rs232_fsm(rs232_data_t *rs232data)
{
	uint8_t		state = CONNECTION;
	need_exit = 1;
	

	while(need_exit) {
		switch(state) {
		case CONNECTION:
			fprintf(I, "[%s] CONNECTION\n", __FUNCTION__);
			state = rs232_fsm_connection(rs232data);
			break;

		case WAIT_FOR_HELLO:
			fprintf(I, "[%s] WAIT_FOR_HELLO\n", __FUNCTION__);
			state = rs232_fsm_hello(rs232data);
			break;

		case SET_PORT:
			fprintf(I, "[%s] SET_PORT\n", __FUNCTION__);
			state = rs232_fsm_set_port(rs232data);
			break;

		case BREAK:
			/* close clinet socket */
			fprintf(I, "[%s] BREAK\n", __FUNCTION__);
			close(rs232data->client[1].fd);
			return -1;

		default:
			fprintf(I, "[%s] unknown state\n", __FUNCTION__);
			return -1;

		} // switch(state)
	} // while(1)

	return 0;
}

int rs232_make_signals(rs232_data_t* rs232data)
{
	/* registering signals */
	struct sigaction int_sig;
        
	int_sig.sa_handler = &rs232_sig_INT;
        sigemptyset(&int_sig.sa_mask);
        int_sig.sa_flags = SA_NOMASK;

        if( ( (sigaction(SIGINT, &int_sig, NULL)) == -1  ) ||
            ( (sigaction(SIGTERM, &int_sig, NULL)) == -1 )
          ){
                fprintf(I, "[err] cannot set handler. error: %s", strerror(errno));
                return -1;
        }

	return 0;
}

int rs232_make_net(rs232_data_t* rs232data)
{
	struct	sockaddr_in	sin = {};
	socklen_t		len = sizeof(sin);

	rs232data->client[0].fd = socket(AF_INET/* inet */, SOCK_STREAM/*2-way stream*/, 0);
	if( rs232data->client[0].fd < 0) {
		fprintf(I, "[%s] [err] during create socket. errno %s\n", __FUNCTION__, strerror(errno));
		return -1;
	}

	sin.sin_family = AF_INET;
	sin.sin_port = htons(rs232data->port);		// FIXME
	sin.sin_addr.s_addr = htonl(INADDR_ANY);	// listen on every interface

	if( bind(rs232data->client[0].fd, (struct sockaddr *)&sin, len) < 0 ) {
		fprintf(I, "[%s] [err] during bind the socket on port [%d]. errno %s\n",
				__FUNCTION__,
				rs232data->port,
				strerror(errno)
			);

		close(rs232data->client[0].fd);
		return -1;
	}

	if( listen(rs232data->client[0].fd, 2) ) {
		fprintf(I, "[%s] error during listen() the socket on port [%d]", __FUNCTION__, rs232data->port);
		close(rs232data->client[0].fd);
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
	
	if( strlen(rs232data->name) == 0 ) {
		fprintf(I, "[err] you must set COM-port name with -r parameter\n");
		return -1;
	}

	return 0;

}

int main(int argc, char **argv)
{
	rs232_data_t		rs232data = {};
	int 			res;
	
	I = stdout;

	while ( (res = getopt(argc,argv,"hp:r:")) != -1){
		switch (res) {
		case 'h':
			rs232_banner();
			return -1;
		case 'r':
			fprintf(I, "RS232 port set to [%s]\n", optarg);
			snprintf(rs232data.name, MAXLINE, "%s", optarg);
			break;
		
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
	

	rs232_fsm(&rs232data);


#if 0
	/* open COM - port */
	errno = 0;

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
