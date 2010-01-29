#!/bin/bash

# format start comm cfg 

# Fix it for your COM-port
COM_PORT="/dev/ttyUSB0"
PRG_NAME="./rs232_ttool"

if [ -n $1 ]
then
	COMM=$1
else
	printf "you forgot about command. just ping without command\n"
	COMM="aa"
fi

if [ -n $2 ]
then
	CFG_NAME=$2
else
	printf "use the default cfg\n"
	CFG_NAME="default_cfg"
fi

$PRG_NAME -p $COM_PORT -c $COMM -f $CFG_NAME
