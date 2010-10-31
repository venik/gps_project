#ifndef __RS232_DUMPER_
#define __RS232_DUMPER_

#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>

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
	int		iov_length = 14;
	int		i;
	struct 		iovec iov[iov_length];
	struct pollfd	*pfd = &bd_data->client[DUMP_FD];

	pfd->fd = open((char *)bd_data->dump_file, O_RDWR|O_CREAT|O_TRUNC, 0666);

	if( pfd->fd < 0 ) {
		TRACE(0, "Error. during open the flush file. errno %s\n", strerror(errno));
		exit(-1);
	}

	/* get and write current time */
	time_t	cur_time;
	char	banner_size[BANNER_SIZE] = {};			// # banner_size
	char	p_time[40] = "# ";
	char	blank_str[] = "#\n";

	time(&cur_time);
	ctime_r(&cur_time, p_time + 2);

	iov[0].iov_base = banner_size;				// 4 octets for banner size
	iov[0].iov_len = sizeof(banner_size);
	iov[1].iov_base = p_time;
	iov[1].iov_len = strlen(p_time);
	iov[2].iov_base = blank_str;
	iov[2].iov_len = strlen(blank_str);

	for( i = 0; i < 10; i++ ) {
		iov[i + 3].iov_base = bd_data->gps_regs[i].str;
		iov[i + 3].iov_len = strlen(bd_data->gps_regs[i].str);
	}

	iov[13].iov_base = blank_str;
	iov[13].iov_len = strlen(blank_str);

	i = writev(pfd->fd, iov, iov_length);

	if( i < 0) {
		TRACE(0, "[%s] err. errno [%s]\n", __func__, strerror(errno));
		return -1;
	}

	return 0;
}

int rs232_dump_upload(bd_data_t *bd_data)
{
	pid_t	pid;

	if( (pid = fork()) < 0 ) {
		TRACE(0, "Error. Cannot fork(). errno: %s\n", strerror(errno));
		return -1;
	} else if( pid == 0) {
		if( execl("/bin/sh", "sh", bd_data->upload_script, NULL) < 0 ) {
			TRACE(0, "Error execl(). errno: %s\n", strerror(errno));
			return -1;
		}
	};
	
	if( waitpid(pid, NULL, 0) < 0 ) {
		TRACE(0, "Error waitpid()\n");
		return -1;
	}

	return 0;
}

static int rs232_dump_gps_banner(bd_data_t *bd_data)
{
    	int 		res ;
	uint64_t	comm_64 ;

	char		header_string[] = "# Mode: 2bit, sign/magnitude\n# format [q2 i2 q1 i1]\n# i\tq\n";
	
	struct pollfd	*pfd = &bd_data->client[BOARD_FD];
	struct pollfd	*dfd = &bd_data->client[DUMP_FD];

	/* make banner */
	rs232_open_dump_file(bd_data);
	write(dfd->fd, header_string, strlen(header_string));

	/* flush it */
	comm_64 = RS232_DUMP_DATA ;
	res = write(pfd->fd, &comm_64, sizeof(uint64_t));

	/* write banner size */
	lseek(dfd->fd, (off_t)0, SEEK_SET);
	off_t size_dump = lseek(dfd->fd, (off_t)0, SEEK_END);
	TRACE(9, "==> size [%d]\n", (int)size_dump);

	lseek(dfd->fd, (off_t)0, SEEK_SET);		// skip ## at start of the first line

	char	size_string[BANNER_SIZE] = "";
	snprintf(size_string, sizeof(size_string),"# [%x]", (uint16_t)size_dump);
	size_string[BANNER_SIZE-1] = '\n';

	write(dfd->fd, (uint32_t *)&size_string, BANNER_SIZE);

	lseek(dfd->fd, (off_t)0, SEEK_END);		// set ptr to end of the file 

	return 0;
}

static int rs232_dump_finish(bd_data_t *bd_data)
{
	struct pollfd	*dfd = &bd_data->client[DUMP_FD];

	TRACE(0, "[%s] Dumped successfully\n", __func__);

	/* upload flush */
	rs232_dump_upload(bd_data);
	TRACE(0, "[%s] Uploaded successfully\n", __func__);

	close(dfd->fd);

	return 0;
}

int rs232_dump_gps_text(bd_data_t *bd_data)
{
	TRACE(0, "[%s] Start dumping \n", __func__);

	uint8_t		buff[1<<18] = {};
	uint64_t	addr;
	uint32_t	max_addr = (1<<18);
	int 		res;
	char		str_i_q[255] = {};
	
	struct pollfd	*pfd = &bd_data->client[BOARD_FD];
	struct pollfd	*dfd = &bd_data->client[DUMP_FD];

	snprintf((char *)bd_data->dump_file, MAXLINE, "/tmp/flush.txt");
	rs232_dump_gps_banner(bd_data);
	
	/* because the first data is buggy */
	for(addr = 1; addr < max_addr; addr++ ) {

		res = read(pfd->fd, buff+addr, 1);

		//hex2str(str, buff[addr]);
		//TRACE(0, "=replay= [0x%02x]\t b[%s] addr [%06lld]\n", buff[addr], str, addr);

		WRITE_BYTE_TXT(dfd->fd, buff[addr], str_i_q, res);
	}

	rs232_dump_finish(bd_data);

	return 0;
}

static int rs232_dump_gps_both(bd_data_t *bd_data)
{
	TRACE(0, "[%s] Start dumping \n", __func__);

	uint8_t		buff[1<<18] = {};
	uint32_t	addr;
	uint32_t	max_addr = (1<<18);
	int 		res;
	
	struct pollfd	*pfd = &bd_data->client[BOARD_FD];
	struct pollfd	*dfd = &bd_data->client[DUMP_FD];

	int	dfd_bin, dfd_txt;

	/* make binary file */
	snprintf((char *)bd_data->dump_file, MAXLINE, "/tmp/flush.bin");
	rs232_dump_gps_banner(bd_data);

	dfd_bin = dfd->fd;

	/* make txt file */
	char		str_i_q[255] = {};
	
	snprintf((char *)bd_data->dump_file, MAXLINE, "/tmp/flush.txt");
	rs232_dump_gps_banner(bd_data);

	dfd_txt =  dfd->fd;

	int fd_dummy = open("source", (O_RDWR));
	for(addr = 1; addr < max_addr; addr++ ) {
		//res = read(pfd->fd, buff+addr, 1);
		res = read(fd_dummy, buff+addr, 1);

		//TRACE(0, "%02d: val [%02x]\n", (int)addr, buff[addr]);

		write(dfd_bin, buff+addr, 1);
		WRITE_BYTE_TXT(dfd_txt, buff[addr], str_i_q, res);
	}

	exit(-1);

	rs232_dump_finish(bd_data);
	return 0;
}


int rs232_dump_gps_bin(bd_data_t *bd_data)
{
	TRACE(0, "[%s] Start dumping \n", __func__);

	uint8_t		buff[1<<18] = {};
	uint64_t	addr;
	uint32_t	max_addr = (1<<18);
	
	struct pollfd	*pfd = &bd_data->client[BOARD_FD];
	struct pollfd	*dfd = &bd_data->client[DUMP_FD];
	
	int 		res;

	snprintf((char *)bd_data->dump_file, MAXLINE, "/tmp/flush.bin");
	rs232_dump_gps_banner(bd_data);
	
	/* because the first data is buggy */
	for(addr = 1; addr < max_addr; addr++ )
		res = read(pfd->fd, buff+addr, 1);
	
	write(dfd->fd, buff, sizeof(buff));

	rs232_dump_finish(bd_data);

	return 0;
}

int rs232_program_max(bd_data_t *bd_data)
{
	int 		res = 1;
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
	//bd_data->bd_dump_cb(bd_data);
	rs232_dump_gps_both(bd_data);

	return 0;
}

void *rs232_process(void *priv)
{
	int	res;
	useconds_t flush_time = 10 * MINUTE, time_remain = 0 ;
	useconds_t cycle_time = 30 * SECOND;

	bd_data_t *bd_data = (bd_data_t *)priv;
	
	res = rs232_open_device(bd_data);
	if( res == -1 )
		pthread_exit((void *) -1);

	res = rs232_program_max(bd_data);
	if( res == -1 )
		pthread_exit((void *) -1);

	while(bd_data->need_exit) {
		TRACE(0, "[%s] Process...\n", __func__);

		/* FIXME - too late now, i need checkit */
		if( (bd_data->need_flush_now != 0) || (time_remain >= flush_time) ) {

			if( bd_data->client[BOARD_FD].fd < 0 ) {
				TRACE(0, "[%s] Warning. Board not connected!!!\n", __func__);
				pthread_exit((void *) -1);
			} else {
				/* FIXME - check the task from gui */
				time_remain = 0;	
				res = rs232_work(bd_data);
				/* check for errors */
				if( res < 0 )
					break;
			
				/* clear the flag */
				bd_data->need_flush_now = 0;

			} // if( bd_data->client[BOARD_FD].fd < 0 )
		} // if( (bd_data->need_flush_now == 0) || (time_remain >= flush_time) )

		usleep(cycle_time);
		time_remain += cycle_time;
	}

	TRACE(0, "[%s] near exit\n", __func__);

	pthread_exit((void *) 0);
}

#endif /* __RS232_DUMPER_ */
