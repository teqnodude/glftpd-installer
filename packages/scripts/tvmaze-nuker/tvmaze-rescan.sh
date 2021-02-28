#!/bin/bash
VER=1.0
#--[ Info ]-----------------------------------------------------#
#
# This script comes without any warranty, use it at your own risk.
#
# If you want to rescan your tv releases for TVMaze info then 
# this script is for you. It grabs info from TVMaze api and
# creates an .imdb file and tag file in each release with it.
# 
# Changelog
# 2021-02-28 : Teqno original creator
#
#--[ Settings ]-------------------------------------------------#

# Location of glftpd
glroot=/glftpd

# Tmp folder under $glroot
tmp=/tmp

# Recommended to run in debug mode before running, set to 0 to disable.
debug=1

# Set sections that should be scanned. Format /site/section
sections="
/site/TV-HD
"

# What to exclude from scanner
exclude="no-nfo|incomplete|NUKED"

# Do you want to preserve date & time on scanned releases
preserve=1

#--[ Script Start ]---------------------------------------------#

for section in $sections
do
    for rls_name in `ls $glroot$section | egrep -v "$exclude"`
    do
    SHOW=`echo $rls_name | egrep -o ".*.S[0-9][0-9]E[0-9][0-9].|.*.E[0-9][0-9].|.*.[0-9][0-9][0-9][0-9].[0-9][0-9].[0-9][0-9].|.*.Part.[0-9]." | sed -e 's|.S[0-9][0-9].*||' -e 's|.Part.*||' -e 's|[0-9][0-9][0-9][0-9].[0-9][0-9].[0-9][0-9].*||' | tr '.' ' '`
    lynx --dump "https://api.tvmaze.com/singlesearch/shows?q=$SHOW" | sed -e 's|","|"#"|g' -e 's|],"|]#"|g' -e 's|},"|}#"|g' -e 's|",|"#|g' -e 's|,"|#"|g' | tr '#' '\n' > $glroot$tmp/tvmaze.tmp
    SHOW_ID=`cat $glroot$tmp/tvmaze.tmp | grep 'id":' | head -1 | cut -d':' -f2 | tr -d '"'`
    SHOW_NAME=`cat $glroot$tmp/tvmaze.tmp | grep 'name":' | head -1 | cut -d':' -f2 | tr -d '"'`
    SHOW_GENRES=`cat $glroot$tmp/tvmaze.tmp | grep 'genres":' | sed -n '/"genres"/,/]/p' | tr '\n' ' ' | tr -d '[' | tr -d ']' | sed 's/"genres"://' | tr -d '"'`
    SHOW_COUNTRY=`cat $glroot$tmp/tvmaze.tmp | grep 'country":' | head -1 | cut -d':' -f3 | tr -d '"'`
    SHOW_LANGUAGE=`cat $glroot$tmp/tvmaze.tmp | grep 'language":' | head -1 | cut -d':' -f2 | tr -d '"'`
    SHOW_NETWORK=`cat $glroot$tmp/tvmaze.tmp | grep 'name":' | head -2 | tail -1 | cut -d':' -f2 | tr -d '"'`
    SHOW_STATUS=`cat $glroot$tmp/tvmaze.tmp | grep 'status":' | head -1 | cut -d':' -f2 | tr -d '"'`
    SHOW_TYPE=`cat $glroot$tmp/tvmaze.tmp | grep 'type":' | head -1 | cut -d':' -f2 | tr -d '"'`
    SHOW_RATING=`cat $glroot$tmp/tvmaze.tmp | grep 'rating":' | head -1 | cut -d':' -f3 | tr -d '"' | tr -d '}'`
    SHOW_IMDB=`cat $glroot$tmp/tvmaze.tmp | grep 'imdb":' | head -1 | cut -d':' -f2 | tr -d '"' | tr -d '}'`
    SHOW_URL=`cat $glroot$tmp/tvmaze.tmp | grep 'url":' | head -1 | cut -d':' -f2- | tr -d '"' | tr -d '}'`
    SHOW_SUMMARY=`cat $glroot$tmp/tvmaze.tmp | grep 'summary":' | head -1 | cut -d':' -f2 | tr -d '"' | sed -e 's|<p>||' -e 's|</p>||' -e 's|<b>||g' -e 's|</b>||g' -e 's|<i>||g' -e 's|</i>||g'`
    if [ `echo $rls_name | egrep -o "S[0-9][0-9]E[0-9][0-9]"` ]
    then
        SEASON=`echo $rls_name | egrep -o "S[0-9][0-9]" | tr -d 'S'`
        EPISODE=`echo $rls_name | egrep -o "E[0-9][0-9]" | tr -d 'E'`
        lynx --dump "https://api.tvmaze.com/shows/$SHOW_ID/episodebynumber?season=$SEASON&number=$EPISODE" | sed -e 's|","|"#"|g' -e 's|],"|]#"|g' -e 's|},"|}#"|g' -e 's|",|"#|g' -e 's|,"|#"|g' | tr '#' '\n' > $glroot$tmp/tvmaze.tmp
        EP_URL=`cat $glroot$tmp/tvmaze.tmp | grep 'url":' | head -1 | cut -d':' -f2- | tr -d '"' | tr -d '}'`
    fi
    if [ `echo $rls_name | egrep -o "[0-9][0-9][0-9][0-9].[0-9][0-9].[0-9][0-9]"` ]
    then
        DATE=`echo $rls_name | egrep -o "[0-9][0-9][0-9][0-9].[0-9][0-9].[0-9][0-9]" | tr '.' '-'`
        lynx --dump "https://api.tvmaze.com/shows/$SHOW_ID/episodesbydate?date=$DATE" | sed -e 's|","|"#"|g' -e 's|],"|]#"|g' -e 's|},"|}#"|g' -e 's|",|"#|g' -e 's|,"|#"|g' | tr '#' '\n' > $glroot$tmp/tvmaze.tmp
        EP_URL=`cat $glroot$tmp/tvmaze.tmp | grep 'url":' | head -1 | cut -d':' -f2- | tr -d '"' | tr -d '}'`
    fi
    if [ `echo $rls_name | egrep -o "Part.[0-9]"` ]
    then
        SEASON=1
        EPISODE=`echo $rls_name | grep -o "Part.[0-9]" | grep -o "[0-9]"`
        lynx --dump "https://api.tvmaze.com/shows/$SHOW_ID/episodebynumber?season=$SEASON&number=$EPISODE" | sed -e 's|","|"#"|g' -e 's|],"|]#"|g' -e 's|},"|}#"|g' -e 's|",|"#|g' -e 's|,"|#"|g' | tr '#' '\n' > $glroot$tmp/tvmaze.tmp
        EP_URL=`cat $glroot$tmp/tvmaze.tmp | grep 'url":' | head -1 | cut -d':' -f2- | tr -d '"' | tr -d '}'`
    fi
    [ "$SHOW_GENRES" == "null" -o -z "$SHOW_GENRES" ] && SHOW_GENRES="NA"
    [ "$SHOW_COUNTRY" == "null" -o -z "$SHOW_COUNTRY" ] && SHOW_COUNTRY="NA"
    [ "$SHOW_LANGUAGE" == "null" -o -z "$SHOW_LANGUAGE" ] && SHOW_LANGUAGE="NA"
    [ "$SHOW_NETWORK" == "null" -o -z "$SHOW_NETWORK" ] && SHOW_NETWORK="NA"
    [ "$SHOW_STATUS" == "null" -o -z "$SHOW_STATUS" ] && SHOW_STATUS="NA"
    [ "$SHOW_TYPE" == "null" -o -z "$SHOW_TYPE" ] && SHOW_TYPE="NA"
    [ "$SHOW_EP_AIR_DATE" == "null" -o -z "$SHOW_EP_AIR_DATE" ] && SHOW_EP_AIR_DATE="NA"
    [ "$SHOW_RATING" == "null" -o -z "$SHOW_RATING" ] && SHOW_RATING="NA"
    [ "$SHOW_IMDB" == "null" -o -z "$SHOW_IMDB" ] && SHOW_IMDB="NA" || SHOW_IMDB="https://imdb.com/title/$SHOW_IMDB"
    [ "$SHOW_SUMMARY" == "null" -o -z "$SHOW_SUMMARY" ] && SHOW_SUMMARY="NA"
    [ "$SHOW_PREMIERED" == "null" -o -z "$SHOW_PREMIERED" ] && SHOW_PREMIERED="NA"
    [ "$SHOW_URL" == "null" -o -z "$SHOW_URL" ] && SHOW_URL="NA"
    [ "$EP_URL" == "null" -o -z "$EP_URL" ] && EP_URL="NA"

    if [ "$debug" -eq 1 ]
    then
        echo "============================ TVMAZE INFO v`cat $glroot/bin/tvmaze.sh | grep 'VER=' | cut -d'=' -f2` ================================"
        echo ""
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
        echo "-"
        echo "Plot.........: $SHOW_SUMMARY"
        echo ""
        echo "============================ TVMAZE INFO v`cat $glroot/bin/tvmaze.sh | grep 'VER=' | cut -d'=' -f2` ================================"
    else
        echo "============================ TVMAZE INFO v`cat $glroot/bin/tvmaze.sh | grep 'VER=' | cut -d'=' -f2` ================================" > $glroot$section/$rls_name/.imdb
        echo "" >> $glroot$section/$rls_name/.imdb
        echo "Title........: $SHOW_NAME" >> $glroot$section/$rls_name/.imdb
        echo "-" >> $glroot$section/$rls_name/.imdb
        echo "IMDB Link....: $SHOW_IMDB" >> $glroot$section/$rls_name/.imdb
        echo "TVMaze Link..: $SHOW_URL" >> $glroot$section/$rls_name/.imdb
        echo "Episode Link.: $EP_URL" >> $glroot$section/$rls_name/.imdb
        echo "Genre........: $SHOW_GENRES" >> $glroot$section/$rls_name/.imdb
        echo "Type.........: $SHOW_TYPE" >> $glroot$section/$rls_name/.imdb
        echo "User Rating..: $SHOW_RATING" >> $glroot$section/$rls_name/.imdb
        echo "-" >> $glroot$section/$rls_name/.imdb
        echo "Country......: $SHOW_COUNTRY" >> $glroot$section/$rls_name/.imdb
        echo "Language.....: $SHOW_LANGUAGE" >> $glroot$section/$rls_name/.imdb
        echo "Network......: $SHOW_NETWORK" >> $glroot$section/$rls_name/.imdb
        echo "Status.......: $SHOW_STATUS" >> $glroot$section/$rls_name/.imdb
        echo "-" >> $glroot$section/$rls_name/.imdb
        echo "Plot.........: $SHOW_SUMMARY" >> $glroot$section/$rls_name/.imdb
        echo "" >> $glroot$section/$rls_name/.imdb
        echo "============================ TVMAZE INFO v`cat $glroot/bin/tvmaze.sh | grep 'VER=' | cut -d'=' -f2` ================================" >> $glroot$section/$rls_name/.imdb
        touch "$glroot$section/$rls_name/[TVMAZE]=-_Score_${SHOW_RATING}_-_${SHOW_GENRES}_-_(${SHOW_PREMIERED})_-=[TVMAZE]"
        chmod 666 "$glroot$section/$rls_name/[TVMAZE]=-_Score_${SHOW_RATING}_-_${SHOW_GENRES}_-_(${SHOW_PREMIERED})_-=[TVMAZE]"
        if [ "$preserve" -eq 1 ]
        then
	find $glroot$section -type d -name "$rls_name" -print0 | while read -r -d '' dir; do file="$(find "$dir" -maxdepth 1 -type f  -printf '%T+ %p\n' | sort -r | head -3 | tail -1 | cut -d' ' -f2-)";if [ -n "$file" ]; then touch "$dir" -mr "$file"; fi; done
        fi
    fi
    done
done

rm $glroot$tmp/tvmaze.tmp

exit 0