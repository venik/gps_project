#ifndef __GUI_SERVER_
#define __GUI_SERVER_

int rs232_connection(rs232_data_t *rs232data)
{
	fprintf(I, "[%s]\n", __func__);
	rs232data->client[GUI_FD].fd = accept(rs232data->client[LISTEN_FD].fd, NULL, NULL);

	return 0;
}

int rs232_fsm_setport(rs232_data_t *rs232data)
{
	/* RS232_PORT + : = point to the dev-name */
	char 	*p_port = (char *)(rs232data->recv_buf + strlen(rs232_commands[0]));

	int 	res;
	size_t 	real_todo;

	fprintf(I, "[%s] port[%s]\n", __func__, p_port);

	strncpy(rs232data->name, p_port, MAXLINE);

	res = rs232_open_device(rs232data);
	if( res < 0 ) {
		/* error during opening the rs232-port */
		real_todo = strlen((char *)rs232data->send_buf);
		rs232_poll_write(rs232data, GUI_FD, real_todo);
		return -1;
	}

	rs232data->client[BOARD_FD].fd = res;

	/* make the ACK answer */
	sprintf((char *)rs232data->send_buf, "ACK\n");
	fprintf(I, "%s\n", (char *)rs232data->recv_buf);	
	real_todo = strlen((char *)rs232data->send_buf);
	res = rs232_poll_write(rs232data, GUI_FD, real_todo);
	if( res < 0 ) {
		/* cannot send ACK, close the rs232 */
		fprintf(I, "[%s] [err] cannot send ACK to the GUI, close rs232 \n", __func__);
		close(rs232data->client[BOARD_FD].fd);
		rs232data->client[BOARD_FD].fd = -1;
		return -1;
	}
	
	fprintf(I, "[%s] the COM-port succsseful opened =] \n", __func__);

	return 0; 
}

/* execute command */
int rs232_fsm(rs232_data_t *rs232data, int i)
{
	fprintf(I, "[%s] command [%s]\n", __func__, rs232_commands[i]);

	switch(i) {
	case 0:
		rs232_fsm_setport(rs232data);
		break;
	default: 
		fprintf(I, "[%s] command [%s] not implement yet\n", __func__, rs232_commands[i]);
		return -1;
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

int rs232_idle(rs232_data_t *rs232data)
{
	int	res;

	need_exit = 1;

	while(need_exit) {
		//res = rs232_poll_read(rs232data, GUI_FD, 255);
		res = rs232_read_command(rs232data, GUI_FD);
		if( res > 0 ) {
			/* data in the client socket - need parse it */
			res = rs232_get_command(rs232data);

			if( res < 0 ) {
				res = strlen((char *)rs232data->send_buf);
				rs232_poll_write(rs232data, GUI_FD, res);
				continue;
			}
			
			rs232_fsm(rs232data, res);

		} else if( res < 0 ){
			/* lost connection, need reconnect */
			rs232_connection(rs232data);
		}
	}
	
	return 0;
};

/* return the index of command or -1 in the error case */
int rs232_get_command(rs232_data_t *rs232data) {

	size_t	res;
	size_t 	real_todo;
	int	i = 0;
	
	fprintf(I, "[%s]\n", __func__);

	do {
		res = strlen(rs232_commands[i]);
		real_todo = strncmp((const char *)rs232data->recv_buf, rs232_commands[i], res);

		if( (real_todo == 0) && (res != 0) ) {
			fprintf(I, "Catch res = [%d], command [%s]\n", real_todo, rs232_commands[i]);	
			goto parse_finish;	
		}

#if 1	
		/* debug part */
		dump_hex((uint8_t *)rs232_commands[i], res);
		fprintf(I, "[%s] line:[%d] src:[%d] match:[%d]\n", __func__, __LINE__, res, real_todo);	
#endif 

		i++;
	} while(res != 0);

	snprintf((char *)rs232data->send_buf, MAXLINE, "[%s] [err] unknown command\n", __func__);
	fprintf(I, "%s\n", (char *)rs232data->recv_buf);	

	return -1;

parse_finish:

	return i;
}

#endif /* __GUI_SERVER_ */
