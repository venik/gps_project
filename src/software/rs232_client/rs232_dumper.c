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
	close(rs232data->client[2].fd);
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

int rs232_poll_read(rs232_data_t *rs232data, uint8_t num, size_t todo)
{
	int nready, res;
	struct pollfd	*pfd = &rs232data->client[num];

	fprintf(I, "[%s]\n", __FUNCTION__);

	pfd->events = POLLIN;

	nready = poll(pfd, 1, TIMEOUT);

	if( nready < 1 ) {
		/* client not ready */
		strcpy((char *)rs232data->recv_buf, "[err] there is no data in the client socket, disconnect...");
		rs232_fsm_say_err(rs232data);

		fprintf(I, "[err] there is no data in the client socket, disconnect...\n");
		return -1;
	}

	if( pfd->revents & POLLIN ) {
		
		res = read(pfd->fd, rs232data->recv_buf, todo);
		fprintf(I, "[%s] need [%d] received [%d] \n", __func__, todo, res);
		
		if( res <= 0 ) {
			/* error occur */
			fprintf(I, "[err] while reading. errno [%s]\n", strerror(errno));
			return -1;
		}
		
		dump_hex(rs232data->recv_buf, res);

		fprintf(I, "[%s] fd = [%d] read = [%d]\n",
			__func__,
			pfd->fd,
			res
			);

		return res;

	}
			
	return -1;
}

int rs232_poll_write(rs232_data_t *rs232data, uint8_t num, size_t todo)
{
	int nready, res;
	struct pollfd	*pfd = &rs232data->client[num];

	fprintf(I, "[%s]\n", __func__);

	pfd->events = POLLOUT;

	nready = poll(pfd, 1, TIMEOUT);

	if( nready < 1 ) {
		fprintf(I, "[err] the GUI not ready, disconnect...\n");
		/* client not ready */
		return -1;
	}

	if( pfd->revents & POLLOUT ) {
		
		res = write(pfd->fd, rs232data->send_buf, todo);
	
		dump_hex(rs232data->send_buf, todo);
		
		if( res <= 0 ) {
			/* error occur */
			fprintf(I, "[err] while writing. errno [%s]\n", strerror(errno));
			return -1;

		} else if( res != todo ) {
			fprintf(I, "[%s] fd = [%d] res = [%d] todo = [%d]",
				__func__,
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

int rs232_fsm_hello(rs232_data_t *rs232data)
{
	size_t	res;
	size_t 	real_todo = 255;
	
	if( (res = rs232_poll_read(rs232data, 1, real_todo)) < 0 ) {
		/* error occur */
		fprintf(I, " close connection or error. errno %s\n", strerror(errno));
		strcpy((char *)rs232data->send_buf, strerror(errno));
		goto out_with_err;
	}

	
	real_todo = strncmp((const char *)rs232data->recv_buf, stage1_in[0], res);

	if( real_todo == 0 ) {
		fprintf(I, "[%s] GUI successfully identified =] \n", __FUNCTION__);
		if( rs232_fsm_say_ack(rs232data) < 0 )
			return BREAK;

		return SET_PORT; 

	} 

	//rs232data->recv_buf[res] = '\0';
	fprintf(I, "[err]: result [%d] unknown command, we expect %s, but receive %s \n", 	\
			res,									\
			stage1_in[0],								\
			rs232data->recv_buf							\
		);
	
	dump_hex((uint8_t *)stage1_in, sizeof(stage1_in[0]));

out_with_err:

	rs232_fsm_say_err(rs232data);
	close(rs232data->client[1].fd);


	return CONNECTION; 
}

int rs232_fsm_test_sram(rs232_data_t *rs232data)
{
	size_t	res;
	size_t 	real_todo = strlen(TEST_SRAM_CMD);
	
	if( rs232_poll_read(rs232data, 1, real_todo) < 0 ) {
		/* error occur */
		return BREAK;
	}
	
	res = strncmp((const char *)rs232data->recv_buf, (const char *)TEST_SRAM_CMD, real_todo);


	if( res == 0 ) {
		fprintf(I, "[%s] request for test onboard SRAM-chip \n", __FUNCTION__);

		/* work with board */
		uint64_t 	*comm_req = (uint64_t *)rs232data->send_buf;
		uint8_t 	*comm_ans = (uint8_t *)rs232data->recv_buf;
		
		*comm_req = RS232_TEST_SRAM;	
		
		if( rs232_poll_write(rs232data, 2, sizeof(uint64_t)) < 0 ) {
			/* error occur */
			fprintf(I, "[%s] PC => Board: sram-chip test failed\n", __FUNCTION__);
			return BREAK;
		}
		
		if( rs232_poll_read(rs232data, 2, sizeof(uint8_t)) < 0 ) {
			/* error occur */
			fprintf(I, "[%s] Board => PC answer\n", __FUNCTION__);
			return BREAK;
		}

		if( ((*comm_req) & 0xFFull) == (*comm_ans) ) {
			fprintf(I, "SRAM work fine =) \n");

			if( rs232_fsm_say_ack(rs232data) < 0 )
				return BREAK;
		
		} else {
			fprintf(I, "problem with the onboard sram =( \n");
			return BREAK;
		}


		return TEST_SRAM; 

	} 

	rs232data->recv_buf[real_todo] = '\0';
	fprintf(I, "ERROR: unknown command, we expect %s, but receive %s \n",
			TEST_RS232_CMD,
			rs232data->recv_buf
		);

	rs232_fsm_say_err(rs232data);

	return BREAK;
		
}
int rs232_fsm_test_rs232(rs232_data_t *rs232data)
{
	size_t	res;
	size_t 	real_todo = strlen(TEST_RS232_CMD);
	
	if( rs232_poll_read(rs232data, 1, real_todo) < 0 ) {
		/* error occur */
		return BREAK;
	}
	
	res = strcmp((const char *)rs232data->recv_buf, (const char *)TEST_RS232_CMD);

	//printf("[%x] [%x]", rs232data->recv_buf[real_todo], rs232data->recv_buf[real_todo + 1]);
	//dump_hex(rs232data->recv_buf, real_todo);
	//dump_hex((uint8_t *)TEST_RS232_CMD, real_todo);

	if( res == 0 ) {
		fprintf(I, "[%s] request for COM-port testing \n", __FUNCTION__);

		/* work with board */
		uint64_t 	*comm_req = (uint64_t *)rs232data->send_buf;
		uint8_t 	*comm_ans = (uint8_t *)rs232data->recv_buf;
		
		*comm_req = RS232_TEST_RS232;	
		
		if( rs232_poll_write(rs232data, 2, sizeof(uint64_t)) < 0 ) {
			/* error occur */
			fprintf(I, "[%s] PC => Board: rs232 test\n", __FUNCTION__);
			return BREAK;
		}
		
		if( rs232_poll_read(rs232data, 2, sizeof(uint8_t)) < 0 ) {
			/* error occur */
			fprintf(I, "[%s] Board => PC answer\n", __FUNCTION__);
			return BREAK;
		}

		if( ((*comm_req) & 0xFFull) == (*comm_ans) ) {
			fprintf(I, "RS232 work fine =) \n");

			if( rs232_fsm_say_ack(rs232data) < 0 )
				return BREAK;
		
		} else {
			fprintf(I, "problem with the RS232 connection =( \n");
			return BREAK;
		}


		return TEST_SRAM; 

	} 

	rs232data->recv_buf[real_todo] = '\0';
	fprintf(I, "ERROR: unknown command, we expect %s, but receive %s \n",
			TEST_RS232_CMD,
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
			//exit(-1);
			break;

		case SET_PORT:
			fprintf(I, "[%s] SET_PORT\n", __FUNCTION__);
			state = rs232_fsm_set_port(rs232data);
			return 0;
			//break;

		};

	}; // while(need_exit)

	return 0;
}

int rs232_fsm(rs232_data_t *rs232data)
{
	uint8_t		state = CONNECTION;
	need_exit = 1;
	
	while(need_exit) {
		switch(state) {

#if 0
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

#endif
		case TEST_RS232:
			fprintf(I, "[%s] TEST_RS232\n", __FUNCTION__);
			state = rs232_fsm_test_rs232(rs232data);
			break;
			
		case TEST_SRAM:
			fprintf(I, "[%s] TEST_SRAM\n", __func__);
			state = rs232_fsm_test_sram(rs232data);
			break;

		case BREAK:
			/* close the clinet socket */
			fprintf(I, "[%s] BREAK\n", __FUNCTION__);
			close(rs232data->client[1].fd);
			return -1;

		default:
			fprintf(I, "[%s] unknown state [%d]n", __func__, state);
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

        if( ( (sigaction(SIGINT,  &int_sig, NULL)) == -1 ) ||
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
	rs232_idle(&rs232data);
	//rs232_fsm(&rs232data);

	/* free memory and close all fd's */
	rs232_destroy(&rs232data);

	return 0;
}
