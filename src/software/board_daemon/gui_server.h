#ifndef __GUI_SERVER_
#define __GUI_SERVER_

int gui_connection(bd_data_t *bd_data)
{
	TRACE(0, "[%s]\n", __func__);
	bd_data->client[GUI_FD].fd = accept(bd_data->client[LISTEN_FD].fd, NULL, NULL);

	return 0;
}

/* get the command LEN(3):COMM:VAL */
int gui_read_command(bd_data_t *bd_data, uint8_t num)
{
	int 	res;

	/* get size of a incomming command */
	res = bd_poll_read(bd_data, num, 4);
	if( res < 0 ) 
		return -1;

	/* get the comm */
	bd_data->recv_buf[3] = '\0';
	int	todo = atoi((const char *)bd_data->recv_buf);

	if(todo < 0) {
		/* wrong size - reconnection */
	}

	res = bd_poll_read(bd_data, num, todo);
	if( res < 0 ) 
		return -1;

	return 0;
}

int gui_fsm_setport(bd_data_t *bd_data)
{
	/* RS232_PORT + : = point to the dev-name */
	char 	*p_port = (char *)(bd_data->recv_buf + strlen(gui_commands[0]));

	int 	res;
	size_t 	real_todo;

	TRACE(0, "[%s] port[%s]\n", __func__, p_port);

	strncpy(bd_data->name, p_port, MAXLINE);

	res = rs232_open_device(bd_data);
	if( res < 0 ) {
		/* error during opening the rs232-port */
		real_todo = strlen((char *)bd_data->send_buf);
		bd_poll_write(bd_data, GUI_FD, real_todo);
		return -1;
	}

	bd_data->client[BOARD_FD].fd = res;

	/* make the ACK answer */
	sprintf((char *)bd_data->send_buf, "ACK");
	TRACE(I, "%s\n", (char *)bd_data->send_buf);	

	real_todo = strlen((char *)bd_data->send_buf);
	res = bd_poll_write(bd_data, GUI_FD, real_todo);
	if( res < 0 ) {
		/* cannot send ACK, close the rs232 */
		TRACE(I, "[%s] [err] cannot send ACK to the GUI, close GUI socket \n", __func__);
		close(bd_data->client[BOARD_FD].fd);
		bd_data->client[BOARD_FD].fd = -1;

		return -1;
	}
	
	TRACE(I, "[%s] the COM-port succsseful opened =] \n", __func__);

	return 0; 
}

/* execute command */
int gui_fsm(bd_data_t *bd_data, int i)
{
	TRACE(I, "[%s] command [%s]\n", __func__, gui_commands[i]);

	switch(i) {
	case 0:
		gui_fsm_setport(bd_data);
		break;
	default: 
		TRACE(I, "[%s] command [%s] not implement yet\n", __func__, gui_commands[i]);
		return -1;
	}
	return 0;
}

int gui_make_net(bd_data_t* bd_data)
{
	struct	sockaddr_in	sin = {};
	socklen_t		len = sizeof(sin);
	struct pollfd		*listen_socket = &bd_data->client[LISTEN_FD];

	listen_socket->fd = socket(AF_INET/* inet */, SOCK_STREAM/*2-way stream*/, 0);
	if( listen_socket->fd < 0) {
		fprintf(I, "[%s] [err] during create socket. errno %s\n", __func__, strerror(errno));
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

	return 0;
}

/* return the index of command or -1 in the error case */
int gui_get_command(bd_data_t *bd_data) {

	size_t	res;
	size_t 	real_todo;
	int	i = 0;
	
	TRACE(0, "[%s]\n", __func__);

	do {
		res = strlen(gui_commands[i]);
		real_todo = strncmp((const char *)bd_data->recv_buf, gui_commands[i], res);

		if( (real_todo == 0) && (res != 0) ) {
			fprintf(I, "Catch res = [%d], command [%s]\n", real_todo, gui_commands[i]);	
			goto parse_finish;	
		}

#if 1	
		/* debug part */
		dump_hex((uint8_t *)gui_commands[i], res);
		fprintf(I, "[%s] line:[%d] src:[%d] match:[%d]\n", __func__, __LINE__, res, real_todo);	
#endif 

		i++;
	} while(res != 0);

	snprintf((char *)bd_data->send_buf, MAXLINE, "[%s] [err] unknown command\n", __func__);
	fprintf(I, "%s\n", (char *)bd_data->recv_buf);	

	return -1;

parse_finish:

	return i;
}

int gui_idle(bd_data_t *bd_data)
{
	int	res;

	need_exit = 1;

	while(need_exit) {
		res = bd_poll_read(bd_data, GUI_FD, 255);
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
			gui_connection(bd_data);
		}
	}
	
	return 0;
};


#endif /* __GUI_SERVER_ */
