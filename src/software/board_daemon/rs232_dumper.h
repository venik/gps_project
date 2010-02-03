#ifndef __RS232_DUMPER_
#define __RS232_DUMPER_

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

void rs232_close_device(bd_data_t *bd_data)
{
	close(bd_data->client[BOARD_FD].fd);
	bd_data->client[BOARD_FD].fd = -1;
}

int rs232_send_comm(bd_data_t *bd_data, uint64_t reg)
{
	uint8_t		buff = 0;
	int 		res;

	res = write(bd_data->client[BOARD_FD].fd, &reg, sizeof(uint64_t));
	TRACE(0, "[%s] write 0x%016llx, res [%d]\n", __func__, reg, res);

	res = read(bd_data->client[BOARD_FD].fd, &buff, 1);
	printf("=replay= [0x%02x] \n", buff);

	if( res < 0 ) {
		if( errno != EAGAIN ) {
			printf("[ERR] error occur while in data sending. errno %s\n", strerror(errno));
			return -1;
		}

		printf("[WARN] EAGAIN occur while sending, need to do something =] \n");
	}

	if( buff != (uint8_t)(reg & 0xFFull)) {
		/* wrong answer */
		/* this function work not correct for reading from the memory */
		TRACE(0, "[%s] Error. Wrong answer. command [0x%02x] answer [0x%02x]\n",
			__func__, (uint8_t)(reg & 0xFFull), buff);

		return -1;
	}

	return buff;
}


int rs232_open_dump_file(bd_data_t *bd_data)
{
	int		iov_length = 13;
	int		i;
	struct 		iovec iov[iov_length];
	struct pollfd	*pfd = &bd_data->client[DUMP_FD];

	pfd->fd = open("/tmp/flush", O_RDWR|O_CREAT|O_TRUNC, 0666);

	if( pfd->fd < 0 ) {
		TRACE(0, "Error. during open the flush file. errno %s\n", strerror(errno));
		return -1;;
	}

	/* get and write current time */
	time_t	cur_time;
	char	p_time[40] = "# ";
	char	blank_str[] = "#\n";

	time(&cur_time);
	ctime_r(&cur_time, p_time + 2);

	iov[0].iov_base = p_time;
	iov[0].iov_len = strlen(p_time);
	iov[1].iov_base = blank_str;
	iov[1].iov_len = strlen(blank_str);

	for( i = 0; i < 10; i++ ) {
		iov[i + 2].iov_base = bd_data->gps_regs[i].str;
		iov[i + 2].iov_len = strlen(bd_data->gps_regs[i].str);
	}

	iov[12].iov_base = blank_str;
	iov[12].iov_len = strlen(blank_str);

	i = writev(pfd->fd, iov, iov_length);

	if( i < 0) {
		TRACE(0, "[%s] err. errno [%s]\n", __func__, strerror(errno));
		return -1;
	}

	return 0;
}

int rs232_dump_mem(bd_data_t *bd_data)
{
	TRACE(0, "[%s] Start dumping \n", __func__);

	uint8_t		buff[1<<18] = {};
	uint64_t	addr;
	uint32_t	max_addr = (1<<18);
	
	uint64_t	comm_64;
	int 		res;
	
	//char		str[10] = {};
	char		header_string[] = "# Mode: 2bit, sign/magnitude\n# format [q2 i2 q1 i1]\n# i\tq\n";
	char		str_i_q[255] = {};
	
	struct pollfd	*pfd = &bd_data->client[BOARD_FD];
	struct pollfd	*dfd = &bd_data->client[DUMP_FD];

	rs232_open_dump_file(bd_data);
	write(dfd->fd, header_string, strlen(header_string));

	/* flush it */
	comm_64 = RS232_DUMP_DATA ;
	res = write(pfd->fd, &comm_64, sizeof(uint64_t));
	
	/* because the first data is buggy */
	for(addr = 1; addr < max_addr; addr++ ) {

		res = read(pfd->fd, buff+addr, 1);

		//hex2str(str, buff[addr]);
		//TRACE(0, "=replay= [0x%02x]\t b[%s] addr [%06lld]\n", buff[addr], str, addr);

		sprintf(str_i_q, "%d\t%d\n%d\t%d\n", 
			gps_value[GET_I1(buff[addr])],
			gps_value[GET_Q1(buff[addr])],
			gps_value[GET_I2(buff[addr])],
			gps_value[GET_Q2(buff[addr])]
		);

		write(dfd->fd, str_i_q, strlen(str_i_q));
	}

	TRACE(0, "[%s] Dumped successfully\n", __func__);

	close(dfd->fd);

	return 0;
}

int rs232_program_max(bd_data_t *bd_data)
{
	int 		res;
	uint8_t		i;
	uint64_t	comm_64;


	for( i = 0; i < 11; i++ ) {
		comm_64 = RS232_SET_REG;		

		comm_64 |= (bd_data->gps_regs[i].reg<<12);		// data
		comm_64 |= (i<<8);					// address
		
		res = rs232_send_comm(bd_data, comm_64);
		if( res < 0 ) {
			/* need restart the board - strange response */
			rs232_close_device(bd_data);
			return -1;
		}
	}
	
	return 0;
}

int rs232_work(bd_data_t *bd_data)
{
	uint64_t	comm_64;
	int		res;

	/* ping the Board */
	comm_64 = RS232_PING ;
	res = rs232_send_comm(bd_data, comm_64);
	if( res < 0 ) {
		/* error occur */
		rs232_close_device(bd_data);
		return -1;
	}
	
	/* clean the SRAM */
	comm_64 = RS232_ZERO_MEM ;
	res = rs232_send_comm(bd_data, comm_64);
	if( res < 0 ) {
		/* error occur */
		rs232_close_device(bd_data);
		return -1;
	}
	
	/* get the gps data */
	comm_64 = RS232_START_GPS ;
	res = rs232_send_comm(bd_data, comm_64);
	if( res < 0 ) {
		/* error occur */
		rs232_close_device(bd_data);
		return -1;
	}

	usleep(SECOND);

	/* FIXME - command from gui for reprogramming MAX2769 */
	if(0) {
		res = rs232_program_max(bd_data);
		if( res == -1 )
			return -1;
			
	}

	usleep(3 * SECOND);

	/* get the flush */
	/* add the mode checking */
	rs232_dump_mem(bd_data) ;

	return 0;
}

void *rs232_process(void *priv)
{
	int	res;

	bd_data_t *bd_data = (bd_data_t *)priv;
	
	res = rs232_open_device(bd_data);
	if( res == -1 )
		pthread_exit((void *) -1);

	res = rs232_program_max(bd_data);
	if( res == -1 )
		pthread_exit((void *) -1);

	while(bd_data->need_exit) {
		TRACE(0, "[%s] Process...\n", __func__);

		if( bd_data->client[BOARD_FD].fd < 0 ) {
			TRACE(0, "[%s] Warning. Board not connected!!!\n", __func__);
			pthread_exit((void *) -1);
		} else {
			/* FIXME - check the task from gui */
			
			res = rs232_work(bd_data);
			/* check for errors */
			if( res < 0 )
				break;
		}

		usleep(15 * SECOND);
	}

	TRACE(0, "[%s] near exit\n", __func__);

	pthread_exit((void *) 0);
}

#endif /* __RS232_DUMPER_ */
