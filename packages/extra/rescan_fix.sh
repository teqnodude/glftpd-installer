#!/bin/bash
VER=1.01
#--[ Intro ]--------------------------------------------------------#
#                                                                   #
# rescan_fix 1.0 by Teqno                                           #
# It checks for lock files in pzs-ng dir and removes them íf found  #
# and starts a rescan of the affected dirs to ensure releases are   #
# complete and allows them to be completed if not.                  #
#                                                                   #
#--[ Installation ]-------------------------------------------------#
#                                                                   #
# Copy rescan_fix.sh to /glftpd/bin and chmod it to 755.            #
#                                                                   #
# Put this in crontab:                                              #
# */2 * * * * /glftpd/bin/rescan_fix.sh >/dev/null 2>&1             #
#                                                                   #
#--[ Configuration ]------------------------------------------------#

glroot=/glftpd                                  # path to glftpd folder
tmp=$glroot/tmp                                 # path to tmp folder
log=$glroot/ftp-data/logs/rescan_fix.log        # path to log file
minutes=5                                       # how old do the lock files need to be before they are removed

#--[ Script Start ]-------------------------------------------------#

if [ -e "$tmp/rescan_fix.lock" ]
then

    echo "Check already running"

else
    touch $tmp/rescan_fix.lock
    check=`find $glroot/ftp-data/pzs-ng -name *.lock -mmin +$minutes`
    
    if [ -z "$check" ]
    then

        echo "No lock files found"

    else
        echo "`date +%Y-%m-%d" "%H:%M:%S` - Looking for lock files older than $minutes minutes"
        echo "`date +%Y-%m-%d" "%H:%M:%S` - Looking for lock files older than $minutes minutes" >> $log
        for result in $check
        do
            lock=`echo $result | sed 's|.lock|*|'`
            release=`echo $result | sed 's|'"$glroot"'/ftp-data/pzs-ng||' | sed 's|headdata.lock||'`
            echo "`date +%Y-%m-%d" "%H:%M:%S` - Removing -missing files from $glroot$release"
            echo "`date +%Y-%m-%d" "%H:%M:%S` - Removing -missing files from $glroot$release" >> $log
            find "$glroot$release" -name "*-missing" -exec rm -rf {} +

            echo "`date +%Y-%m-%d" "%H:%M:%S` - Removing lock file from pzs-ng dir $glroot/ftp-data/pzs-ng$release"
            echo "`date +%Y-%m-%d" "%H:%M:%S` - Removing lock file from pzs-ng dir $glroot/ftp-data/pzs-ng$release" >> $log
            rm -f $lock

            echo "`date +%Y-%m-%d" "%H:%M:%S` - Doing a rescan of dir to check if $glroot$release is complete"
            echo "`date +%Y-%m-%d" "%H:%M:%S` - Doing a rescan of dir to check if $glroot$release is complete" >> $log
            $glroot/bin/rescan --chroot=$glroot --normal --dir=$release

            echo "`date +%Y-%m-%d" "%H:%M:%S` - Done"
            echo "`date +%Y-%m-%d" "%H:%M:%S` - Done" >> $log

        done

    fi

    rm -f $tmp/rescan_fix.lock

fi

exit 0
