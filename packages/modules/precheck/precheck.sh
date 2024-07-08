#!/bin/bash
VER=1.1
#---------------------------------------------------------------#
# Precheck by Teqno                                             #
#                                                               #
# Adds !precheck cmd to irc, to search for a group's pre's      #
# on site. Just copy the precheck.sh in to /glftpd/bin and put  #
# the tcl in your sitebot/scripts dir. Then put this line in to #
# your eggdrop.conf                                             #
#                                                               #
# source scripts/precheck.tcl                                   #
#                                                               #
# Rehash the bot and your good to go                            #
#                                                               #
# Do !precheck <GROUPNAME> to check for their pre's             #
#                                                               #
#--[ Settings ]-------------------------------------------------#

glroot=/glftpd
glftpd=$glroot/ftp-data/logs/glftpd.log
precheck=$glroot/ftp-data/logs/precheck.log

#--[ Script Start ]---------------------------------------------#
# Don't change anything below this line

trigger=`grep "bind pub" $glroot/sitebot/scripts/precheck.tcl | cut -d " " -f4`

if [ "$1" = "" ]
then
    echo "Syntax: $trigger groupname"
else
    if [ ! -e "$precheck" ]
    then
	touch $precheck && chmod 666 $precheck
    fi

    if [ ! -w "$precheck" ]
    then
    	chmod 666 $precheck
    fi

    grep "PRE:" $glftpd | grep -n -i "\-$1\"" > $precheck

    if [ -s "$precheck" ]
    then
	echo "The group $1 have preed a total of `tail -1 $precheck | awk -F '[ \t]+' '{print $2}'` times since "`head -2 $glftpd | tail -1 | awk -F '[ :]+' '{print $2}''{print $3}''{print $7}'`
	echo " "
	echo "Last Pre : " `tail -1 $precheck | awk -F '[ /]+' '{print $2}''{print $3}''{print $5}'`
	echo "Time :  " `tail -1 $precheck | awk -F '[ /]+' '{print $4}'`
	echo "Pre : " `tail -1 $precheck | awk -F '[ :]+' '{print $10}' | sed 's/\/site\///'`
	echo " "
	echo "Last 5 Releases are :"
	tail -5 $precheck | sed '1!G;h;$!d' | awk -F '[ :]+' '{print $3" "$4" "$5":"$6":"$7" "$8" "$10}' | sed 's/\/site\///'
	> $precheck
    else
	echo "The group $1 have not preed since logfile date "`head -2 $glftpd | tail -1 | awk -F '[ :]+' '{print $2}''{print $3}''{print $7}'`
    fi
fi

exit 0

