#!/bin/bash
VER=1.4
#--[ Info ]-----------------------------------------------------#
#
# This script comes without any warranty, use it at your own risk.
#
# If you want to rescan your tv releases for TVMaze info then 
# this script is for you. It grabs info from TVMaze api and
# creates an .imdb file and tag file in each release with it.
# 
# Changelog
# 2021-03-25 : v1.4 Code for airdate was not properly set
# 2021-03-03 : v1.3 Added option for maximum width for plot summary
#                   and added skip option for releases that already have a .imdb file
# 2021-03-02 : v1.2 Now you can scan up to 3 dirs in depth and
#                   I've also included a check to only scan TV releases that match 
#                   set regex. Made some cosmetic changes too and included a check
#                   to prevent double instances of script.
# 2021-03-01 : v1.1 Fixed releases with year and country code
# 2021-02-28 : v1.0 Teqno original creator
#
#--[ Settings ]-------------------------------------------------#

# Location of glftpd
glroot=/glftpd

# Tmp folder under $glroot
tmp=/tmp

# Recommended to run in debug mode before running, set to 0 to disable.
debug=0

# Set sections that should be scanned. 
# Examples: 
# /site/section: <- rescan /site/section
# /site/section:1x <- rescan /site/section/subdir
# /site/section:2x <- rescan /site/section/subdir/subdir2
# /site/seciton:3x <- rescan /site/section/subdir/subdir2/subdir3
# 
sections="
/site/TV-HD:
/site/ARCHIVE1/TV/TV-HD/Showname:1x
/site/ARCHIVE2/TV/TV-HD:2x
/site/ARCHIVE3/TV:3x
"

# What to exclude from scanner
exclude="^\[NUKED\]-|^\[incomplete\]-|^\[no-nfo\]-|^\[no-sample\]-"

# Do you want to preserve date & time on scanned releases
preserve=1

# Maximum width for text written to .imdb
width=77

# Do you want to skip releases that already got a .imdb file
skip=0

#--[ Script Start ]---------------------------------------------#

if [ -e "$glroot$tmp/tvmaze-rescan.lock" ]
then
    if [ "`find \"$glroot$tmp/tvmaze-rescan.lock\" -type f -mmin -1440`" ]
    then
	echo "Lockfile $glroot$tmp/tvmaze-rescan.lock exists and is not 24 hours old yet. Quitting."
	exit 0
    else
        echo "Lockfile exists, but its older then 24 hours. Removing lockfile."
	touch "$glroot$tmp/tvmaze-rescan.lock"
    fi
else
     touch "$glroot$tmp/tvmaze-rescan.lock"
fi

i=1

function rescan {

    for rls_name in `ls $1 | egrep -v "$exclude"`
    do
	if [ -z `echo $rls_name | egrep -o ".*.S[0-9][0-9]E[0-9][0-9].|.*.E[0-9][0-9].|.*.[0-9][0-9][0-9][0-9].[0-9][0-9].[0-9][0-9].|.*.Part.[0-9]."` ]
	then
	    continue
	fi
	if [ "$skip" -eq 1 ] && [ -e "$1/$rls_name/.imdb" ]
	then
	    continue
	fi
	SHOW=`echo $rls_name | egrep -o ".*.S[0-9][0-9]E[0-9][0-9].|.*.E[0-9][0-9].|.*.[0-9][0-9][0-9][0-9].[0-9][0-9].[0-9][0-9].|.*.Part.[0-9]." | sed -e 's|.S[0-9][0-9].*||' -e 's|.Part.*||' -e 's|[0-9][0-9][0-9][0-9].[0-9][0-9].[0-9][0-9].*||' -e 's|.[0-9][0-9][0-9][0-9].*||' -e 's|.AU.*||' -e 's|.CA.*||' -e 's|.NZ.*||' -e 's|.UK.*||' -e 's|.US.*||' | tr '.' ' '`
	lynx --dump "https://api.tvmaze.com/singlesearch/shows?q=$SHOW" | sed -e 's|","|"#"|g' -e 's|],"|]#"|g' -e 's|},"|}#"|g' -e 's|",|"#|g' -e 's|,"|#"|g' | tr '#' '\n' > $glroot$tmp/tvmaze-rescan.tmp
	SHOW_ID=`cat $glroot$tmp/tvmaze-rescan.tmp | grep 'id":' | head -1 | cut -d':' -f2 | tr -d '"'`
	SHOW_NAME=`cat $glroot$tmp/tvmaze-rescan.tmp | grep 'name":' | head -1 | cut -d':' -f2 | tr -d '"'`
	SHOW_GENRES=`cat $glroot$tmp/tvmaze-rescan.tmp | grep 'genres":' | sed -n '/"genres"/,/]/p' | tr '\n' ' ' | tr -d '[' | tr -d ']' | sed 's/"genres"://' | tr -d '"'`
	SHOW_COUNTRY=`cat $glroot$tmp/tvmaze-rescan.tmp | grep 'country":' | head -1 | cut -d':' -f3 | tr -d '"'`
	SHOW_LANGUAGE=`cat $glroot$tmp/tvmaze-rescan.tmp | grep 'language":' | head -1 | cut -d':' -f2 | tr -d '"'`
	SHOW_NETWORK=`cat $glroot$tmp/tvmaze-rescan.tmp | grep 'name":' | head -2 | tail -1 | cut -d':' -f2 | tr -d '"'`
	SHOW_PREMIERED=`cat $glroot$tmp/tvmaze-rescan.tmp | grep 'premiered":' | head -1 | cut -d':' -f2 | tr -d '"' | sed 's/-.*//g'`
	SHOW_STATUS=`cat $glroot$tmp/tvmaze-rescan.tmp | grep 'status":' | head -1 | cut -d':' -f2 | tr -d '"'`
	SHOW_TYPE=`cat $glroot$tmp/tvmaze-rescan.tmp | grep 'type":' | head -1 | cut -d':' -f2 | tr -d '"'`
	SHOW_RATING=`cat $glroot$tmp/tvmaze-rescan.tmp | grep 'rating":' | head -1 | cut -d':' -f3 | tr -d '"' | tr -d '}'`
	SHOW_IMDB=`cat $glroot$tmp/tvmaze-rescan.tmp | grep 'imdb":' | head -1 | cut -d':' -f2 | tr -d '"' | tr -d '}'`
	SHOW_URL=`cat $glroot$tmp/tvmaze-rescan.tmp | grep 'url":' | head -1 | cut -d':' -f2- | tr -d '"' | tr -d '}'`
	SHOW_SUMMARY=`cat $glroot$tmp/tvmaze-rescan.tmp | grep 'summary":' | head -1 | cut -d':' -f2 | tr -d '"' | tr -d '\\\' | sed 's|<*.[b|i|p]>||g'`

	if [ `echo $rls_name | egrep -o "S[0-9][0-9]E[0-9][0-9]"` ]
	then
	    SEASON=`echo $rls_name | egrep -o "S[0-9][0-9]" | tr -d 'S'`
	    EPISODE=`echo $rls_name | egrep -o "E[0-9][0-9]" | tr -d 'E'`
	    lynx --dump "https://api.tvmaze.com/shows/$SHOW_ID/episodebynumber?season=$SEASON&number=$EPISODE" | sed -e 's|","|"#"|g' -e 's|],"|]#"|g' -e 's|},"|}#"|g' -e 's|",|"#|g' -e 's|,"|#"|g' | tr '#' '\n' > $glroot$tmp/tvmaze-rescan.tmp
	    EP_URL=`cat $glroot$tmp/tvmaze-rescan.tmp | grep 'url":' | head -1 | cut -d':' -f2- | tr -d '"' | tr -d '}'`
	    EP_AIR_DATE=`cat $glroot$tmp/tvmaze-rescan.tmp | grep 'airdate":' | head -1 | cut -d':' -f2 | tr -d '"'`
	fi
	if [ `echo $rls_name | egrep -o "[0-9][0-9][0-9][0-9].[0-9][0-9].[0-9][0-9]"` ]
	then
	    DATE=`echo $rls_name | egrep -o "[0-9][0-9][0-9][0-9].[0-9][0-9].[0-9][0-9]" | tr '.' '-'`
	    lynx --dump "https://api.tvmaze.com/shows/$SHOW_ID/episodesbydate?date=$DATE" | sed -e 's|","|"#"|g' -e 's|],"|]#"|g' -e 's|},"|}#"|g' -e 's|",|"#|g' -e 's|,"|#"|g' | tr '#' '\n' > $glroot$tmp/tvmaze-rescan.tmp
	    EP_URL=`cat $glroot$tmp/tvmaze-rescan.tmp | grep 'url":' | head -1 | cut -d':' -f2- | tr -d '"' | tr -d '}'`
	    EP_AIR_DATE=`cat $glroot$tmp/tvmaze-rescan.tmp | grep 'airdate":' | head -1 | cut -d':' -f2 | tr -d '"'`
	fi
	if [ `echo $rls_name | egrep -o "Part.[0-9]"` ]
	then
	    SEASON=1
	    EPISODE=`echo $rls_name | grep -o "Part.[0-9]" | grep -o "[0-9]"`
	    lynx --dump "https://api.tvmaze.com/shows/$SHOW_ID/episodebynumber?season=$SEASON&number=$EPISODE" | sed -e 's|","|"#"|g' -e 's|],"|]#"|g' -e 's|},"|}#"|g' -e 's|",|"#|g' -e 's|,"|#"|g' | tr '#' '\n' > $glroot$tmp/tvmaze-rescan.tmp
	    EP_URL=`cat $glroot$tmp/tvmaze-rescan.tmp | grep 'url":' | head -1 | cut -d':' -f2- | tr -d '"' | tr -d '}'`
	    EP_AIR_DATE=`cat $glroot$tmp/tvmaze-rescan.tmp | grep 'airdate":' | head -1 | cut -d':' -f2 | tr -d '"'`
	fi
	[ "$SHOW_GENRES" == "null" -o -z "$SHOW_GENRES" ] && SHOW_GENRES="NA"
	[ "$SHOW_COUNTRY" == "null" -o -z "$SHOW_COUNTRY" ] && SHOW_COUNTRY="NA"
	[ "$SHOW_LANGUAGE" == "null" -o -z "$SHOW_LANGUAGE" ] && SHOW_LANGUAGE="NA"
	[ "$SHOW_NETWORK" == "null" -o -z "$SHOW_NETWORK" ] && SHOW_NETWORK="NA"
	[ "$SHOW_STATUS" == "null" -o -z "$SHOW_STATUS" ] && SHOW_STATUS="NA"
	[ "$SHOW_TYPE" == "null" -o -z "$SHOW_TYPE" ] && SHOW_TYPE="NA"
	[ "$EP_AIR_DATE" == "null" -o -z "$EP_AIR_DATE" ] && EP_AIR_DATE="NA"
	[ "$SHOW_RATING" == "null" -o -z "$SHOW_RATING" ] && SHOW_RATING="NA"
	[ "$SHOW_IMDB" == "null" -o -z "$SHOW_IMDB" ] && SHOW_IMDB="NA" || SHOW_IMDB="https://imdb.com/title/$SHOW_IMDB"
	[ "$SHOW_SUMMARY" == "null" -o -z "$SHOW_SUMMARY" ] && SHOW_SUMMARY="NA"
	[ "$SHOW_PREMIERED" == "null" -o -z "$SHOW_PREMIERED" ] && SHOW_PREMIERED="NA"
	[ "$SHOW_URL" == "null" -o -z "$SHOW_URL" ] && SHOW_URL="NA"
	[ "$EP_URL" == "null" -o -z "$EP_URL" ] && EP_URL="NA"

	if [ "$debug" -eq 1 ]
	then
	    echo "Scanning dir $i : $1/$rls_name"
	    echo "============================ TVMAZE INFO v`cat $glroot/bin/tvmaze.sh | grep 'VER=' | cut -d'=' -f2` ================================"
	    echo ""
	    echo "Location.....: $1"
	    echo "Show id......: $SHOW_ID"
	    echo "Releasename..: $rls_name"
	    echo "Title........: $SHOW_NAME"
	    echo "-"
	    echo "IMDB Link....: $SHOW_IMDB"
	    echo "TVMaze Link..: $SHOW_URL"
	    echo "Episode Link.: $EP_URL"
	    echo "Genre........: $SHOW_GENRES"
	    echo "Type.........: $SHOW_TYPE"
	    echo "User Rating..: $SHOW_RATING"
	    echo "-"
	    echo "Country......: $SHOW_COUNTRY"
	    echo "Language.....: $SHOW_LANGUAGE"
	    echo "Network......: $SHOW_NETWORK"
	    echo "Status.......: $SHOW_STATUS"
	    echo "Premiered....: $SHOW_PREMIERED"
	    echo "Airdate......: $EP_AIR_DATE"
	    echo "-"
	    echo "Plot.........: $SHOW_SUMMARY"
	    echo ""
	    echo "============================ TVMAZE INFO v`cat $glroot/bin/tvmaze.sh | grep 'VER=' | cut -d'=' -f2` ================================"
	    i=$(($i + 1))
	else
	    echo "Scanning dir $i : $1/$rls_name"
	    echo "============================ TVMAZE INFO v`cat $glroot/bin/tvmaze.sh | grep 'VER=' | cut -d'=' -f2` ================================" > $1/$rls_name/.imdb
	    echo "" >> $1/$rls_name/.imdb
	    echo "Title........: $SHOW_NAME" >> $1/$rls_name/.imdb
	    echo "-" >> $1/$rls_name/.imdb
	    echo "IMDB Link....: $SHOW_IMDB" >> $1/$rls_name/.imdb
	    echo "TVMaze Link..: $SHOW_URL" >> $1/$rls_name/.imdb
	    echo "Episode Link.: $EP_URL" >> $1/$rls_name/.imdb
	    echo "Genre........: $SHOW_GENRES" >> $1/$rls_name/.imdb
	    echo "Type.........: $SHOW_TYPE" >> $1/$rls_name/.imdb
	    echo "User Rating..: $SHOW_RATING" >> $1/$rls_name/.imdb
	    echo "-" >> $1/$rls_name/.imdb
	    echo "Country......: $SHOW_COUNTRY" >> $1/$rls_name/.imdb
	    echo "Language.....: $SHOW_LANGUAGE" >> $1/$rls_name/.imdb
	    echo "Network......: $SHOW_NETWORK" >> $1/$rls_name/.imdb
	    echo "Status.......: $SHOW_STATUS" >> $1/$rls_name/.imdb
	    echo "Premiered....: $SHOW_PREMIERED" >> $1/$rls_name/.imdb
	    echo "Airdate......: $EP_AIR_DATE" >> $1/$rls_name/.imdb
	    echo "-" >> $1/$rls_name/.imdb
	    echo "Plot.........: $SHOW_SUMMARY" | fold -s -w $width >> $1/$rls_name/.imdb
	    echo "" >> $1/$rls_name/.imdb
	    echo "============================ TVMAZE INFO v`cat $glroot/bin/tvmaze.sh | grep 'VER=' | cut -d'=' -f2` ================================" >> $1/$rls_name/.imdb
	    find $1/$rls_name/ -iname "*tvmaze*" -exec rm {} +
	    touch "$1/$rls_name/[TVMAZE]=-_Score_${SHOW_RATING}_-_${SHOW_GENRES}_-_(${SHOW_TYPE})_-=[TVMAZE]"
	    chmod 666 "$1/$rls_name/[TVMAZE]=-_Score_${SHOW_RATING}_-_${SHOW_GENRES}_-_(${SHOW_TYPE})_-=[TVMAZE]"
	    if [ "$preserve" -eq 1 ]
	    then
		find $1 -type d -name "$rls_name" -print0 | while read -r -d '' dir; do file="$(find "$dir" -maxdepth 1 -type f  -printf '%T+ %p\n' | sort -r | head -3 | tail -1 | cut -d' ' -f2-)";if [ -n "$file" ]; then touch "$dir" -mr "$file"; fi; done
	    fi
	    i=$(($i + 1))
	fi
    done
}

for section in $sections
do
    sec=`echo $section | cut -d ':' -f1`
    depth=`echo $section | cut -d ':' -f2`
    case $depth in
    3x)
	for subdir in `ls $glroot$sec`
	do
	    for subdir2 in `ls $glroot$sec/$subdir`
	    do
		for subdir3 in `ls $glroot$sec/$subdir/$subdir2`
		do
		    rescan "$glroot$sec/$subdir/$subdir2/$subdir3"
		done
	    done
	done
        i=$(($i - 1))
	echo
	echo "Total scanned directories: $i"	
    ;;
    2x)
	for subdir in `ls $glroot$sec`
	do
	    for subdir2 in `ls $glroot$sec/$subdir`
	    do
		rescan "$glroot$sec/$subdir/$subdir2"
	    done
	done
        i=$(($i - 1))
	echo
	echo "Total scanned directories: $i"		
    ;;
    1x)
	for subdir in `ls $glroot$sec`
	do
	    rescan "$glroot$sec/$subdir"
	done
	i=$(($i - 1))
	echo
	echo "Total scanned directories: $i"	
    ;;
    *)
	rescan "$glroot$sec"
	i=$(($i - 1))
	echo
	echo "Total scanned directories: $i"	
    ;;
    esac
done

[ -e "$glroot$tmp/tvmaze-rescan.tmp" ] && rm $glroot$tmp/tvmaze-rescan.tmp
[ -e "$glroot$tmp/tvmaze-rescan.lock" ] && rm $glroot$tmp/tvmaze-rescan.lock

exit 0