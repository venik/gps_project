#!/usr/bin/wish

####################################################################################3
#
# Description:  network module for Board-GUI
#
# Developer: Alex Nikiforov nikiforov.al [at] gmail.com
#
####################################################################################3

# Read a line of text from stdin and send it to the echoserver socket,
# on eof stdin closedown the echoserver client socket connection
# this implements sending a message to the Server.
proc read_stdin {wsock} {
	global  eventLoop

	set l [gets stdin]
		if {[eof stdin]} {
		close $wsock             ;# close the socket client connection
		set eventLoop "done"     ;# terminate the vwait (eventloop)
	} else {
		puts $wsock $l           ;# send the data to the server
	}
}

proc connection_cmd {rbt res} {

	#set server [$rbt.server_name_e get]
	#set port   [$rbt.server_port_e get]
	
	set server "localhost"
	set port   "1234"

	puts "connect to $server:$port"

	set state STATE_CONNECTION

	# Mega FSM on the text protocol
	while 1 {

		switch $state {

		STATE_CONNECTION {
			puts "STATE_CONNECTION"	
			if [catch {socket $server $port} serverSock] {
				tracep "connection failed on \[$server:$port\]. error: $serverSock"

				break;
			}

			tracep "connection successful on \[$server:$port\]"

			set state SAY_HELLO;
		}

		SAY_HELLO {
			puts "SAY_HELLO"	

			set comm "HELLO_GPS_BOARD v0.1"
			puts $serverSock $comm 
			flush $serverSock
			tracep "GUI => $comm"

			set response [gets $serverSock]
			if { [string match "ACK" $response] == 0 } {
				# Error handler
				tracep "ERROR: we expect ACK, but receive: \[$response\]"

				place forget $res.server
				$res.server configure -text "FAILED" -padx 1 -background red
				place $res.server -relx 0.5 -x -25 -rely 0.08

				set state FINISH_CONNECTION;

			} else {

				tracep "ACK <= $server:$port"
				tracep "RS232 dumper successfully identified"

				place forget $res.server
				$res.server configure -text "SUCCESSFUL" -padx 1 -background green 
				place $res.server -relx 0.5 -x -44 -rely 0.08

				set state SET_PORT;
			}
		}

		SET_PORT {
			puts "SET_PORT"	
			
			set port_string [$rbt.rs232_e get]
			set len [string length "$port_string"]
			puts $serverSock [format "RS232_PORT:%03d=$port_string" $len]
			flush $serverSock
			tracep "GUI => RS232_PORT:$len=$port_string"

			set response [gets $serverSock]
			if { [string match "ACK" $response] == 0 } {
				# Error handler
				tracep "ERROR: we expect ACK, but receive: \[$response\]"
				
				place forget $res.port
				$res.port configure -text "FAILED" -padx 1 -background red
				place $res.port -relx 0.5 -x -25 -rely 0.14

				set state FINISH_CONNECTION;

			} else {

				tracep "ACK <= $server:$port"
				tracep "RS232_PORT command succsessful, now COM-port is open"

				place forget $res.port
				$res.port configure -text "SUCCESSFUL" -padx 1 -background green 
				place $res.port -relx 0.5 -x -44 -rely 0.14

				set state TEST_RS232;
			}
		}

		TEST_RS232 {
			puts "TEST_RS232"	
			
			puts $serverSock "TEST_RS232"
			flush $serverSock
			tracep "GUI => TEST_RS232"
			
			set response [gets $serverSock]
			if { [string match "ACK" $response] == 0 } {
				# Error handler
				tracep "ERROR: we expect ACK, but receive: \[$response\]"
				
				place forget $res.rs232
				$res.rs232 configure -text "FAILED" -padx 1 -background red 
				place $res.rs232 -relx 0.5 -x -25 -rely 0.27

				set state FINISH_CONNECTION;

			} else {

				tracep "ACK <= $server:$port"
				tracep "RS232 port on board works fine"
	
				place forget $res.rs232
				$res.rs232 configure -text "OK" -padx 1 -background green 
				place $res.rs232 -relx 0.5 -x -15 -rely 0.27

				set state TEST_SRAM;
			}
		}

		TEST_SRAM {
			set comm "TEST_SRAM"

			puts $comm 
			puts $serverSock $comm 
			flush $serverSock
			tracep "GUI => $comm"
			
			set response [gets $serverSock]
			if { [string match "ACK" $response] == 0 } {
				# Error handler
				tracep "ERROR: we expect ACK, but receive: \[$response\]"
				
				place forget $res.mem
				$res.mem configure -text "FAILED" -padx 1 -background red 
				place $res.mem -relx 0.5 -x -25 -rely 0.32

				set state FINISH_CONNECTION;

			} else {

				tracep "ACK <= $server:$port"
				tracep "SRAM-chip on board works fine"
	
				place forget $res.mem
				$res.mem configure -text "OK" -padx 1 -background green 
				place $res.mem -relx 0.5 -x -15 -rely 0.32

				set state FINISH_CONNECTION;
			}
		}

		FINISH_CONNECTION {
			puts "FINISH_CONNECTION"
			close $serverSock
			break;
		}

		}

	}

}


