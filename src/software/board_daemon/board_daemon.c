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

FILE 		*I;
int 		need_exit;

#include "board_protocols.h"
#include "board_daemon.h"
#include "gps_registers.h"
#include "rs232_dumper.h"
#include "gui_server.h"
#include "cfg_parser.h"

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

static void board_daemon_destroy(bd_data_t *bd_data)
{
	TRACE(0, "[%s] free memory, close fd\n", __func__);

	close(bd_data->client[0].fd);
	close(bd_data->client[1].fd);
	close(bd_data->client[2].fd);

	free(bd_data);
	bd_data = NULL;
}

int board_daemon_cfg(bd_data_t *bd_data)
{
	cfg_parser_t	*cfg_parser = NULL;
	char		tmp_str[MAXLINE] = {};
	int 		i;

	TRACE(0, "[%s]\n", __func__);

	cfg_string_t cfg_vals[] = { 	{"addr0", 0},
					{"addr1", 0},
					{"addr2", 0},
					{"addr3", 0},
					{"addr4", 0},
					{"addr5", 0},
					{"addr6", 0},
					{"addr7", 0},
					{"addr8", 0},
					{"addr9", 0},
					{"port",  0},
					{"", 0}
				};

	cfg_parser = cfg_prepare(bd_data->cfg_name, cfg_vals);
	if( cfg_parser == NULL ) {
		return -1;
	}

	cfg_get_vals(cfg_parser) ;

	/* store args */
	snprintf(tmp_str, MAXLINE, "%llx", cfg_vals[0].val);
	sscanf(tmp_str, "%d", &bd_data->port);

	for( i=0; i<11; i++) {
		bd_data->gps_regs[i].reg = cfg_vals[i].val ;
		hex2str(tmp_str, i);
		sprintf(bd_data->gps_regs[i].str, "# %sb 0x%08llx\n", tmp_str, cfg_vals[i].val);
	}
	
	cfg_destroy(cfg_parser);

	return 0;
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

	if( bd_make_signals(bd_data) != 0 )
		return -1;

	if( board_daemon_cfg(bd_data) != 0 )
		return -1;
	
	exit(-1);

	/* init environment */
	bd_data->need_exit = 1;
	need_exit = 1;

	/* create new threads */	
	res = pthread_create(&bd_data->gui_thread, NULL, gui_process, bd_data);
	if ( res ){
		TRACE(0, "[%s] Error; return code from pthread_create() is %d. errno: %s\n",
			__func__, res, strerror(errno) );
		goto destroy;
	}

	TRACE(0, "[%s] gui server thread successfully started\n", __func__);

	res = pthread_create(&bd_data->rs232_thread, NULL, rs232_process, bd_data);
	if ( res ){
		TRACE(0, "[%s] Error; return code from pthread_create() is %d. errno: %s\n",
			__func__, res, strerror(errno) );
		goto destroy;
	}
	
	TRACE(0, "[%s] rs232 dumper thread successfully started\n", __func__);

	/* FIXME improve it - wait for threads */
	while(need_exit) {
	}

	TRACE(0, "[%s] zero init\n", __func__);
	bd_data->need_exit = 0;

	/* we wait when threads are stop */
	res = pthread_cancel(bd_data->gui_thread);
	if ( res )
		TRACE(0, "[%s] Error. Cannot cancel the gui server thread, returned [%d]. errno: %s\n",
			__func__, res, strerror(errno) );

	res = pthread_join(bd_data->gui_thread, NULL);
	if ( res )
		TRACE(0, "[%s] Error. Cannot join to the gui server thread, returned [%d]. errno: %s\n",
			__func__, res, strerror(errno) );

	TRACE(0, "[%s] gui server thread successfully stopped\n", __func__);

	res = pthread_join(bd_data->rs232_thread, NULL);
	if ( res )
		TRACE(0, "[%s] Error. Cannot join rs232 dumper thread, returned [%d]. errno: %s\n",
			__func__, res, strerror(errno) );

	TRACE(0, "[%s] rs232 dumper thread successfully stopped\n", __func__);
	
	/* free memory and close all fd's */
destroy:
	board_daemon_destroy(bd_data);

	return 0;
}
