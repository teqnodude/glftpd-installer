#!/bin/bash
VER=1.0
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

glpath=/glftpd/ftp-data/logs/glftpd.log
log=/glftpd/ftp-data/logs/precheck.log

#--[ Script Start ]---------------------------------------------#
# Don't change anything below this line

if [ "$1" = "" ]
then
	echo "You need to specify a group"
else
	if [ ! -e "$log" ]
	then
		touch $log && chmod 666 $log
	fi

	if [ ! -w "$log" ]
	then
		chmod 666 $log
	fi

	cat $glpath | grep "PRE:" | grep -n -i "\-$1\"" > $log

	if [ -s "$log" ]
	then
		echo "The group $1 have preed a total of `cat -n $log | tail -n1 | awk -F '[ \t]+' '{print $2}'` times since "`cat $glpath | head -n2 | tail -n1 | awk -F '[ :]+' '{print $2}''{print $3}''{print $7}'`
		echo " "
		echo "Last Pre : " `cat $log | tail -n 1 | awk -F '[ /]+' '{print $2}''{print $3}''{print $5}'`
		echo "Time :  " `cat $log | tail -n 1 | awk -F '[ /]+' '{print $4}'`
		echo "Pre : " `cat $log | tail -n 1 | awk -F '[ :]+' '{print $10}' | sed 's/\/site\///'`
		echo " "
		echo "Last 5 Releases are :"
		cat $log | tail -n 5 | sed '1!G;h;$!d' | awk -F '[ :]+' '{print $3" "$4" "$5":"$6":"$7" "$8" "$10}' | sed 's/\/site\///'
		cat /dev/null > $log
	else
		echo "The group $1 have not preed since logfile date "`cat $glpath | head -n2 | tail -n1 | awk -F '[ :]+' '{print $2}''{print $3}''{print $7}'`
        fi
fi

exit 0

