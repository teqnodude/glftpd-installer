#!/bin/bash
VER=1.1
#--[ Script Start ]---------------------------------------------#
#                                                               #
# Ircnick by Teqno                                              #
#                                                               #
# Let's you check what ircnick user has on site, only           #
# works for sites that require users to invite themselves into  #
# channels.                                                     #
#                                                               #
#--[ Settings ]-------------------------------------------------#

glroot=/glftpd
logfile=$glroot/ftp-data/logs/glftpd.log

#--[ Script Start ]---------------------------------------------#

trigger=`grep "bind pub" $glroot/sitebot/scripts/ircnick.tcl | cut -d " " -f4`

if [ -z "$1" ]
then
    echo "Syntax: $trigger username"
else
    if [ -z "`tac $logfile | grep -i "invite:" | grep -i $1`" ]
    then
        echo "User has not been invited into chans since "`head -2 $logfile | tail -1 | awk -F '[ :]+' '{print $2}''{print $3}''{print $7}'`
    else
        tac $logfile | grep -i "invite:" | grep -i $1 | head -1 | awk -F " " '{print $1" "$2" "$3" "$4" "$5" "$6" ircnick: "$7" username: "$8}'
    fi
fi

exit 0
