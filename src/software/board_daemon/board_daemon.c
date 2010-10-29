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
#include <poll.h>

#include <errno.h>

#include <pthread.h>

FILE 		*I;
int 		need_exit;
int 		need_flush_now;

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
	int 		i, res;

	TRACE(0, "[%s]\n", __func__);

	cfg_string_t cfg_vals[] = { 	{"addr0", ""},
					{"addr1", ""},
					{"addr2", ""},
					{"addr3", ""},
					{"addr4", ""},
					{"addr5", ""},
					{"addr6", ""},
					{"addr7", ""},
					{"addr8", ""},
					{"addr9", ""},
					{"gui_tcpport",  ""},		// 10
					{"rs232_portname",  ""},	// 11
					{"upload_script", ""},		// 12
					{"dump_type", ""},		// 13
					{"", ""}
				};

	cfg_parser = cfg_prepare(bd_data->cfg_name, cfg_vals);
	if( cfg_parser == NULL ) {
		return -1;
	}

	cfg_get_vals(cfg_parser) ;

	/* store args */
	for( i=0; i<10; i++) {
		res = sscanf(cfg_vals[i].val_str, "%llx", &bd_data->gps_regs[i].reg); ;
		if( res < 1 ) {
			TRACE(0, "Error. cannot parse/or it's empty [%s] value. register [%d]\n",
				cfg_vals[i].val_str, i);
			return -1;
		}

		hex2str(tmp_str, i);
		sprintf(bd_data->gps_regs[i].str, "# %sb 0x%08llx\n", tmp_str, bd_data->gps_regs[i].reg);
		TRACE(0, "Init reg [%d] with val [0x%07llx]\n", i, bd_data->gps_regs[i].reg);
	}

	bd_data->port = atoi(cfg_vals[10].val_str);
	if( bd_data->port == 0 ) {
		TRACE(0, "Warning. Cannot find/or parser [%s] token int the cfg-file Set default 1234 \n",
			cfg_vals[10].name );
		bd_data->port = 1234;
	}

	/* rs232_portname */
	res = strlen(cfg_vals[11].val_str);
	if( res == 0 ) {
		TRACE(0, "Error. You MUST declare rs232-port name in [%s] token in the cfg-file\n",
			cfg_vals[11].name);
		return -1;
	};

	res = access(cfg_vals[11].val_str, W_OK | R_OK);
	if( res != 0 ) {
		TRACE(0, "Error. rs232 port [%s] access fail. errno: %s \n",
			cfg_vals[11].val_str, strerror(errno));
		return -1;
	};
	strncpy(bd_data->name, cfg_vals[11].val_str, MAXLINE);
	
	/* upload_script */
	res = strlen(cfg_vals[12].val_str);
	if( res == 0 ) {
		TRACE(0, "Error. You MUST declare full path with the name of the the upload script in the [%s] \
				token in the cfg-file\n", cfg_vals[12].name);
		return -1;
	};
	
	res = access(cfg_vals[12].val_str, R_OK | X_OK);
	if( res != 0 ) {
		TRACE(0, "Error. Upload script [%s] failed. errno: %s \n",
			cfg_vals[12].val_str, strerror(errno));
		return -1;
	};
	strncpy(bd_data->upload_script, cfg_vals[12].val_str, MAXLINE);

	/* dump_type */
	res = strcmp(cfg_vals[13].val_str, "text");
	if( res == 0 ) {
	    /* text mode */
	    /* FIXME - check for GNNS type */
	    bd_data->bd_dump_cb = &rs232_dump_gps_text;
	} else {
	    bd_data->bd_dump_cb = &rs232_dump_gps_bin;
	};
	
	/* free memery after cfg-file parsing */
	cfg_destroy(cfg_parser);

	return 0;
}

int main(int argc, char **argv) {
	
	bd_data_t	*bd_data = (bd_data_t *)malloc(sizeof(bd_data_t));
	int 		res = 0;

	memset(bd_data, 0, sizeof(bd_data));

	/* FIXME - some constants, need implement it */
	I = stdout;

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
	
	/* init environment */
	bd_data->need_exit = 1;
	bd_data->need_flush_now = 0;
	need_exit = 1;

	/* create new threads */	
#if 1
	res = pthread_create(&bd_data->gui_thread, NULL, gui_process, bd_data);
	if ( res ){
		TRACE(0, "[%s] Error; return code from pthread_create() is %d. errno: %s\n",
			__func__, res, strerror(errno) );
		goto destroy;
	}
#endif

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
		/* FIXME - too late now, i need check it with the Board */
		if( need_flush_now == 1 ) {
			TRACE(0, "!!! Signal USR1 came, flush now\n");
			bd_data->need_flush_now = 1;
			need_flush_now = 0;
		}
	}

	TRACE(0, "[%s] zero init\n", __func__);
	bd_data->need_exit = 0;

	/* we wait when threads are stop */
	//res = pthread_cancel(bd_data->gui_thread);
	//if ( res )
	//	TRACE(0, "[%s] Error. Cannot cancel the gui server thread, returned [%d]. errno: %s\n",
	//		__func__, res, strerror(errno) );

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
