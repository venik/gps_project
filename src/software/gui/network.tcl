#!/usr/bin/wish

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

# Read data from a channel (the server socket) and put it to stdout
# this implements receiving and handling (viewing) a server reply 
proc read_sock {sock server port} {
	set l [gets $sock]
	tracep "$l <= $server:$port"
}

proc write_sock {sock msg} {
	tracep "GUI => $msg"
	puts $sock $msg
}

#proc connection_cmd {server port} {
proc connection_cmd {} {
	set server "localhost"
	set port "1234"

	set state STATE_CONNECTION

	# Mega FSM on the text protocol
	while 1 {

		switch $state {

		STATE_CONNECTION {
			if [catch {socket $server $port} serverSock] {
				tracep "connection failed on \[$server:$port\]. error: $serverSock"
				break;
			}

			tracep "connection successful on \[$server:$port\]"
			set state SAY_HELLO;
		}

		SAY_HELLO {
			puts $serverSock "HELLO_GPS_BOARD"
			flush $serverSock
			tracep "GUI => HELLO_GPS_BOARD"

			set response [gets $serverSock]
			if { [string match "ACK" $response] == 0 } {
				# Error handler
				tracep "ERROR: we expect ACK, but receive $response"
				close $serverSock

				break;
			}

			tracep "ACK <= $server:$port"
			tracep "RS232 dumper successfully identified"

			set state SET_PORT;
			break;
		}

		SET_PORT {
			puts "yohohoh"	
			set state FINISH_CONNECTION;
		}

		FINISH_CONNECTION {
			puts "Client Finished"
			close $serverSock
			break;
		}

		}

	}

}


