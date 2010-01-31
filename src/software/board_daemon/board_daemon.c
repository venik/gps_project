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

#include "board_daemon.h"

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
	close(bd_data->client[0].fd);
	close(bd_data->client[1].fd);
	close(bd_data->client[2].fd);
}

int main(int argc, char **argv) {
	
	bd_data_t		bd_data = {};
	int 			res;
	
	I = stdout;

	while ( (res = getopt(argc,argv,"hc:")) != -1){
		switch (res) {
		case 'h':
			board_daemon_banner();
			return -1;
		
		case 'p':
			fprintf(I, "Set listen port to [%s]\n", optarg);
			bd_data.port = atoi(optarg);
			break;
		
		default:
			return -1;
        	};
	};

#if 0
	if( rs232_check_opts(&rs232data) != 0 )
		return -1;

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

	/* free memory and close all fd's */
	board_daemon_destroy(&bd_data);

	return 0;
}
