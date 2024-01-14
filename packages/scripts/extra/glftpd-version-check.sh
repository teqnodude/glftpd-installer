#!/bin/bash
VER=1.0
#--[ Settings ]-------------------------------------------------#

gllog=/glftpd/ftp-data/logs/glftpd.log

#--[ Script Start ]---------------------------------------------#

newversion=`lynx --dump https://glftpd.io | grep "latest version" | cut -d ":" -f2 | cut -d ' ' -f3 | sed 's/v//'`
curversion=`/glftpd/bin/glftpd | grep glFTPd | cut -d ' ' -f2`

if [ "$newversion" != "$curversion" ]
then
    echo "New version available: $newversion"
    echo `date "+%a %b %e %T %Y"` GLVERSION: \"There is a new glFTPd version available: $newversion - Current version: $curversion - https://glftpd.io\" >> $gllog
else
    echo "Current non BETA version up to date"
fi

exit 0
