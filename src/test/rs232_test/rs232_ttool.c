/*
 * Private property of IT6-DSPLAB group. 
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
#include <time.h>
#include <sys/uio.h>

#include <errno.h>

FILE 	*I;

#include "gps_registers.h"
#include "trace.h"

#define MAXLINE		255
#define BUF_SIZE	1024*1024	// 1 Mb

static gps_reg_str_t gps_regs[10];

typedef struct rs232_data_s {
	char	name[MAXLINE];
	char	cfg_name[MAXLINE];
	int	fd;
	
	int 	fd_flush;

	uint8_t	cmd;

	uint8_t recv_buf[BUF_SIZE];	

} rs232_data_t;

int rs232_program_gps(rs232_data_t *rs232data);
/*
 * Description: print banner 
 * Return:  	nothing	
 */
void rs232_banner()
{
	printf("Hello this is rs232 test tool for gps-board project by DSP-lab. This is real cool banner\n");
	printf("Usage: rs232_ttool [options]\n");
	printf("Options:\n");
	printf("  -p:	give the rs232 port name, something like this /dev/ttyS0\n");
	printf("  -p:	give the cfg-file name\n");
	printf("  -c:	command in hex\n");
	printf("  -h:	display this information\n");
}

/* maybe it'll read some cfg-files */
int rs232_read_cfg(rs232_data_t *rs232data)
{
	int		res, fd, iov_length, size_of_cfg;
	uint8_t		on = 1;
	size_t		cfg_size = 65536;
	char		cfg_data[cfg_size];
	char		*p_str, *p_start;
	int		addr;
	uint64_t	reg ;
	char		tmp_str[10] = {} ;
	char		pre_reg[2]; 
	
	struct 	iovec iov[2];

	sprintf(pre_reg, "# ");

	fd = open(rs232data->cfg_name, O_RDONLY, 0666);
	if( fd < 0 ) {
		printf("[err] [%s] during open the cfg file. errno %s\n", __func__, strerror(errno));
		exit(-1);
	}

	size_of_cfg = read(fd, cfg_data, cfg_size);
	if( size_of_cfg < 0 ) {
		printf("[err] [%s] during read the cfg file. errno %s\n", __func__, strerror(errno));
		exit(-1);
	}

	/* the main parsing loop */
	p_str = cfg_data;
	while(on) {

		if( *p_str == '\0' )
			break;

		p_start = p_str;
		do {
			//printf("[%c][%d]\n", *p_str, *p_str) ;
			p_str++;
		} while( (*p_str != '\n') && (*p_str != '\0') );

		printf("[%s]\n", __func__) ;

		if( *p_start != '#' ) {
			/* maybe it's data, algo not so robust as i wish */
			/* our format is =>addr[tab]value<= */
			/* sample 0 0x8ec0000 */

			iov_length = 2;

			iov[0].iov_base = pre_reg;
			iov[0].iov_len = sizeof(pre_reg);

			res = sscanf(p_start, "%04d %llx\n", &addr, &reg);
			if(res < 2) {
				printf("[err] cannot parse the string [%s]\n", p_start);
			} else {
				printf("[%s] detected addr[%d] reg[0x%llx]\n", __func__, addr, reg) ;
			}

			/* store the reg */
			gps_regs[addr].addr = (uint8_t)addr;
			gps_regs[addr].reg = reg;
										
			hex2str(tmp_str, addr);					
			snprintf(gps_regs[addr].str, 30, "# %sb 0x%08llx\n", tmp_str, reg);
		} else {
			iov_length = 1;
		}
		
		iov[iov_length - 1].iov_base = p_start;
		iov[iov_length - 1].iov_len = p_str - p_start + 1;		// + 1 = + '\n'

		writev(rs232data->fd_flush, iov, iov_length); 
		
		p_str++;
	}

	printf("[%s] we've parsed the cfg-file\n", __func__) ;

	
	rs232_program_gps(rs232data);

	return 0;
}

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
	
	//options.c_cflag = ~(CSTOP | CRTSCTS | PARENB | PARODD) | options.c_cflag;

	options.c_iflag &= ~(IXON|IXOFF|IXANY);

	/* tcflush(fd, TCIFLUSH); */
	if (tcsetattr(fd, TCSANOW, &options) == -1) {
		printf("Error, can't set rs232 attributes. errno %s", strerror(errno));
		return 0;
	}

	return fd;
}

static void rs232_destroy(rs232_data_t	*rs232data)
{
	close(rs232data->fd_flush);
	close(rs232data->fd);
}

int rs232_open_flush(rs232_data_t *rs232data)
{
	errno = 0;
	int		iov_length = 13;
	int		i;
	struct 		iovec iov[iov_length];

	rs232data->fd_flush = open("flush", O_RDWR|O_CREAT|O_TRUNC, 0666);

	if( rs232data->fd_flush < 0 ) {
		printf("[err] during open the flush file. errno %s\n", strerror(errno));
		exit(-1);
	}

	/* get and write current time */
	time_t	cur_time;
	char	p_time[40] = {};

	p_time[0] = '#' ;
	p_time[1] = ' ' ;

	time(&cur_time);
	ctime_r(&cur_time, p_time + 2);

	iov[0].iov_base = p_time;
	iov[0].iov_len = strlen(p_time);

	char	blank_str[10];
	sprintf(blank_str, "#\n");

	iov[1].iov_base = blank_str;
	iov[1].iov_len = strlen(blank_str);

	i = writev(rs232data->fd_flush, iov, 2);

	if( i < 0) {
		printf("[%s] err. errno [%s]\n", __func__, strerror(errno));
		exit(-1);
	}

	/* write comments from the cfg */
	rs232_read_cfg(rs232data) ;

	/* write summary registers */
	iov_length = 11;
	iov[0].iov_base = blank_str;
	iov[0].iov_len = strlen(blank_str);
	for( i = 1; i < 10; i++ ) {
		iov[i].iov_base = gps_regs[i-1].str;
		iov[i].iov_len = strlen(gps_regs[i-1].str);
	}

	iov[iov_length - 1].iov_base = blank_str;
	iov[iov_length - 1].iov_len = strlen(blank_str);

	i = writev(rs232data->fd_flush, iov, iov_length);

	if( i < 0) {
		printf("[%s] err. errno [%s]\n", __func__, strerror(errno));
		exit(-1);
	}

	return 0;
}

int rs232_send_cmd_flush(rs232_data_t *rs232data)
{
	printf("flush sram\n");
	uint8_t		buff[1<<18] = {};
	uint64_t	addr = 0;
	uint32_t	max_addr = (1<<18) - 2;
	
	uint64_t	comm_64;
	int 		res;

	char		str[10] = {};
	char		header_string[] = "# Mode: 2bit, sign/magnitude\n# format [q2 i2 q1 i1]\n# i\tq\n";
	char		str_i_q[255] = {};

	rs232_open_flush(rs232data);
	write(rs232data->fd_flush, header_string, strlen(header_string));

	/* flush it */
	comm_64 = (0x7ull) ;
	res = write(rs232data->fd, &comm_64, sizeof(uint64_t));
	
	for(addr = 0; addr < max_addr; addr++ ) {

		res = read(rs232data->fd, buff+addr, 1);

		hex2str(str, buff[addr]);

		printf("=replay= [0x%02x]\t b[%s] addr [%06lld]\n", buff[addr], str, addr);

		sprintf(str_i_q, "%d\t%d\n%d\t%d\n", 
			gps_value[GET_I1(buff[addr])],
			gps_value[GET_Q1(buff[addr])],
			gps_value[GET_I2(buff[addr])],
			gps_value[GET_Q2(buff[addr])]
		);

		write(rs232data->fd_flush, str_i_q, strlen(str_i_q));

	}
	
	return 0;
}

int rs232_send_cmd_flush_3bit(rs232_data_t *rs232data)
{
	printf("[%s]\n", __func__);

	uint8_t		buff[1<<18] = {};
	uint64_t	addr = 0;
	uint32_t	max_addr = (1<<18) - 2;
	
	uint64_t	comm_64;
	int 		res;

	char		str[10] = {};
	char		header_string[] = "# 3 bit form MSB => [i1 i0 q1] <= LSB\n";
	char		str_3bit[255] = {};


	rs232_open_flush(rs232data);
	write(rs232data->fd_flush, header_string, strlen(header_string));

	printf("[%s] try to read the data\n", __func__) ;

	/* flush it */
	comm_64 = (0x7ull) ;
	res = write(rs232data->fd, &comm_64, sizeof(uint64_t));
	
	for(addr = 0; addr < max_addr; addr++ ) {

		res = read(rs232data->fd, buff+addr, 1);

		hex2str(str, buff[addr]);

		printf("=replay= [0x%02x]\t b[%s] addr [%06lld]\n", buff[addr], str, addr);

		sprintf(str_3bit, "%d\n%d\n", 
			gps_val_3bit_sign[GET_3b_FIRST_VAL(buff[addr])],
			gps_val_3bit_sign[GET_3b_SECOND_VAL(buff[addr])] );

		write(rs232data->fd_flush, str_3bit, strlen(str_3bit));

	}

	return 0;
}

int rs232_send_cmd(rs232_data_t *rs232data)
{
	uint8_t		buff = 0;
	uint64_t	comm_64 = (uint64_t)rs232data->cmd;
	int 		res;

	res = write(rs232data->fd, &comm_64, sizeof(comm_64));
	printf("write 0x%016llx, res [%d]\n", comm_64, res);
	res = read(rs232data->fd, &buff, 1);
	printf("=replay= [0x%02x] \n", buff);

	if( res < 0 ) {
		if( errno != EAGAIN ) {
			printf("[ERR] error occur while in data sending. errno %s\n", strerror(errno));
			return -1;
		}

		printf("[WARN] EAGAIN occur while sending, need to do something =] \n");
	}

	return res;
}

/* program the gps via serial interface */
int rs232_program_gps(rs232_data_t *rs232data)
{
	int 		res;
	uint8_t		i;
	uint64_t	comm_64;
	uint8_t		buff = 0;


	for( i = 0; i < 11; i++ ) {
		comm_64 = 1ull;		

		comm_64 |= (gps_regs[i].reg<<12);			// data
		comm_64 |= (i<<8);					// address
		
		res = write(rs232data->fd, &comm_64, sizeof(comm_64));
		printf("write 0x%016llx, res [%d]\n", comm_64, res);
		res = read(rs232data->fd, &buff, sizeof(buff));
		printf("=replay= [0x%02x] \n", buff);
	}
	
	return 0;
}

int rs232_send(rs232_data_t *rs232data)
{
	rs232data->cmd = 1;
	uint8_t		buff = 0;
	uint64_t	comm_64 = rs232data->cmd;
	int 		res, todo = sizeof(comm_64);		// FIXME - fix todo

	printf("[%s] block while sending\n", __func__);

	res = write(rs232data->fd, &comm_64, todo);
	printf("write 0x%016llx, res [%d]\n", comm_64, res);
	res = read(rs232data->fd, &buff, 1);
	printf("=replay= [0x%02x] \n", buff);
	return res;
}

void rs232_zero_mem(rs232_data_t *rs232data)
{
	printf("ZEROOOO the memery\n");
	uint8_t		buff = 0;
	uint64_t	addr = 0;
	uint64_t	max_addr = (1<<18);
	
	uint64_t	comm_64 = rs232data->cmd;
	int 		res;
	
	for(addr = 0; addr < max_addr; addr++ ) {

		comm_64 = ((0x4ull) | (addr<<8) | (0x0ull<<26));

		res = write(rs232data->fd, &comm_64, sizeof(uint64_t));
		printf("write 0x%016llx, res [%d]\n", comm_64, res);

		res = read(rs232data->fd, &buff, 1);
		if( buff != 4 ) {
			printf("something wrong =(( [%x]\n", buff);
			exit(-1);
		}

		printf("=replay= [0x%02x]\t addr [%06lld]\n", buff, addr);
	}


}

int main(int argc, char **argv)
{
	rs232_data_t	rs232data = {};
	int 		res;

#if 0	
	uint8_t		val = 0x2b;
	

for(val = 0; val < 16; val++ )
	printf("%d [%x] => %d\t[%x] => %d\n", val,
		GET_3b_FIRST_VAL(val<<4),
		gps_val_3bit_usign[GET_3b_FIRST_VAL(val<<4)],
		GET_3b_SECOND_VAL(val<<4),
		gps_val_3bit_usign[GET_3b_SECOND_VAL(val<<4)]
	);

	exit(-1);
#endif 

	while ( (res = getopt(argc,argv,"hp:c:f:")) != -1){
		switch (res) {
		case 'h':
			rs232_banner();
			return -1;
		case 'p':
			printf("rs232 port set to [%s]\n", optarg);
			snprintf(rs232data.name, MAXLINE, "%s", optarg);
			break;
		case 'f':
			printf("cfg-name set to [%s]\n", optarg);
			snprintf(rs232data.cfg_name, MAXLINE, "%s", optarg);
			break;
		case 'c':
			//rs232data.cmd = atoi(optarg);
			//snprintf(buf, MAXLINE, "%d", optarg);
			sscanf(optarg, "%hx", (short unsigned int *)&rs232data.cmd);
			printf("rs232 command [0x%02x]\n", rs232data.cmd);
			break;
		default:
			return -1;
        	};
	};

	errno = 0;
	rs232data.fd = rs232_open_device(rs232data.name); 
	if( rs232data.fd == 0 )
		return -1;

	printf("\nHello, this is rs232 dumper for GPS-project \n");

	/* send command */
	if(rs232data.cmd == 0xa) {
		/* reset GPS */
		rs232_program_gps(&rs232data);
	} else if(rs232data.cmd == 0xb) {
		rs232_zero_mem(&rs232data);
	} else if(rs232data.cmd == 0xff) {
		rs232_send_cmd_flush(&rs232data);
		//rs232_send_cmd_flush_3bit(&rs232data);
	} else {
		 rs232_send_cmd(&rs232data);
	}

	/* receive data */
	//rs232_receive(&rs232data);

	/* free memory and close all fd's */
	rs232_destroy(&rs232data);

	return 0;
}
