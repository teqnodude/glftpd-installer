#!/bin/bash
VER=1.0
#--[ Info ]-----------------------------------------------------
#
# TMDB by Teqno
# This script comes without any warranty, use it at your own risk.
#
# This script enables the creation of .imdb and tag files with
# TMDB movie info. Copy this to /glftpd/bin and chmod 755.
#
#--[ Settings ]-------------------------------------------------

GLROOT=/glftpd
DEBUG=0

# What user/group to set for tmdb files in rls dir, requires chmod u+s /glftpd/bin/chown
SETUSER=glftpd
SETGROUP=NoGroup

#--[ Script Start ]---------------------------------------------

user=$(grep "^${SETUSER}:" "$GLROOT/etc/passwd" | cut -d ':' -f3)
group=$(grep "^${SETGROUP}:" "$GLROOT/etc/group" | cut -d ':' -f3)

# Remove surrounding quotes and replace underscores with spaces where needed
remove_quotes() { printf '%s' "${1//\"/}"; }
remove_quotes_and_underscores() { printf '%s' "${1//\"/}" | tr '_' ' '; }

RLS_NAME=$(remove_quotes "$1")
MOVIE_TITLE=$(remove_quotes_and_underscores "$2")
MOVIE_GENRES=$(remove_quotes_and_underscores "$3")
MOVIE_COUNTRY=$(remove_quotes_and_underscores "$4")
MOVIE_LANGUAGE=$(remove_quotes_and_underscores "$5")
MOVIE_STATUS=$(remove_quotes_and_underscores "$6")
MOVIE_RELEASE_DATE=$(remove_quotes "$7")
MOVIE_RATING=$(remove_quotes "$8")
MOVIE_IMDB=$(remove_quotes "$9")
MOVIE_TMDB=$(remove_quotes "${10}")
MOVIE_TAGLINE=$(remove_quotes "${11}" | tr '_' ' ')
MOVIE_OVERVIEW=$(remove_quotes "${12}" | tr '_' ' ' | sed 's|<*.[bip]>||g')
MOVIE_RUNTIME=$(remove_quotes_and_underscores "${13}")
MOVIE_CAST=$(remove_quotes_and_underscores "${14}")

#$movie_imdb_id $movie_tmdb_url $movie_tagline $movie_overview

# Extract year from release date
MOVIE_YEAR=$(echo "$MOVIE_RELEASE_DATE" | cut -d'-' -f1)

# Set default values for empty/null variables
for var in MOVIE_GENRES MOVIE_COUNTRY MOVIE_LANGUAGE MOVIE_STATUS \
           MOVIE_RELEASE_DATE MOVIE_RATING MOVIE_IMDB MOVIE_TMDB \
           MOVIE_TAGLINE MOVIE_OVERVIEW MOVIE_RUNTIME MOVIE_CAST MOVIE_YEAR
do
    if [[ "${!var}" == "null" || -z "${!var}" || "${!var}" == "N/A" ]]
    then
        declare "$var=NA"
    fi
done

# Create the output content once
TMD_INFO=$(cat <<- EOF
============================ TMDB INFO v$VER ================================

Title........: $MOVIE_TITLE $MOVIE_YEAR
Released.....: $MOVIE_RELEASE_DATE
	
IMDB Link....: $MOVIE_IMDB
TMDB Link....: $MOVIE_TMDB
Genre........: $MOVIE_GENRES
User Rating..: $MOVIE_RATING/10

Country......: $MOVIE_COUNTRY
Language.....: $MOVIE_LANGUAGE
Runtime......: $MOVIE_RUNTIME
	
Cast.........: $MOVIE_CAST
	
Plot.........: $MOVIE_OVERVIEW
	
============================ TMDB INFO v$VER ================================
EOF
)

if (( DEBUG == 1 ))
then
    # Output to console for debugging
    echo "$TMD_INFO"
else
    # Output to file
    output_file="$GLROOT$RLS_NAME/.imdb"
    echo "$TMD_INFO" > "$output_file"

    # Format genres for filename (replace spaces with underscores and slashes with hyphens)
    FILENAME_GENRES=$(echo "$MOVIE_GENRES" | sed -e 's/ /_/g' -e 's|/|-|g')
    
    # Create tag file with movie info
    tmdbmarker_file="$GLROOT$RLS_NAME/[TMDB]=-_Score_${MOVIE_RATING}_-_${FILENAME_GENRES}_-_(${MOVIE_YEAR})_-=[TMDB]"
    
    touch "$tmdbmarker_file"

    if [[ -f "$output_file" ]]
    then
        chmod 666 "$tmdbmarker_file" "$output_file"
        $GLROOT/bin/chown $user:$group "$tmdbmarker_file" "$output_file"
    fi

fi
