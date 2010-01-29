#ifndef _RS232_DUMPER_H
#define _RS232_DUMPER_H

#include <poll.h>

#define MAXLINE		255
#define BUF_SIZE	1024*1024	// 1 Mb
#define TIMEOUT		3000		// 3 sec

/* commands */
#define SET_PORT_CMD	"RS232_PORT:"
#define TEST_RS232_CMD	"TEST_RS232\r\n"
#define TEST_SRAM_CMD	"TEST_SRAM\r\n"
#define ACK		"ACK\r\n"
#define ERR 		"ERR: UNKNOWN COMMAND\r\n"

FILE 		*I;
uint8_t		need_exit;

enum rs232_fd_list {
	LISTEN_FD	= 0,
	GUI_FD		= 1,
	BOARD_FD	= 2
};

/*****************************************
 *	Text protocol GUI <=> Dumper
 *****************************************/

/* avalible commands */
char	rs232_commands[][255] = 
{
	{"RS232_PORT:"},
	{"TEST_RS232"},
	{"TEST_SRAM"},
	{""}
};

/********************************************
 *	Binary protocol Dumper <=> GPS-Board 
 ********************************************/
enum rs232_comm_request {
	/* 0x00 - 0x10 	SRAM-command */
	RS232_TEST_SRAM		= 0x02,
	RS232_WRITE_BYTE	= 0x04,
	RS232_READ_BYTE		= 0x08,
	/* 0x11 - 0x20 	GPS-command */
	RS232_SET_REG		= 0x11,
	/* Other */
	RS232_TEST_RS232	= 0xAA 
};

/********************************************
 *	Work definition 
 ********************************************/
typedef struct rs232_data_s {

	char		name[MAXLINE];			/* rs232 dev-name */
	uint8_t 	recv_buf[BUF_SIZE];
	uint8_t 	send_buf[BUF_SIZE];

	/* network part */
	struct pollfd	client[3];
	uint16_t	port;

} rs232_data_t;

/* signal handlers */
static void rs232_sig_INT(int sig)
{
        need_exit = 0;
        signal(15, SIG_IGN);
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

/* help functions */
void dump_asci(volatile uint8_t *data, size_t size)
{
        unsigned long   i;

        for(i=0;i<size;i++) {
                if(!(i&0x1f)) {
                        fprintf(I, "\n%08lx:", i);
                }
                uint8_t c = *data;
                c = (c > 0x1f) && (c < 0x7f) ?c :'.';
                fprintf(I, "  %c",  c);
                data++;
        }
        fprintf(I, "\n");
}

void dump_hex(volatile uint8_t *data, size_t size)
{
        unsigned long   i;

        dump_asci(data, size);

        fprintf(I, "len: %lu@%08lx", (unsigned long)size, (unsigned long)data);
        if(!data)
                return;

        for(i=0;i<size;i++) {
                if(!(i&0x1f)) {
                        fprintf(I, "\n%08lx:", i);
                }

                fprintf(I, " %02x", *data);
                data++; 
        } 
        fprintf(I, "\n");
}

/* network helpers */
int rs232_poll_read(rs232_data_t *rs232data, uint8_t num, size_t todo)
{
	int nready, res;
	struct pollfd	*pfd = &rs232data->client[num];

	//fprintf(I, "[%s]\n", __FUNCTION__);

	pfd->events = POLLIN;

	nready = poll(pfd, 1, -1);
	//nready = poll(rs232data->client, 3, -1);

	if( nready < 1 ) {
		/* client not ready */
		fprintf(I, "[%s] no data in the client socket\n", __func__);
		return -1;
	}

	fprintf(I, "[%s] data here\n", __func__);

	if( pfd->revents & POLLIN ) {
		
		res = read(pfd->fd, rs232data->recv_buf, todo);
		fprintf(I, "[%s] need [%d] received [%d] \n", __func__, todo, res);
		
		if( res < 0 ) {
			/* error occur */
			fprintf(I, "[err] while reading. errno [%s]\n", strerror(errno));
			close(pfd->fd);
			return -1;
		} else if( res == 0 ) {
			fprintf(I, "closed socket\n");
			close(pfd->fd);
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

	//fprintf(I, "[%s]\n", __func__);

	pfd->events = POLLOUT;

	nready = poll(pfd, 1, TIMEOUT);

	if( nready < 1 ) {
		fprintf(I, "[err] the GUI not ready, disconnect...\n");
		/* client not ready */
		return -1;
	}

	if( pfd->revents & POLLOUT ) {
	
		dump_hex(rs232data->send_buf, todo);
	
		do {
			errno = 0;
			res = write(pfd->fd, rs232data->send_buf, todo);

			if( res < 0 ) {
				/* error occur */
				fprintf(I, "[%s] [err] while writing. errno [%s]\n", __func__, strerror(errno));
				close(pfd->fd);
				return -1;
			} else if( res == 0 ) {
				fprintf(I, "[%s] [err] GUI closed the socket\n", __func__);
				close(pfd->fd);
				return -1;
			}

			if( res != todo ) {
				fprintf(I, "[%s] fd = [%d] res = [%d] todo = [%d]",
					__func__, pfd->fd, res, todo );
			}
			
			todo -= res;

		} while(todo != 0);

		return 0;
	}
			
	return -1;
}

#endif /* _RS232_DUMPER_H */
