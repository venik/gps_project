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

	if [catch {socket $server $port} serverSock] {
		tracep "connection failed on \[$server:$port\]. error: $serverSock"
	} else {
		tracep "connection successful on \[$server:$port\]"

		# configure channel modes
		# ensure the socket is line buffered so we can get a line of text 
		# at a time (Cos thats what the server expects)...
		# Depending on your needs you may also want this unbuffered so 
		# you don't block in reading a chunk larger than has been fed 
		#  into the socket
		# i.e fconfigure $esvrSock -blocking off
		fconfigure $serverSock -buffering line

		# Setup monitoring on the socket so that when there is data to be 
		# read the proc "read_sock" is called
		#fileevent $serverSock readable [list read_sock $serverSock $server $port]
		#fileevent $serverSock writable [list write_sock $serverSock "HELLO_GPS_BOARD"]
		write_sock $serverSock "HELLO_GPS_BOARD"
		read_sock $serverSock $server $port

		# this is a synchronous connection: 
		# The command does not return until the server responds to the 
		#  connection request

		#if {[eof $esvrSock]} { # connection closed .. abort }



		# wait for and handle either socket or stdin events...
		#vwait eventLoop

		puts "Client Finished"

	}

}


