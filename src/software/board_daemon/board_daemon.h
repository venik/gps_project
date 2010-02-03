#ifndef _BD_DAEMON_H
#define _BD_DAEMON_H

#define TRACE_LEVEL 0

#include <poll.h>
#include "trace.h"
#include "gps_registers.h"

#define MAXLINE		255
#define BUF_SIZE	1024*1024	// 1 Mb
#define TIMEOUT		3000		// 3 sec

#define SECOND		1000000
#define	MINUTE		60 * SECOND

enum bd_fd_list {
	LISTEN_FD	= 0,
	GUI_FD		= 1,
	BOARD_FD	= 2,
	DUMP_FD		= 3
};

/********************************************
 *	Work definition 
 ********************************************/
typedef struct bd_data_s {

	char		name[MAXLINE];		/* rs232 dev-name */
	uint8_t 	recv_buf[BUF_SIZE];
	uint8_t 	send_buf[BUF_SIZE];

	/* network part */
	struct pollfd	client[4];
	uint32_t	port;

	/* support */
	char		cfg_name[MAXLINE];	/* config name */	
	int 		need_exit;

	pthread_t	gui_thread;
	pthread_t	rs232_thread;
	
	/* gps registers array */
	gps_reg_str_t gps_regs[10];
} bd_data_t;

/* signal handlers */
static void bd_sig_INT(int sig)
{
        need_exit = 0;
        signal(15, SIG_IGN);
}

int bd_make_signals()
{
	/* registering signals */
	struct sigaction int_sig;
       
	TRACE(0, "[%s] make signal handlers\n", __func__);

	int_sig.sa_handler = &bd_sig_INT;
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

/* network helpers */
int bd_poll_read(bd_data_t *bd_data, uint8_t num, size_t todo)
{
	int nready, res;
	struct pollfd	*pfd = &bd_data->client[num];
	//fprintf(I, "[%s]\n", __func__);

	pfd->events = POLLIN;

	//nready = poll(pfd, 1, -1);
	nready = poll(pfd, 1, TIMEOUT);

	if( nready < 1 ) {
		/* client not ready */
		fprintf(I, "[%s] no data in the client socket\n", __func__);
		return -1;
	}

	fprintf(I, "[%s] data here\n", __func__);

	if( pfd->revents & POLLIN ) {
		
		res = read(pfd->fd, bd_data->recv_buf, todo);
		fprintf(I, "[%s] need [%d] received [%d] \n", __func__, todo, res);
	
		bd_data->recv_buf[res] = '\0';

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
	
		dump_hex(bd_data->recv_buf, res);

		fprintf(I, "[%s] fd = [%d] read = [%d]\n", __func__, pfd->fd, res );
		return res;
	}
			
	return -1;
}

int bd_poll_write(bd_data_t *bd_data, uint8_t num, size_t todo)
{
	int nready, res;
	struct pollfd	*pfd = &bd_data->client[num];

	fprintf(I, "[%s] todo [%d]\n", __func__, todo);

	pfd->events = POLLOUT;

	nready = poll(pfd, 1, TIMEOUT);

	if( nready < 1 ) {
		fprintf(I, "[err] the GUI not ready, disconnect...\n");
		/* client not ready */
		return -1;
	}

	if( pfd->revents & POLLOUT ) {
	
		dump_hex(bd_data->send_buf, todo);
	
		do {
			errno = 0;
			res = write(pfd->fd, bd_data->send_buf, todo);

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

#endif /* */
