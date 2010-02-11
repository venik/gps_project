#ifndef __GUI_SERVER_
#define __GUI_SERVER_

#include <poll.h>

/*************************************************************************************
 *                        	function definiton
 *************************************************************************************/
int gui_make_net(bd_data_t* bd_data);
int gui_poll_read(bd_data_t *bd_data, size_t todo);
int gui_poll_write(bd_data_t *bd_data, int todo);

/*************************************************************************************
 *                         	some helpers 	
 *************************************************************************************/
enum gui_server_state {
	CONN_WAIT	= 0,
	COMMAND_WAIT	= 1,
};

/*************************************************************************************
 *                         	Rock & Roll 	
 *************************************************************************************/
/* get the command LEN(3):COMM:VAL */
int gui_read_command(bd_data_t *bd_data, uint8_t num)
{
	int 	res;

	/* get size of a incomming command */
	//res = bd_poll_read(bd_data, num, 4);
	if( res < 0 ) 
		return -1;

	/* get the comm */
	bd_data->recv_buf[3] = '\0';
	int	todo = atoi((const char *)bd_data->recv_buf);

	if(todo < 0) {
		/* FIXME wrong size - reconnection */
		return -1;
	}

	//res = bd_poll_read(bd_data, num, todo);
	if( res < 0 ) 
		return -1;

	return 0;
}

/* execute command */
int gui_fsm(bd_data_t *bd_data, int i)
{
	TRACE(I, "[%s] command [%s]\n", __func__, gui_commands[i]);

	switch(i) {
	case 0:
		//gui_fsm_setport(bd_data);
		break;
	default: 
		TRACE(I, "[%s] command [%s] not implement yet\n", __func__, gui_commands[i]);
		return -1;
	}
	return 0;
}

/* return the index of command or -1 in the error case */
int gui_get_command(bd_data_t *bd_data) {

	int 	real_todo, comm_len;
	int	done;
	
	TRACE(0, "[%s]\n", __func__);

	/* small FSM => LEN state and COMMAND state */

	TRACE(0, "[%s] LEN \n", __func__);

	/* LEN */
	real_todo = 3;
	do {
		done = gui_poll_read(bd_data, real_todo);
		if( done == -1 ) {
			/* error occur */
			return -1;
		}
		real_todo -= done ;
	} while( real_todo > 0 );

	/* check the LEN value */
	bd_data->recv_buf[3] = '\0';
	comm_len = real_todo = atoi((char *)bd_data->recv_buf) ;
	if( real_todo <= 0 ) {
		/* cannot parse the len on the command - close the socket */
		close(bd_data->client[GUI_FD].fd);
		return -1;
	}

	TRACE(0, "[%s] COMM \n", __func__);
	/* COMMAND */
	do {
		done = gui_poll_read(bd_data, real_todo);
		if( done == -1 ) {
			/* error occur */
			return -1;
		}
		real_todo -= done ;
	} while( real_todo > 0 );

	/* parse the COMMAND */
	bd_data->recv_buf[comm_len] = '\0' ;


	/* parser the COMMAND */

#if 0
	do {
		res = strlen(gui_commands[i]);
		real_todo = strncmp((const char *)bd_data->recv_buf, gui_commands[i], res);

		if( (real_todo == 0) && (res != 0) ) {
			TRACE(0, "Catch res = [%d], command [%s]\n", real_todo, gui_commands[i]);	
			goto parse_finish;	
		}

		/* debug part */
		dump_hex((uint8_t *)gui_commands[i], res);
		TRACE(0, "[%s] line:[%d] src:[%d] match:[%d]\n", __func__, __LINE__, res, real_todo);	

		i++;
	} while(res != 0);

	snprintf((char *)bd_data->send_buf, MAXLINE, "[%s] [err] unknown command\n", __func__);
	TRACE(0, "%s\n", (char *)bd_data->recv_buf);	

	return -1;

parse_finish:

	return i;
#endif 

	return 0;
}

/* loop - wait for connection */
int gui_conn_state(bd_data_t *bd_data)
{
	int nready;

	struct	pollfd *pfd_gui = &bd_data->client[GUI_FD];
	struct	pollfd *pfd_listen = &bd_data->client[LISTEN_FD];

	pfd_listen->events = POLLIN;

	nready = poll(pfd_listen, 1, TIMEOUT);

	if( nready < 1 ) 
		return 0;

	if( pfd_listen->revents & POLLIN ) {
		TRACE(0, "[%s] Incomming connection\n", __func__);

		pfd_gui->fd = accept(pfd_listen->fd, NULL, NULL);

		return 1;

	}

	return 0;
}

void *gui_process(void *priv)
{
	int	res;
	uint8_t	state = CONN_WAIT;
	bd_data_t *bd_data = (bd_data_t *)priv;

	if( gui_make_net(bd_data) != 0 )
		return NULL;

	while(bd_data->need_exit) {

		/* simple FSM - wait for connection or wait for command */
		if( state == CONN_WAIT) {
			res = gui_conn_state(bd_data);
			/* switch state */
			if(res) {
				TRACE(0, "[%s] Switch to wait command\n", __func__);
				state = COMMAND_WAIT ;
			}
		} else {
			res = gui_get_command(bd_data);
			if(res) {
				TRACE(0, "[%s] Switch to wait connection\n", __func__);
				state = CONN_WAIT ;
			}

		};
	}

#if 0
	while(bd_data->need_exit) {
		//res = bd_poll_read(bd_data, GUI_FD, 255);
		//res = gui_read_command(bd_data, GUI_FD);
		if( res > 0 ) {
			/* data in the client socket - need parse it */
			res = gui_get_command(bd_data);

			if( res < 0 ) {
				res = strlen((char *)bd_data->send_buf);
				bd_poll_write(bd_data, GUI_FD, res);
				continue;
			}
			
			gui_fsm(bd_data, res);

		} else if( res < 0 ){
			/* lost connection, need reconnect */
		}
	}
#endif

	TRACE(0, "[%s] near exit\n", __func__);

	pthread_exit((void *) 0);
};

int gui_make_net(bd_data_t* bd_data)
{
	struct	sockaddr_in	sin = {};
	socklen_t		len = sizeof(sin);
	struct pollfd		*listen_socket = &bd_data->client[LISTEN_FD];

	listen_socket->fd = socket(AF_INET/* inet */, SOCK_STREAM/*2-way stream*/, 0);
	if( listen_socket->fd < 0) {
		TRACE(0, "[%s] [err] during create socket. errno %s\n", __func__, strerror(errno));
		return -1;
	}

	sin.sin_family = AF_INET;
	sin.sin_port = htons(bd_data->port);
	sin.sin_addr.s_addr = htonl(INADDR_ANY);	// listen on every interface

	if( bind(listen_socket->fd, (struct sockaddr *)&sin, len) < 0 ) {
		TRACE(0, "[%s] [err] during bind the socket on port [%d]. errno %s\n",
				__func__, bd_data->port, strerror(errno) );

		close(listen_socket->fd);
		return -1;
	}

	if( listen(listen_socket->fd, 2) ) {
		TRACE(0, "[%s] error during listen() the socket on port [%d]. errno [%s]",
			__func__, bd_data->port, strerror(errno));

		close(listen_socket->fd);
		return -1;
	}
	
	TRACE(0, "[%s] successfully bind the tcp port [%d]\n", __func__, bd_data->port);

	return 0;
}

/*************************************************************************************
 * poll() for read wrapper
 * Return:	0  - not ready
 * 		-1 - closed clien the socket
 * 		>0 - count of bytes from the socket
 *************************************************************************************/
int gui_poll_read(bd_data_t *bd_data, size_t todo)
{
	int nready, res;
	struct pollfd	*pfd = &bd_data->client[GUI_FD];

	pfd->events = POLLIN;

	nready = poll(pfd, 1, TIMEOUT);

	if( (nready > 0) && (pfd->revents & POLLIN) ) {

		res = read(pfd->fd, bd_data->recv_buf, todo);
		TRACE(0, "[%s] need [%d] received [%d] \n", __func__, todo, res);
	
		if( res < 0 ) {
			/* error occur */
			TRACE(0, "[err] while reading. errno [%s]\n", strerror(errno));
			close(pfd->fd);
			return -1;
		} else if( res == 0 ) {
			TRACE(0, "closed socket\n");
			close(pfd->fd);
			return -1;
		}
	
		dump_hex(bd_data->recv_buf, res);

		TRACE(I, "[%s] fd = [%d] read = [%d]\n", __func__, pfd->fd, res );
		return res;
	}

	TRACE(0, "[%s] => nothing read <= \n", __func__);
			
	return 0;
}

/*************************************************************************************
 * poll() for write wrapper
 * Return:	0  - not ready
 * 		-1 - closed clien the socket
 * 		>0 - count of bytes written to the socket
 *************************************************************************************/
int gui_poll_write(bd_data_t *bd_data, int todo)
{
	int nready, res;
	struct pollfd	*pfd = &bd_data->client[GUI_FD];

	TRACE(0, "[%s]\n", __func__);

	pfd->events = POLLOUT;

	nready = poll(pfd, 1, TIMEOUT);

	if( (nready > 0) && (pfd->revents & POLLOUT) ) {
	
		dump_hex(bd_data->send_buf, todo);
	
		res = write(pfd->fd, bd_data->send_buf, todo);

		if( res < 0 ) {
			/* error occur */
			TRACE(I, "[%s] [err] while writing. errno [%s]\n", __func__, strerror(errno));
			close(pfd->fd);
			return -1;
		} else if( res == 0 ) {
			TRACE(I, "[%s] [err] GUI closed the socket\n", __func__);
			close(pfd->fd);
			return -1;
		}

		TRACE(0, "[%s] fd = [%d] res = [%d] todo = [%d]",
			__func__, pfd->fd, res, todo );
		
		return res;
	}
	
	TRACE(0, "[%s] => nothing write <= \n", __func__);
			
	return 0;
}

#endif /* __GUI_SERVER_ */
