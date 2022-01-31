#!/bin/bash
VER=1.0
##############################
# CONFIG                     #
# ^^^^^^                     #
##############################

# enter path glftpd is installed in.
glroot=/glftpd

# enter path to the cleanup binary relative to glroot.
cleanup=/bin/cleanup

# enter path to the nuker binary
nukeprog=$glroot/bin/nuker

# enter the username which will be used to nuke
nukeuser=glftpd

# enter the reason for the nuke
reason="-Auto- Not completed for 12 hours."

# enter the multiplier for the nuke
multiplier=5

# enter the path to glftpd.conf
glconf=$glroot/etc/glftpd.conf

# date format for log file
now="$( date +%Y-%m-%d" "%H:%M:%S )"

# minutes old for nuke to occur
minutes=720

# nuke release even if it's just the nfo that is missing
nonfo=0

# path to log file
log=$glroot/ftp-data/logs/incomplete-list-nuker.log

# enter sections in the following format:
# <announce name of section>:<path to section, including a terminating slash ``/''
# spaces and newline separates.
#sections="
#0DAY:/site/incoming/0day/
#GAMES:/site/incoming/games/
#APPS:/site/incoming/apps/
#MV:/site/incoming/musicvideos/
#"

# alternative, set the following variable to point to your dZSbot.conf and
# uncomment the ''botconf='' directive below.
botconf=/glftpd/sitebot/scripts/pzs-ng/ngBot.conf

# Set this to your complete line (non-dynamic part)
releaseComplete="Complete -"

# set this to one if you have sections in subdirs of one another - ie,
# if you have defined in $sections "A:/site/DIR" and "B:/site/DIR/SUBDIR"
no_strict=0

#############################
# END OF CONFIG             #
# ^^^^^^^^^^^^^             #
#############################

if [ "`find \"$glroot/tmp/incomplete-list-nuker.lock\" -type f -mmin +20`" ] ; then rm -f $glroot/tmp/incomplete-list-nuker.lock ; fi
if [ -e "$glroot/tmp/incomplete-list-nuker.lock" ]
then
    echo "Check already running"
else
    touch $glroot/tmp/incomplete-list-nuker.lock
    # grab sections from the sitebot's conf instead
    if [ ! -z "$botconf" ] && [ -e "$botconf" ]
    then
	sections="`grep "^set paths(" $botconf | sed 's/^set paths(\(.*\))[[:space:]]\{1,\}\"\(.*\)\*\"/\1:\2/'`"
    fi
    IFSORIG="$IFS"
    IFS="
    "
    for section in $sections
    do
	secname="`echo "$section" | cut -d ':' -f 1`"
	secpaths="`echo "$section" | cut -d ':' -f 2- | tr ' ' '\n'`"
	for secpath in $secpaths
	do
    	    results="`chroot $glroot $cleanup 2>/dev/null | grep -e "^Incomplete" | tr '\"' '\n' | grep -e "$secpath" | grep -v "\/Sample\|\/Subs" | tr -s '/' | sort`"
    	    if [ ! -z "$results" ]
	    then
		for result in $results
		do
		    secrel=`echo $result | sed "s|$secpath||" | tr -s '/'`
		    comp="`ls -1 $glroot$result/ | grep "$releaseComplete"`"
		    percent="`echo $comp | awk -F " " '{print $3}'` complete"
		    if [ "$percent" != " complete" ]
		    then
		    	percent="`echo $comp | awk -F " " '{print $3}'`"
			if [ $no_strict ] || [ "`dirname $secrel`/" = "`echo $secpath/ | tr -s '/'`" ]
			then
			    echo "$secname: ${secrel} is $percent complete."
    			    if [ "$secname" = "0DAY" ] || [ "$secname" = "MP3" ] || [ "$secname" = "FLAC" ] || [ "$secname" = "EBOOKS" ] || [ "$secname" = "XXX-PAYSITE" ]
			    then
                            	release=`echo $secrel | awk -F "/" '{print $2}'`
		                day=`echo $secrel | awk -F "/" '{print $1}'`
				if [ $(find $glroot/site/$secname/$secrel -maxdepth 0 -type f -iname "Approved_by*" | wc -l) == "0" ]
				then
				    find $glroot/site/$secname/$day -maxdepth 1 -mmin +$minutes -type d -name $release -exec echo $now - Nuking incomplete release $release in section $secname >> $log ';'
				    find $glroot/site/$secname/$day -maxdepth 1 -mmin +$minutes -type d -name $release -exec $nukeprog -r $glconf -N $nukeuser -n /site/$secname/$day/$release $multiplier $reason ';'
				fi
			    else
				if [ $(find $glroot/site/$secname/$secrel -maxdepth 0 -type f -iname "Approved_by*" | wc -l) == "0" ]
				then
				    find $glroot/site/$secname -maxdepth 1 -mmin +$minutes -type d -name $secrel -exec echo $now - Nuking incomplete release $secrel in section $secname >> $log ';'
				    find $glroot/site/$secname -maxdepth 1 -mmin +$minutes -type d -name $secrel -exec $nukeprog -r $glconf -N $nukeuser -n /site/$secname/$secrel $multiplier $reason ';'
				fi
			    fi
			fi
		    else
			if [ $no_strict ] || [ "`dirname $secrel`/" = "`echo $secpath/ | tr -s '/'`" ]
			then
			    [ "$nonfo" = 0 ] && echo "$secname: ${secrel} is either empty or missing a NFO."
			    if [ "$nonfo" = 1 ]
			    then
    				if [ "$secname" = "0DAY" ] || [ "$secname" = "MP3" ] || [ "$secname" = "FLAC" ] || [ "$secname" = "EBOOKS" ] || [ "$secname" = "XXX-PAYSITE" ]
				then
                            	    release=`echo $secrel | awk -F "/" '{print $2}'`
		            	    day=`echo $secrel | awk -F "/" '{print $1}'`
				    if [ $(find $glroot/site/$secname/$secrel -maxdepth 0 -type f -iname "Approved_by*" | wc -l) == "0" ]
				    then
					find $glroot/site/$secname/$day -maxdepth 1 -mmin +$minutes -type d -name $release -exec echo $now - Nuking incomplete release $release in section $secname >> $log ';'
					find $glroot/site/$secname/$day -maxdepth 1 -mmin +$minutes -type d -name $release -exec $nukeprog -r $glconf -N $nukeuser -n /site/$secname/$day/$release $multiplier $reason ';'
				    fi
				else
				    if [ $(find $glroot/site/$secname/$secrel -maxdepth 0 -type f -iname "Approved_by*" | wc -l) == "0" ]
				    then
					find $glroot/site/$secname -maxdepth 1 -mmin +$minutes -type d -name $secrel -exec echo $now - Nuking incomplete release $secrel in section $secname >> $log ';'
					find $glroot/site/$secname -maxdepth 1 -mmin +$minutes -type d -name $secrel -exec $nukeprog -r $glconf -N $nukeuser -n /site/$secname/$secrel $multiplier $reason ';'
				    fi
				fi
			    fi
			fi
		    fi
		done
	    fi
	done
    done
    echo "No more incompletes found."
    IFS="$IFSORIG"
    rm -f $glroot/tmp/incomplete-list-nuker.lock
fi

exit 0
