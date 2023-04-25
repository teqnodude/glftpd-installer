#!/bin/bash
VER=1.5
#--[ Info ]-----------------------------------------------------#
#
# This script enables the creation of .imdb and tag file with
# TVMaze info. Copy this to /glftpd/bin and chmod 755.
#
# Changelog
# 2022-04-21 v1.5 Added ability to set user/group for tvmaze files in rls dir
# 2021-03-25 v1.4 Code for airdate was not properly set
# 2021-03-03 v1.3 Added option for maximum width for plot summary
# 2021-03-02 v1.2 Cosmetic changes in code and change from premiered to show type in tag file
# 2021-02-28 v1.1 Added TVMaze link for show and episode
# 2021-02-26 v1.0 Orginal creator Teqno
#
#--[ Settings ]-------------------------------------------------#

glroot=/glftpd
debug=0
# Maximum width for text written to .imdb
width=77
# What user/group to set for tmaze files in rls dir, requires chmod u+s /glftpd/bin/chown
setuser=glftpd
setgroup=NoGroup

#--[ Script Start ]---------------------------------------------#

user=`cat $glroot/etc/passwd | grep $setuser | cut -d ':' -f3`
group=`cat $glroot/etc/group | grep $setgroup | cut -d ':' -f3`

# Process args and remove unwanted chars..
RLS_NAME=`sed -e 's/^"//' -e 's/"$//' <<<"$1"`
SHOW_NAME=`sed -e 's/^"//' -e 's/"$//' -e 's|_| |g' <<<"$2"`
SHOW_GENRES=`sed -e 's/^"//' -e 's/"$//' -e 's|_| |g' <<<"$3"`
SHOW_COUNTRY=`sed -e 's/^"//' -e 's/"$//' -e 's|_| |g' <<<"$4"`
SHOW_LANGUAGE=`sed -e 's/^"//' -e 's/"$//' -e 's|_| |g' <<<"$5"`
SHOW_NETWORK=`sed -e 's/^"//' -e 's/"$//' -e 's|_| |g' <<<"$6"`
SHOW_STATUS=`sed -e 's/^"//' -e 's/"$//' -e 's|_| |g' <<<"$7"`
SHOW_TYPE=`sed -e 's/^"//' -e 's/"$//' -e 's|_| |g' <<<"$8"`
EP_AIR_DATE=`sed -e 's/^"//' -e 's/"$//' <<<"$9"`
SHOW_RATING=`sed -e 's/^"//' -e 's/"$//' <<<"${10}"`
SHOW_IMDB=`sed -e 's/^"//' -e 's/"$//' <<<"${11}"`
SHOW_SUMMARY=`sed -e 's/^"//' -e 's/"$//' -e 's|_| |g' -e 's|<*.[b|i|p]>||g' <<<"${12}"`
SHOW_PREMIERED=`sed -e 's/^"//' -e 's/"$//' -e 's/-.*//g'<<<"${13}"`
SHOW_URL=`sed -e 's/^"//' -e 's/"$//' -e 's/-.*//g'<<<"${14}"`
EP_URL=`sed -e 's/^"//' -e 's/"$//' -e 's/-.*//g'<<<"${15}"`

[ "$SHOW_GENRES" == "null" -o -z "$SHOW_GENRES" ] && SHOW_GENRES="NA"
[ "$SHOW_COUNTRY" == "null" -o -z "$SHOW_COUNTRY" ] && SHOW_COUNTRY="NA"
[ "$SHOW_LANGUAGE" == "null" -o -z "$SHOW_LANGUAGE" ] && SHOW_LANGUAGE="NA"
[ "$SHOW_NETWORK" == "null" -o -z "$SHOW_NETWORK" ] && SHOW_NETWORK="NA"
[ "$SHOW_STATUS" == "null" -o -z "$SHOW_STATUS" ] && SHOW_STATUS="NA"
[ "$SHOW_TYPE" == "null" -o -z "$SHOW_TYPE" ] && SHOW_TYPE="NA"
[ "$EP_AIR_DATE" == "null" -o -z "$EP_AIR_DATE" ] && EP_AIR_DATE="NA"
[ "$SHOW_RATING" == "null" -o -z "$SHOW_RATING" ] && SHOW_RATING="NA"
[ "$SHOW_IMDB" == "null" -o -z "$SHOW_IMDB" ] && SHOW_IMDB="NA"
[ "$SHOW_SUMMARY" == "null" -o -z "$SHOW_SUMMARY" ] && SHOW_SUMMARY="NA"
[ "$SHOW_PREMIERED" == "null" -o -z "$SHOW_PREMIERED" ] && SHOW_PREMIERED="NA"
[ "$SHOW_URL" == "null" -o -z "$SHOW_URL" ] && SHOW_URL="NA"
[ "$EP_URL" == "null" -o -z "$EP_URL" ] && EP_URL="NA"


if [ "$debug" -eq 1 ]
then
    echo "============================ TVMAZE INFO v$VER ================================"
    echo ""
    echo "Title........: $SHOW_NAME"
    echo "Premiered....: $SHOW_PREMIERED"
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
    echo "============================ TVMAZE INFO v$VER ================================"
else
    echo "============================ TVMAZE INFO v$VER ================================" > $glroot$RLS_NAME/.imdb
    echo "" >> $glroot$RLS_NAME/.imdb
    echo "Title........: $SHOW_NAME" >> $glroot$RLS_NAME/.imdb
    echo "Premiered....: $SHOW_PREMIERED" >> $glroot$RLS_NAME/.imdb
    echo "-" >> $glroot$RLS_NAME/.imdb
    echo "IMDB Link....: $SHOW_IMDB" >> $glroot$RLS_NAME/.imdb
    echo "TVMaze Link..: $SHOW_URL" >> $glroot$RLS_NAME/.imdb
    echo "Episode Link.: $EP_URL" >> $glroot$RLS_NAME/.imdb
    echo "Genre........: $SHOW_GENRES" >> $glroot$RLS_NAME/.imdb
    echo "Type.........: $SHOW_TYPE" >> $glroot$RLS_NAME/.imdb
    echo "User Rating..: $SHOW_RATING" >> $glroot$RLS_NAME/.imdb
    echo "-" >> $glroot$RLS_NAME/.imdb
    echo "Country......: $SHOW_COUNTRY" >> $glroot$RLS_NAME/.imdb
    echo "Language.....: $SHOW_LANGUAGE" >> $glroot$RLS_NAME/.imdb
    echo "Network......: $SHOW_NETWORK" >> $glroot$RLS_NAME/.imdb
    echo "Status.......: $SHOW_STATUS" >> $glroot$RLS_NAME/.imdb
    echo "Premiered....: $SHOW_PREMIERED" >> $glroot$RLS_NAME/.imdb
    echo "Airdate......: $EP_AIR_DATE" >> $glroot$RLS_NAME/.imdb
    echo "-" >> $glroot$RLS_NAME/.imdb
    echo "Plot.........: $SHOW_SUMMARY" | fold -s -w $width >> $glroot$RLS_NAME/.imdb
    echo "" >> $glroot$RLS_NAME/.imdb
    echo "============================ TVMAZE INFO v$VER ================================" >> $glroot$RLS_NAME/.imdb
    SHOW_GENRES=`echo $SHOW_GENRES | sed -e 's/ /_/g' -e 's|/|-|g'`
    touch "$glroot$RLS_NAME/[TVMAZE]=-_Score_${SHOW_RATING}_-_${SHOW_GENRES}_-_(${SHOW_TYPE})_-=[TVMAZE]"
    chmod 666 "$glroot$RLS_NAME/[TVMAZE]=-_Score_${SHOW_RATING}_-_${SHOW_GENRES}_-_(${SHOW_TYPE})_-=[TVMAZE]" $glroot$RLS_NAME/.imdb
    $glroot/bin/chown $user:$group "$glroot$RLS_NAME/[TVMAZE]=-_Score_${SHOW_RATING}_-_${SHOW_GENRES}_-_(${SHOW_TYPE})_-=[TVMAZE]" $glroot$RLS_NAME/.imdb
fi

exit 0