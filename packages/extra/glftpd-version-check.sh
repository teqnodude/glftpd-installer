#!/bin/bash
VER=1.1
#--[ Settings ]-------------------------------------------------#

glroot=/glftpd
gllog=$glroot/ftp-data/logs/glftpd.log

#--[ Script Start ]---------------------------------------------#

if [[ `curl -s https://glftpd.io | grep "/files/glftpd" | grep -v BETA | grep -o "glftpd-LNX.*.tgz" | head -1` == glftpd* ]]
then
    url="https://glftpd.io"
else
    if [[ `curl -s https://mirror.glftpd.nl.eu.org | grep "/files/glftpd" | grep -v BETA | grep -o "glftpd-LNX.*.tgz" | head -1` == glftpd* ]]
    then
        url="https://mirror.glftpd.nl.eu.org"
    else
        echo
        echo
        echo -e "\e[0;91mNo available website for glFTPd, aborting check.\e[0m"
        exit 1
    fi
fi

newversion=`lynx --dump $url | grep "latest version" | cut -d ":" -f2 | cut -d ' ' -f3 | sed 's/v//'`
curversion=`$glroot/bin/glftpd | grep glFTPd | cut -d ' ' -f2`


if [ "$newversion" != "$curversion" ]
then
    echo "New version available: $newversion"
    echo `date "+%a %b %e %T %Y"` GLVERSION: \"There is a new glFTPd version available: $newversion - Current version: $curversion - https://glftpd.io\" >> $gllog
else
    echo "Current non BETA version up to date"
fi

exit 0
