#!/bin/bash

# Fix it for your COM-port
COM_PORT="/dev/ttyS0"
PRG_NAME="./rs232_ttool"

if [ -n $1 ]
then
	COMM=$1
else
	printf "you forgot about command. just ping without command\n"
	COMM="aa"
fi


$PRG_NAME -p $COM_PORT -c $COMM
