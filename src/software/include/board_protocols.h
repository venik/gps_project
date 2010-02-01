#ifndef __BOARD_PROTOCOL_
#define __BOARD_PROTOCOL_

/********************************************
 *	Binary protocol Board daemon <=> GPS-Board 
 ********************************************/
enum rs232_comm_request {
	
	RS232_SET_REG		= 0x01ull,
	RS232_TEST_SRAM		= 0x02ull,
	RS232_START_GPS		= 0x03ull,
	RS232_WRITE_BYTE	= 0x04ull,
	RS232_ZERO_MEM		= 0x05ull,
	RS232_DUMP_DATA		= 0x07ull,
	RS232_READ_BYTE		= 0x08ull,
	RS232_PING		= 0xAAull,
};

/*****************************************
 *	Text protocol GUI <=> Board_daemon 
 *****************************************/
char	gui_commands[][255] = 
{
	{"RS232_PORT:"},
	{"TEST_RS232"},
	{"TEST_SRAM"},
	{""}
};

#endif /* __BOARD_PROTOCOL_ */
