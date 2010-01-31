/* Developer: Alex Nikiforov nikiforov.al [at] gmail.com */

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

#include <pthread.h>

#include "board_daemon.h"
#include "rs232_dumper.h"
#include "gui_server.h"

/*
 * Description: print banner 
 * Return:  	nothing	
 */
void board_daemon_banner()
{
	printf("Hello this is board_daemon for gps-board project by DSP-lab IT6 faculty MGUPI university.\n");
	printf("Usage: board_daemon [options]\n");
	printf("Options:\n");
	printf("  -c:	config file\n");
	printf("  -h:	display this information\n");
}

static void board_daemon_destroy(bd_data_t	*bd_data)
{
	TRACE(0, "[%s] free memory, close fd\n", __func__);

	close(bd_data->client[0].fd);
	close(bd_data->client[1].fd);
	close(bd_data->client[2].fd);

	free(bd_data);
	bd_data = NULL;
}

int main(int argc, char **argv) {
	
	bd_data_t	*bd_data = (bd_data_t *)malloc(sizeof(bd_data_t));
	int 		res;

	memset(bd_data, 0, sizeof(bd_data));

	/* FIXME - some constants, need implement it */
	I = stdout;
	sprintf(bd_data->name, "/dev/ttyS0");

	/* parse input */
	while ( (res = getopt(argc,argv,"hc:")) != -1){
		switch (res) {
		case 'h':
			board_daemon_banner();
			return -1;
		
		case 'c':
			strncpy(bd_data->cfg_name, optarg, MAXLINE);
			break;
		
		default:
			return -1;
        	};
	};

	if( strlen(bd_data->cfg_name) == 0 ) {
		TRACE(0, "[%s] Error. You must declare a config name via -c parameter\n", __func__);
		return -1;
	}

#if 0
	if( rs232_make_net(&rs232data) != 0 )
		return -1;

	if( rs232_make_signals(&rs232data) != 0 )
		return -1;

	/* init section */
	rs232data.client[BOARD_FD].fd = -1;

	/* protocol handler */
	rs232_connection(&rs232data);
	rs232_idle(&rs232data);

#endif

	/* init environment */
	rs232_open_device(bd_data);
	bd_data->need_exit = 1;
	bd_data->port = 1234;
	need_exit = 1;

	/* create new threads */	
	res = pthread_create(&bd_data->gui_thread, NULL, gui_process, bd_data);
	if ( res ){
		TRACE(0, "[%s] Error; return code from pthread_create() is %d. errno: %s\n",
			__func__, res, strerror(errno) );
		goto destroy;
	}

	/* FIXME improve it */
	while(need_exit) {
	}

	/* free memory and close all fd's */
destroy:
	board_daemon_destroy(bd_data);

	return 0;
}
