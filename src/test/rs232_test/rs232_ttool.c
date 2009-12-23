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

#include <errno.h>

#include "gps_registers.h"

#define MAXLINE		255
#define BUF_SIZE	1024*1024	// 1 Mb

typedef struct rs232_data_s {
	char	name[MAXLINE];
	int	fd;
	
	int 	fd_flush;

	uint8_t	cmd;

	uint8_t recv_buf[BUF_SIZE];	

} rs232_data_t;

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
	printf("  -c:	command in hex\n");
	printf("  -h:	display this information\n");
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

void rs232_destroy(rs232_data_t	*rs232data)
{
	close(rs232data->fd);
}

int rs232_open_flush(rs232_data_t *rs232data)
{
	errno = 0;

	rs232data->fd_flush = open("flush", O_RDWR|O_CREAT|O_TRUNC, 0666);

	if( rs232data->fd_flush < 0 ) {
		printf("[err] during open the flush file. errno %s\n", strerror(errno));
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
	int 		res, fd;

	char		str[10] = {};
	char	header_string[] = "i\tq\n";
	char	str_i_q[255] = {};

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
	
	close(fd);

	return 0;
}

int rs232_send_cmd_flush_3bit(rs232_data_t *rs232data)
{
	printf("[%s]\n", __func__);

	uint8_t		buff[1<<18] = {};
	uint64_t	addr = 0;
	uint32_t	max_addr = (1<<18) - 2;
	
	uint64_t	comm_64;
	int 		res, fd;

	char		str[10] = {};
	char	header_string[] = "3 bit form MSB => [i1 i0 q1] <= LSB \n";
	char	str_3bit[255] = {};


	rs232_open_flush(rs232data);
	write(fd, header_string, strlen(header_string));

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
	
	close(fd);

	return 0;
}

int rs232_send_cmd(rs232_data_t *rs232data)
{
	uint8_t		buff = 0;
	uint64_t	comm_64 = (uint64_t)rs232data->cmd;
	int 		res;
	uint64_t	reg = 0;

	/* users */
	//comm_64 |= (0x01<<8);			// address
	//comm_64 |= (0x855028cull<<12);		// data
	//comm_64 |= (0x7<<8);			// address
	//comm_64 |= (0x3fff1d9ull<<12);		// data

	comm_64 |= (0x01<<0x08);		// address
	//reg |= (VCOEN|IVCO_n|REFOUTEN|REFDIV_x1|IXTAL_bnc|ICP_05ma|PFDEN_en|INT_PLL_frac|PWSAV_off|REG_23);
	//reg = 0x8ec0000;
	//reg = 0xeaff1dc;
	//reg = 0x855048c;
	//reg = 0xa2939a3;
	comm_64 |= (reg<<12);	// data

	//comm_64 = (comm_64 | 0x56ull<<8 | 0xabull<<26);

	//res = write(rs232data->fd, &comm_64, sizeof(uint64_t));
	//res = write(rs232data->fd, &byte, sizeof(uint8_t));
	//printf("write 0x%016llx, res [%d]\n", comm_64, res);
	//printf("write 0x%02x, res [%d]\n", byte, res);

	//res = read(rs232data->fd, &buff, 1);
	//printf("=replay= [0x%02x]\t\n", buff);

#if 1
	int i;
	//for(i=0; i<8; i++) {
	for(i=0; i<1; i++) {
		comm_64 = rs232data->cmd;
		comm_64 |= ((0x01ull<<i)<<8);		// address
		//comm_64 |= (0x55ull<<26);		// data
		comm_64 |= (0x00ull<<26);		// data

		//printf("data for mem [%x]\n", (uint8_t)(comm_64>>26));
		
		//res = write(rs232data->fd, &comm_64, todo);
		res = write(rs232data->fd, &comm_64, sizeof(comm_64));
		printf("write 0x%016llx, res [%d]\n", comm_64, res);
		res = read(rs232data->fd, &buff, 1);
		printf("=replay= [0x%02x] \n", buff);
	}
#endif


	if( res < 0 ) {
		if( errno != EAGAIN ) {
			printf("[ERR] error occur while in data sending. errno %s\n", strerror(errno));
			return -1;
		}

		printf("[WARN] EAGAIN occur while sending, need to do something =] \n");
	}

	return res;
}

int rs232_send(rs232_data_t *rs232data)
{
	rs232data->cmd = 1;
	uint8_t		buff = 0;
	uint64_t	comm_64 = rs232data->cmd;
	int 		res, todo = sizeof(comm_64);		// FIXME - fix todo

	printf("[%s] block while sending\n", __FUNCTION__);

#if 0
	comm_64 |= (0x11<<8);
	comm_64 |= (0x22<<16);
	comm_64 |= (0x33<<24);
	comm_64 |= (0x44ull<<32);
	comm_64 |= (0x55ull<<40);
	comm_64 |= (0x66ull<<48);
	comm_64 |= (0x77ull<<56);
	
	comm_64 |= (0x00ull<<26);
#endif

	/* 0000 */
	comm_64 |= (0x00<<8);			// address
	comm_64 |= (0xa2939a3ull<<12);
	res = write(rs232data->fd, &comm_64, todo);
	printf("write 0x%016llx, res [%d]\n", comm_64, res);
	res = read(rs232data->fd, &buff, 1);
	printf("=replay= [0x%02x] \n", buff);

	/* 0001 */
	comm_64 = rs232data->cmd;
	comm_64 |= (0x01<<8);			// address
	//comm_64 |= (0x0855028Cull<<12);		// data
	comm_64 |= (0x8550c8cull<<12);		// data
	res = write(rs232data->fd, &comm_64, todo);
	printf("write 0x%016llx, res [%d]\n", comm_64, res);
	res = read(rs232data->fd, &buff, 1);
	printf("=replay= [0x%02x] \n", buff);

	/* 0010 */
	comm_64 = rs232data->cmd;
	comm_64 |= (0x02<<8);			// address
	//comm_64 |= (0xeaff1dcull<<12);		// data				// FIXME
	comm_64 |= (0x6aff1dcull<<12);		// data				// FIXME
	res = write(rs232data->fd, &comm_64, todo);
	printf("write 0x%016llx, res [%d]\n", comm_64, res);
	res = read(rs232data->fd, &buff, 1);
	printf("=replay= [0x%02x] \n", buff);
	
	/* 0011 */
	comm_64 = rs232data->cmd;
	comm_64 |= (0x03<<8);			// address
	comm_64 |= (0x9ec0008ull<<12);		// data
	res = write(rs232data->fd, &comm_64, todo);
	printf("write 0x%016llx, res [%d]\n", comm_64, res);
	res = read(rs232data->fd, &buff, 1);
	printf("=replay= [0x%02x] \n", buff);

	/* 0100 */
	comm_64 = rs232data->cmd;
	comm_64 |= (0x04<<8);			// address
	comm_64 |= (0x0c00080ull<<12);		// data
	res = write(rs232data->fd, &comm_64, todo);
	printf("write 0x%016llx, res [%d]\n", comm_64, res);
	res = read(rs232data->fd, &buff, 1);
	printf("=replay= [0x%02x] \n", buff);

	/* 0101 */
	comm_64 = rs232data->cmd;
	comm_64 |= (0x05<<8);			// address
	comm_64 |= (0x8000070ull<<12);		// data
	res = write(rs232data->fd, &comm_64, todo);
	printf("write 0x%016llx, res [%d]\n", comm_64, res);
	res = read(rs232data->fd, &buff, 1);
	printf("=replay= [0x%02x] \n", buff);

	/* 0110 */
	comm_64 = rs232data->cmd;
	comm_64 |= (0x06<<8);			// address
	comm_64 |= (0x8000000ull<<12);		// data
	res = write(rs232data->fd, &comm_64, todo);
	printf("write 0x%016llx, res [%d]\n", comm_64, res);
	res = read(rs232data->fd, &buff, 1);
	printf("=replay= [0x%02x] \n", buff);

	/* 0111 */
	comm_64 = rs232data->cmd;
	comm_64 |= (0x07<<8);			// address
	comm_64 |= (0x10061b2ull<<12);		// data
	res = write(rs232data->fd, &comm_64, todo);
	printf("write 0x%016llx, res [%d]\n", comm_64, res);
	res = read(rs232data->fd, &buff, 1);
	printf("=replay= [0x%02x] \n", buff);

	/* 1000 */
	comm_64 = rs232data->cmd;
	comm_64 |= (0x08<<8);			// address
	comm_64 |= (0x1e0f401ull<<12);		// data
	res = write(rs232data->fd, &comm_64, todo);
	printf("write 0x%016llx, res [%d]\n", comm_64, res);
	res = read(rs232data->fd, &buff, 1);
	printf("=replay= [0x%02x] \n", buff);

	/* 1001 */
	comm_64 = rs232data->cmd;
	comm_64 |= (0x09<<8);			// address
	comm_64 |= (0x14c0402ull<<12);		// data
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

	while ( (res = getopt(argc,argv,"hp:tc:")) != -1){
		switch (res) {
		case 'h':
			rs232_banner();
			return -1;
		case 'p':
			printf("rs232 port set to [%s]\n", optarg);
			snprintf(rs232data.name, MAXLINE, "%s", optarg);
			break;
		case 'c':
			//rs232data.cmd = atoi(optarg);
			//snprintf(buf, MAXLINE, "%d", optarg);
			sscanf(optarg, "%hx", (short unsigned int *)&rs232data.cmd);
			printf("rs232 command [0x%02x]\n", rs232data.cmd);
			break;
		case 't':
			printf("test mode\n");
			//rs232data.cb = &rs232_test_mode;
			//rs232_test_mode(&rs232data);
			return -1;
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
		 rs232_send(&rs232data);
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
