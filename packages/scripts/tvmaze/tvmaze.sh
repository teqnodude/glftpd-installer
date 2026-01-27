#!/bin/bash
VER=1.7
#--[ Info ]-----------------------------------------------------
#
# TVMaze Info by Teqno
#
# This script comes without any warranty, use it at your own risk.
#
# This script enables the creation of .imdb and tag file with
# TVMaze info. Copy this to /glftpd/bin and chmod 755.
#
#--[ Settings ]-------------------------------------------------

GLROOT=/glftpd
DEBUG=0

# What user/group to set for tmaze files in rls dir, requires chmod u+s /glftpd/bin/chown
SETUSER=glftpd
SETGROUP=NoGroup

#--[ Script Start ]---------------------------------------------

user=$(grep "^${SETUSER}:" "$GLROOT/etc/passwd" | cut -d ':' -f3)
group=$(grep "^${SETGROUP}:" "$GLROOT/etc/group" | cut -d ':' -f3)

# Remove surrounding quotes and replace underscores with spaces where needed
remove_quotes() { printf '%s' "${1//\"/}"; }
remove_quotes_and_underscores() { printf '%s' "${1//\"/}" | tr '_' ' '; }

RLS_NAME=$(remove_quotes "$1")
SHOW_NAME=$(remove_quotes_and_underscores "$2")
SHOW_GENRES=$(remove_quotes_and_underscores "$3")
SHOW_COUNTRY=$(remove_quotes_and_underscores "$4")
SHOW_LANGUAGE=$(remove_quotes_and_underscores "$5")
SHOW_NETWORK=$(remove_quotes_and_underscores "$6")
SHOW_STATUS=$(remove_quotes_and_underscores "$7")
SHOW_TYPE=$(remove_quotes_and_underscores "$8")
EP_AIR_DATE=$(remove_quotes "$9")
SHOW_RATING=$(remove_quotes "${10}")
SHOW_IMDB=$(remove_quotes "${11}")
SHOW_SUMMARY=$(remove_quotes "${12}" | tr '_' ' ' | sed 's|<*.[bip]>||g')
SHOW_PREMIERED=$(remove_quotes "${13}" | sed 's/-.*//g')
SHOW_URL=$(remove_quotes "${14}" | sed 's/-.*//g')
EP_URL=$(remove_quotes "${15}" | sed 's/-.*//g')

for var in SHOW_GENRES SHOW_COUNTRY SHOW_LANGUAGE SHOW_NETWORK SHOW_STATUS \
           SHOW_TYPE EP_AIR_DATE SHOW_RATING SHOW_IMDB SHOW_SUMMARY \
           SHOW_PREMIERED SHOW_URL EP_URL
do

    if [[ "${!var}" == "null" || -z "${!var}" ]]
    then

        declare "$var=NA"

    fi

done

# Create the output content once
TVMAZE_INFO=$(cat <<- EOF
============================ TVMAZE INFO v$VER ================================

Title........: $SHOW_NAME
Premiered....: $SHOW_PREMIERED
	
IMDB Link....: $SHOW_IMDB
TVMaze Link..: $SHOW_URL
Episode Link.: $EP_URL
Genre........: $SHOW_GENRES
Type.........: $SHOW_TYPE
User Rating..: $SHOW_RATING
	
Country......: $SHOW_COUNTRY
Language.....: $SHOW_LANGUAGE
Network......: $SHOW_NETWORK
Status.......: $SHOW_STATUS
Airdate......: $EP_AIR_DATE
	
Plot.........: $SHOW_SUMMARY
	
============================ TVMAZE INFO v$VER ================================
EOF
)
if (( DEBUG == 1 ))
then
	echo "$TVMAZE_INFO"
else

    # Output to file
    output_file="$GLROOT$RLS_NAME/.imdb"
    echo "$TVMAZE_INFO" > "$output_file"

    # Format genres for filename
    SHOW_GENRES=$(echo "$SHOW_GENRES" | sed -e 's/ /_/g' -e 's|/|-|g')
    tvmarker_file="$GLROOT$RLS_NAME/[TVMAZE]=-_Score_${SHOW_RATING}_-_${SHOW_GENRES}_-_(${SHOW_TYPE})_-=[TVMAZE]"
    
    touch "$tvmarker_file"

    if [[ -f "$output_file" ]]
    then

        chmod 666 "$tvmarker_file" "$output_file"
        $GLROOT/bin/chown $user:$group "$tvmarker_file" "$output_file"

    fi

fi

