#!/bin/bash
VER=1.0
#--[ Info ]-----------------------------------------------------#
#
# This script enables the creation of .imdb and tag file with
# TVMaze info. Copy this to /glftpd/bin and chmod 755.
#
# Changelog
# 2021-02-26 v.1.0 Orginal creator Teqno
#
#--[ Settings ]-------------------------------------------------#

glroot=/glftpd
debug=0

#--[ Script Start ]---------------------------------------------#

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
SHOW_SUMMARY=`sed -e 's/^"//' -e 's/"$//' -e 's|_| |g' -e 's|<p>||' -e 's|</p>||' -e 's|<b>||g' -e 's|</b>||g'<<<"${12}"`
SHOW_PREMIERED=`sed -e 's/^"//' -e 's/"$//' -e 's/-.*//g'<<<"${13}"`

[ -z "$SHOW_GENRES" ] && SHOW_GENRES="NA"
[ -z "$SHOW_COUNTRY" ] && SHOW_COUNTRY="NA"
[ -z "$SHOW_LANGUAGE" ] && SHOW_LANGUAGE="NA"
[ -z "$SHOW_NETWORK" ] && SHOW_NETWORK="NA"
[ -z "$SHOW_STATUS" ] && SHOW_STATUS="NA"
[ -z "$SHOW_TYPE" ] && SHOW_TYPE="NA"
[ -z "$SHOW_EP_AIR_DATE" ] && SHOW_EP_AIR_DATE="NA"
[ -z "$SHOW_RATING" ] && SHOW_RATING="NA"
[ -z "$SHOW_IMDB" ] && SHOW_IMDB="NA"
[ -z "$SHOW_SUMMARY" ] && SHOW_SUMMARY="NA"
[ -z "$SHOW_PREMIERED" ] && SHOW_PREMIERED="NA"

if [ "$debug" -eq 1 ]
then
    echo "============================ TVMAZE INFO v1.0 ================================"
    echo ""
    echo "Title........: $SHOW_NAME"
    echo "Premiered....: $SHOW_PREMIERED"
    echo "-"
    echo "IMDB Link....: $SHOW_IMDB"
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
    echo "============================ TVMAZE INFO v1.0 ================================"
else
    [ -z "$SHOW_RATING" ] && SHOW_RATING="NA"
    [ -z "$SHOW_GENRES" ] && SHOW_GENRES="NA"
    [ -z "$SHOW_PREMIERED" ] && SHOW_PREMIERED="NA"
    echo "============================ TVMAZE INFO v1.0 ================================" > $glroot$RLS_NAME/.imdb
    echo "" >> $glroot$RLS_NAME/.imdb
    echo "Title........: $SHOW_NAME" >> $glroot$RLS_NAME/.imdb
    echo "Premiered....: $SHOW_PREMIERED" >> $glroot$RLS_NAME/.imdb
    echo "-" >> $glroot$RLS_NAME/.imdb
    echo "IMDB Link....: $SHOW_IMDB" >> $glroot$RLS_NAME/.imdb
    echo "Genre........: $SHOW_GENRES" >> $glroot$RLS_NAME/.imdb
    echo "Type.........: $SHOW_TYPE" >> $glroot$RLS_NAME/.imdb
    echo "User Rating..: $SHOW_RATING" >> $glroot$RLS_NAME/.imdb
    echo "-" >> $glroot$RLS_NAME/.imdb
    echo "Country......: $SHOW_COUNTRY" >> $glroot$RLS_NAME/.imdb
    echo "Language.....: $SHOW_LANGUAGE" >> $glroot$RLS_NAME/.imdb
    echo "Network......: $SHOW_NETWORK" >> $glroot$RLS_NAME/.imdb
    echo "Status.......: $SHOW_STATUS" >> $glroot$RLS_NAME/.imdb
    echo "-" >> $glroot$RLS_NAME/.imdb
    echo "Plot.........: $SHOW_SUMMARY" >> $glroot$RLS_NAME/.imdb
    echo "" >> $glroot$RLS_NAME/.imdb
    echo "============================ TVMAZE INFO v1.0 ================================" >> $glroot$RLS_NAME/.imdb
    SHOW_GENRES=`echo $SHOW_GENRES | sed -e 's/ /_/g' -e 's|/|-|g'`
    touch "$glroot$RLS_NAME/[TVMAZE]=-_Score_${SHOW_RATING}_-_${SHOW_GENRES}_-_(${SHOW_PREMIERED})_-=[TVMAZE]"
    chmod 666 "$glroot$RLS_NAME/[TVMAZE]=-_Score_${SHOW_RATING}_-_${SHOW_GENRES}_-_(${SHOW_PREMIERED})_-=[TVMAZE]"
    chmod 666 $glroot$RLS_NAME/.imdb
fi

exit 0