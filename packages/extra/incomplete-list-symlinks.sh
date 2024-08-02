#!/bin/bash
VER=1.01
##############################
#
# Put in crontab * * * * *       /glftpd/bin/incomplete-list-symlinks.sh >/dev/null 2>&1
#
##############################

# enter path glftpd is installed in.
glroot=/glftpd

# enter path to the cleanup binary.
cleanup=$glroot/bin/cleanup

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

# create symlinks
create=1

# incomplete symlinks
incomplete=INCOMPLETES

# set this to one if you have sections in subdirs of one another - ie,
# if you have defined in $sections "A:/site/DIR" and "B:/site/DIR/SUBDIR"
no_strict=0

#############################
# END OF CONFIG             #
# ^^^^^^^^^^^^^             #
#############################

# grab sections from the sitebot's conf instead
if [ ! -z "$botconf" ] && [ -e "$botconf" ]
then
    sections="`grep "^set paths(" $botconf | sed 's/^set paths(\(.*\))[[:space:]]\{1,\}\"\(.*\)\*\"/\1:\2/'`"
fi

IFSORIG="$IFS"
IFS="
"

if [ "$create" = 1 ]
then
    if [ ! -e $glroot/site/$incomplete ]
    then
	mkdir $glroot/site/$incomplete
    fi
    rm -f $glroot/site/$incomplete/*
fi

for section in $sections
do
    secname="`echo "$section" | cut -d ':' -f 1`"
    secpaths="`echo "$section" | cut -d ':' -f 2- | tr ' ' '\n'`"
    for secpath in $secpaths
    do
	results="`$cleanup $glroot 2>/dev/null | grep -e "^Incomplete" | tr '\"' '\n' | grep -e "$secpath" | tr -s '/' | sort`"
	if [ ! -z "$results" ]
	then
    	    for result in $results
	    do
	        secrel=`echo $result | sed "s|$secpath||" | tr -s '/' | sed "s|$glroot||"`
	        comp="`ls -1 $result/ | grep "$releaseComplete"`"
    		percent="`echo $comp | awk -F " " '{print $3}'` complete"

	        if [ $percent != " complete" ]
		then
        	    percent="`echo $comp | awk -F " " '{print $3}'`"

        	    if [ $no_strict ] || [ "`dirname $secrel`/" = "`echo $secpath/ | tr -s '/'`" ]
		    then
        		echo "$secname: $secrel is $percent complete."
			if [ "$create" = 1 ]
			then
			    if [[ "$secrel" == *"/Subs"* ]]
			    then
				release=`echo $secrel | cut -d "/" -f1`
				subs=`echo $secrel | cut -d "/" -f2`
				ln -s ../$secname/$release/$subs $glroot/site/$incomplete/$release-$subs
				find $glroot/site/$secname/$release -type l -exec rm -f {} +
			    else
				if [[ "$secrel" == *"/"* ]]
				then
				    release=`echo $secrel | awk -F"/" '{print $NF}'`
				    ln -s ../$secname/$secrel $glroot/site/$incomplete/$release
				else
				    ln -s ../$secname/$secrel $glroot/site/$incomplete/$secrel
				fi
				find $glroot/site/$secname/$secrel -type l -exec rm -f {} +
			    fi
			fi
        	    fi
		    
    		else

        	    if [ $no_strict ] || [ "`dirname $secrel`/" = "`echo $secpath/ | tr -s '/'`" ]
		    then
        		echo "$secname: $secrel is either empty or missing a NFO."
			if [ "$create" = 1 ]
                        then
			    ln -s ../$secname/$secrel $glroot/site/$incomplete/$secrel
			    find $glroot/site/$secname/$secrel -type l -exec rm -f {} +
			fi
        	    fi
    		fi
    	    done
	fi
    done
done
echo "No more incompletes found."
IFS="$IFSORIG"
