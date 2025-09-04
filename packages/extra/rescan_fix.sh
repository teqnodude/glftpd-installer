#!/bin/bash
VER=1.1
#--[ Intro ]--------------------------------------------------------
#                                                                   
# rescan_fix 1.1 by Teqno                                           
# It checks for lock files in pzs-ng dir and removes them íf found  
# and starts a rescan of the affected dirs to ensure releases are   
# complete and allows them to be completed if not.                  
#                                                                   
#--[ Installation ]-------------------------------------------------
#                                                                   
# Copy rescan_fix.sh to /glftpd/bin and chmod it to 755.            
#                                                                   
# Put this in crontab:                                              
# */2 * * * * /glftpd/bin/rescan_fix.sh >/dev/null 2>&1             
#                                                                   
#--[ Configuration ]------------------------------------------------

glroot=/glftpd                                  # path to glftpd folder
tmp=$glroot/tmp                                 # path to tmp folder
log=$glroot/ftp-data/logs/rescan_fix.log        # path to log file
minutes=5                                       # how old do the lock files need to be before they are removed

#--[ Script Start ]-------------------------------------------------

log()
{

    local ts
    ts=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$ts - $*"
    if [[ -n "$log" ]]
    then

        echo "$ts - $*" >> "$log"

    fi

}

if [[ -e "$tmp/rescan_fix.lock" ]]
then

    echo "Check already running"

else

    touch $tmp/rescan_fix.lock
    trap 'rm -f "$tmp/rescan_fix.lock"' EXIT

    check=$(find $glroot/ftp-data/pzs-ng -name *.lock -mmin +$minutes)

    if [[ -z "$check" ]]
    then

        echo "No lock files found"

    else

        echo "Looking for lock files older than $minutes minutes"
        log "Looking for lock files older than $minutes minutes"

        for result in $check
        do

            lock=$(echo $result | sed 's|.lock|*|')
            release=$(echo $result | sed 's|'"$glroot"'/ftp-data/pzs-ng||' | sed 's|headdata.lock||')

            echo "Removing -missing files from $glroot$release"
            log "Removing -missing files from $glroot$release"
            find "$glroot$release" -name "*-missing" -exec rm -rf {} +

            echo "Removing lock file from pzs-ng dir $glroot/ftp-data/pzs-ng$release"
            log "Removing lock file from pzs-ng dir $glroot/ftp-data/pzs-ng$release"
            rm -f $lock

            echo "Doing a rescan of dir to check if $glroot$release is complete"
            log "Doing a rescan of dir to check if $glroot$release is complete"
            $glroot/bin/rescan --chroot=$glroot --normal --dir=$release

            echo "Done"
            log "Done"

        done

    fi

fi
