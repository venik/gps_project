#ifndef _RS232_DUMPER_H
#define _RS232_DUMPER_H

#include <poll.h>

#define MAXLINE		255
#define BUF_SIZE	1024*1024	// 1 Mb
#define TIMEOUT		3000		// 3 sec

/* commands */
#define CONNECTION_CMD	"HELLO_GPS_BOARD\r\n"
#define SET_PORT_CMD	"RS232_PORT:"
#define TEST_RS232_CMD	"TEST_RS232\r\n"
#define TEST_SRAM_CMD	"TEST_SRAM\r\n"
#define ACK		"ACK\r\n"
#define ERR 		"ERR: UNKNOWN COMMAND\r\n"

FILE 		*I;

enum rs232_fsm_state {
	BREAK,			/* exit from cycle */
	CONNECTION,
	WAIT_FOR_HELLO,
	SET_PORT,
	TEST_RS232,
	TEST_SRAM	
};

enum rs232_comm_request {
	RS232_SET_REG		= 1<<0,
	RS232_TEST_SRAM		= 1<<1,
	RS232_GPS_START		= 1<<2,
	RS232_TEST_RS232	= 0xAA 
};

typedef struct rs232_data_s {

	char		name[MAXLINE];
	uint8_t 	recv_buf[BUF_SIZE];
	uint8_t 	send_buf[BUF_SIZE];

	/* network part */
	struct pollfd	client[3];
	uint16_t	port;

} rs232_data_t;

static void rs232_fsm_say_err(rs232_data_t *rs232data);
static void rs232_fsm_say_err_errno(rs232_data_t *rs232data, char *str);

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

#endif /* _RS232_DUMPER_H */
