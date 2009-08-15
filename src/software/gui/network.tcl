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

proc connection_cmd {rbt res} {

	set server [$rbt.server_name_e get]
	set port   [$rbt.server_port_e get]
	
	puts "connect to $server:$port"

	set state STATE_CONNECTION

	# Mega FSM on the text protocol
	while 1 {

		switch $state {

		STATE_CONNECTION {
			if [catch {socket $server $port} serverSock] {
				tracep "connection failed on \[$server:$port\]. error: $serverSock"

				place forget $res.server
				$res.server configure -text "FAILED" -padx 1 -background red
				place $res.server -relx 0.5 -x -25 -rely 0.08

				break;
			}

			tracep "connection successful on \[$server:$port\]"

			place forget $res.server
			$res.server configure -text "SUCCESSFUL" -padx 1 -background green 
			place $res.server -relx 0.5 -x -44 -rely 0.08

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
				set state FINISH_CONNECTION;

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


