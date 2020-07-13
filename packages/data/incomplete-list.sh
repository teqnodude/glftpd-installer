#!/bin/bash


##############################
# CONFIG                     #
# ^^^^^^                     #
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

# set this to 1 if you wish to announce sections where no incompletes are found.
verbose=0

# set this to one if you have sections in subdirs of one another - ie,
# if you have defined in $sections "A:/site/DIR" and "B:/site/DIR/SUBDIR"
no_strict=0

bold=
dgry=14
lred=4

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

for section in $sections
do
	secname="`echo "$section" | cut -d ':' -f 1`"
	secpaths="`echo "$section" | cut -d ':' -f 2- | tr ' ' '\n'`"

	for secpath in $secpaths
	do
		results="`$cleanup $glroot 2>/dev/null | grep -e "^Incomplete" | tr '\"' '\n' | grep -e "$secpath" | tr -s '/' | sort`"
	
		if [ -z "$results" ]
		then

			if [ $verbose -eq 1 ]
			then
				echo "$secname: No incomplete releases found."
			fi
	
		else
	
		for result in $results
		do
			#secrel=`echo $result | sed "s|$secpath||" | tr -s '/'`
			secrel=`echo $result | sed "s|$secpath||" | tr -s '/' | sed "s|$glroot||"`
			#comp="`ls -1 $glroot$result/ | grep "$releaseComplete"`"
			comp="`ls -1 $result/ | grep "$releaseComplete"`"
			percent="`echo $comp | awk -F " " '{print $3}'` complete"

			if [ $percent != " complete" ]
			then
				percent="`echo $comp | awk -F " " '{print $3}'`"
	
				if [ $no_strict ] || [ "`dirname $secrel`/" = "`echo $secpath/ | tr -s '/'`" ]
				then
					echo "$secname:${lred} ${secrel}${dgry} is${lred} $percent ${dgry}complete."
				fi
	
			else
	
				if [ $no_strict ] || [ "`dirname $secrel`/" = "`echo $secpath/ | tr -s '/'`" ]
				then
					echo "$secname:${lred} ${secrel}${dgry} is missing a NFO."
				fi
	
			fi
			
		done
		
		fi
		
	done
	
done
echo "No more incompletes found."
IFS="$IFSORIG"

exit 0
