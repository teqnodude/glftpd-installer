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

logfile=/glftpd/ftp-data/logs/glftpd.log

#--[ Script Start ]---------------------------------------------#

if [ -z "$1" ]
then
        echo "Syntax: !ircnick username"
else
        if [ -z "`tac $logfile | grep -i "invite:" | grep -i $1`" ]
        then
                echo "User has not been invited into chans since "`cat $logfile | head -n2 | tail -n1 | awk -F '[ :]+' '{print $2}''{print $3}''{print $7}'`
        else
                tac $logfile | grep -i "invite:" | grep -i $1 | head -1 | awk -F " " '{print $1" "$2" "$3" "$4" "$5" "$6" ircnick: "$7" username: "$8}'
        fi
fi

exit 0
