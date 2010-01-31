#!/bin/bash

echo "GPS-Board store script"

# Constants
FTP_HOST="ftp.sample.ru"
FTP_DIR="/target/dir"
FTP_LOGIN="login"
FTP_PASSWORD="pass"

# Make new .netrc 
cp -p ~/.netrc ~/.netrc_old 2>/dev/null
printf "machine $FTP_HOST\n" > ~/.netrc
printf "\tlogin $FTP_LOGIN\n" >> ~/.netrc
printf "\tpassword $FTP_PASSWORD\n" >> ~/.netrc
chmod 600 ~/.netrc

# Begin ftp transaction 
ftp <<**
open $FTP_HOST
cd $FTP_DIR
put flush
bye
**

# Restore .netrc
cp -p ~/.netrc_old ~/.netrc 2>/dev/null

echo "ftp transfer ended"
