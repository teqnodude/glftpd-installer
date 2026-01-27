#!/bin/bash
VER=1.0
#--[ Info ]-----------------------------------------------------
#
# TMDB Nuker by Teqno
#
# This script comes without any warranty, use it at your own risk.
#
# Installation: copy tmdb-nuker.sh to glftpd/bin and chmod it
# 755. Copy the modificated TMDB.tcl into your eggdrop pzs-ng
# plugins dir.
#
# Modify glroot into /glftpd or /jail/glftpd.
#
# To ensure log file exist, run: "./tmdb-nuker.sh sanity" from
# shell, this will create the log file and set the correct
# permissions.
#
#--[ Settings ]-------------------------------------------------

GLROOT=/glftpd
GLCONF=$GLROOT/etc/glftpd.conf
DEBUG=0
LOG_FILE=$GLROOT/ftp-data/logs/tmdb-nuker.log

# Username of person to nuke with. This user must be a glftpd user account.
NUKE_USER=glftpd

# Multiplier to use when nuking a release
NUKE_MULTIPLER=5

# Movie Genres: Action Adventure Animation Comedy Crime Documentary Drama Family Fantasy History Horror Music Mystery Romance Science_Fiction TV_Movie Thriller War Western
# Space delimited list of movie genres to nuke.
NUKE_MOVIE_GENRES="Documentary"

# Configured like NUKE_SECTION_GENRES
# Genres: Action Adventure Animation Comedy Crime Documentary Drama Family Fantasy History Horror Music Mystery Romance Science_Fiction TV_Movie Thriller War Western
NUKE_SECTION_GENRES="
/site/MOVIES-HD:(Documentary|Music)
"

# Movies with a release date before this year will be nuked
NUKE_MOVIES_BEFORE_YEAR="2010"

# Space delimited list of countries that will be nuked
NUKE_ORIGIN_COUNTRIES="CN RU"

# Languages to NOT nuke.
NUKE_SECTION_LANGUAGES="
/site/X264-1080:(English)
"

# What rating should be the minimum *allowed* per section? For now, no decimals are allowed.
NUKE_SECTION_RATINGS="
/site/MOVIES-HD:5
"

# Movie Status: Released Rumored Planned In_Production Post_Production Canceled
NUKE_SECTION_STATUS="
/site/MOVIES-HD:(Rumored|Planned|In_Production|Post_Production|Canceled)
"

# Space delimited list of Movies to nuke, use releasename and not movie name ie use The.Matrix and NOT The Matrix
NUKE_MOVIES_LIST=""

# 1 = Enable / 0 = Disable
NUKE_MOVIE_GENRE=0
NUKE_SECTION_GENRE=0
NUKE_MOVIE_BEFORE_YEAR=0
NUKE_ORIGIN_COUNTRY=0
NUKE_SECTION_LANGUAGE=0
NUKE_SECTION_RATING=0
NUKE_SECTION_STATUS=0
NUKE_MOVIE=0
NUKE_ADAPTIVE=0
NUKE_CLEAN_BLOCKLIST=0

# Space delimited list of movies to never nuke, use releasename and not movie name i.e. use The.Matrix and NOT The Matrix
ALLOWED_MOVIES=""

# Space delimited list of sections to never nuke
EXCLUDED_SECTIONS="ARCHIVE REQUEST"

# Space delimited list of groups to never nuke ie affils
EXCLUDED_GROUPS=""

# Blockfile for adaptive blocking that needs to be created and chmod 666
BLOCKFILE=$GLROOT/bin/tur-predircheck.block

# How many days should a row of blocks remain in BLOCKFILE before being cleaned out by the setting NUKE_CLEAN_BLOCKLIST
BLOCKDAYS=180 # 180 days = 6 months

# Length of rows in chars in BLOCKFILE. Its relevance is to the number of rows and blocks before losing speed when creating new dirs.
# WARNING: If you change this number you have to empty the file BLOCKFILE to avoid problems.
LENGTH=400

#--[ Script Start ]---------------------------------------------

LogMsg()
{

    DATE=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$DATE $@" >> $LOG_FILE

}

if [[ "$1" = "sanity" ]]
then

    echo
    echo "Creating log and blockfile and setting permission 666"
    touch $LOG_FILE && chmod 666 $LOG_FILE
    touch $BLOCKFILE && chmod 666 $BLOCKFILE
    exit 0

fi

if [[ ! -f $LOG_FILE ]]
then

    echo
    echo "Log file $LOG_FILE do not exist, create it by running ./tmdb-nuker.sh sanity"
    echo
    exit 1

fi

if [[ ! -f $BLOCKFILE ]]
then

    echo
    echo "Blockfile $BLOCKFILE do not exist, create it by running ./tmdb-nuker.sh sanity"
    echo
    exit 1

fi

if [[ $# -lt 7 ]]
then

    echo
    echo "ERROR! Missing arguments. Expected at least 7, got $#"
    echo "Usage: $0 <release_name> <genres> <country> <language> <status> <release_date> <rating>"
    echo
    LogMsg "ERROR! Not enough arguments passed in. Got $# args."
    exit 1

fi

# Process args and remove encapsulating double quotes.
remove_quotes() 
{
    printf '%s' "${1//\"/}"
}

RLS_NAME=$(remove_quotes "$1")
MOVIE_GENRES=$(remove_quotes "$2")
MOVIE_COUNTRY=$(remove_quotes "$3")
MOVIE_LANGUAGE=$(remove_quotes "$4")
MOVIE_STATUS=$(remove_quotes "$5")
MOVIE_RELEASE_DATE=$(remove_quotes "$6")
MOVIE_RATING=$(remove_quotes "$7")

# Extract year from release date
MOVIE_YEAR=$(echo "$MOVIE_RELEASE_DATE" | cut -d'-' -f1)

function addblock
{

today=$(date "+%Y-%m-%d")
section=$(echo $1 | cut -d '/' -f3)

if [[ ! "$(grep "$1" $BLOCKFILE)" ]]
then

    echo "$1:^($2)[._-]:$today" >> $BLOCKFILE

else

    if [[ "$(grep "$1" $BLOCKFILE | tail -1 | wc -c)" -ge "$LENGTH" ]]
    then

        $GLROOT/bin/sed -i -e "$(grep -n "/site/$section:^" $BLOCKFILE | tail -1 | cut -f1 -d':')a /site/$section:^($2)[._-]:$today" $BLOCKFILE

    else

        startword=$(grep "$1:^(" $BLOCKFILE | tail -1 | sed -e 's/\^(//' -e 's/)\[._-]//' | cut -d':' -f2 | cut -d'|' -f1)
        $GLROOT/bin/sed -i "/\/site\/$section:^(/ s/$startword/$2|$startword/" $BLOCKFILE

    fi

fi

}


if [[ "$DEBUG" == "1" ]]
then

    LogMsg "Release: $RLS_NAME Genres: $MOVIE_GENRES Country: $MOVIE_COUNTRY Language: $MOVIE_LANGUAGE Status: $MOVIE_STATUS Release date: $MOVIE_RELEASE_DATE Year: $MOVIE_YEAR Rating: $MOVIE_RATING"

fi

for movie in $ALLOWED_MOVIES
do

    result=$(echo "$RLS_NAME" | grep -i "$movie")

    if [[ -n "$result" ]]
    then

        if [[ "$DEBUG" == "1" ]]
        then

            LogMsg "Skipping allowed movie: $RLS_NAME"

        fi

        echo "Skipping allowed movie: $RLS_NAME"
        exit 0

    fi

done

for section in $EXCLUDED_SECTIONS
do

    result=$(echo "$RLS_NAME" | grep -i "$section/")

    if [[ -n "$result" ]]
    then

        if [[ "$DEBUG" == "1" ]]
        then

            LogMsg "Skipping excluded section: $RLS_NAME - $section"

        fi

        echo "Skipping excluded section: $RLS_NAME - $section"
        exit 0

    fi

done

for group in $EXCLUDED_GROUPS
do

    result=$(echo "$RLS_NAME" | grep -i "\-$group")

    if [[ -n "$result" ]]
    then

        if [[ "$DEBUG" == "1" ]]
        then

            LogMsg "Skipping excluded group: $RLS_NAME - $group"

        fi

        echo "Skipping excluded group: $RLS_NAME - $group"
        exit 0

    fi

done

if [[ "$NUKE_MOVIE_GENRE" == "1" ]]
then

    if [[ -n "$NUKE_MOVIE_GENRES" ]]
    then

        for genre in $NUKE_MOVIE_GENRES
        do

            if echo "$MOVIE_GENRES" | grep -iq "$genre"
            then

                if [[ "$NUKE_ADAPTIVE" == "1" ]]
                then

                    section=$(echo $RLS_NAME | cut -d'/' -f1-3)
                    # Extract movie title from release name (remove year and everything after)
                    movie_title=$(echo $RLS_NAME | rev | cut -d'/' -f1 | rev | sed -E 's/\.[0-9]{4}\..*//' | sed 's/\./ /g')
                    # Get first word for blocking
                    block_word=$(echo $movie_title | awk '{print $1}')
                    
                    if ! grep "^$section:^(" "$BLOCKFILE" \
                        | sed -E 's#^.*:\^\(([^)]*)\)\[._-].*#\1#' \
                        | tr '|' '\n' \
                        | grep -Fxq "$block_word"
                    then

                        addblock "$section" "$block_word"

                    fi

                fi

                $GLROOT/bin/nuker -r "$GLCONF" -N "$NUKE_USER" -n "$RLS_NAME" "$NUKE_MULTIPLER" "$genre movies are not allowed"
                [[ -f "$GLROOT/bin/incomplete-list-nuker.sh" ]] && $GLROOT/bin/incomplete-list-nuker.sh store $RLS_NAME
                LogMsg "Nuked release: $RLS_NAME because its genre contains $genre which is not allowed."
                exit 0

            fi

        done

    fi

fi

if [[ "$NUKE_SECTION_GENRE" == "1" ]]
then

    for rawdata in $NUKE_SECTION_GENRES
    do

        section="$(echo "$rawdata" | cut -d ':' -f1)"
        denied="$(echo "$rawdata" | cut -d ':' -f2)"

        if echo "$RLS_NAME" | grep -iq "$section/"
        then

            if echo "$MOVIE_GENRES" | grep -Eiq "$denied"
            then

                genre="$(echo $MOVIE_GENRES | grep -Eoi $denied | head -1)"

                if [[ "$NUKE_ADAPTIVE" == "1" ]]
                then

                    # Extract movie title from release name
                    movie_title=$(echo $RLS_NAME | rev | cut -d'/' -f1 | rev | sed -E 's/\.[0-9]{4}\..*//' | sed 's/\./ /g')
                    block_word=$(echo $movie_title | awk '{print $1}')

                    if ! grep "^$section:^(" "$BLOCKFILE" \
                        | sed -E 's#^.*:\^\(([^)]*)\)\[._-].*#\1#' \
                        | tr '|' '\n' \
                        | grep -Fxq "$block_word"
                    then

                        addblock "$section" "$block_word"

                    fi

                fi

                $GLROOT/bin/nuker -r "$GLCONF" -N "$NUKE_USER" -n "$RLS_NAME" "$NUKE_MULTIPLER" "$genre genre is not allowed"
                [[ -f "$GLROOT/bin/incomplete-list-nuker.sh" ]] && $GLROOT/bin/incomplete-list-nuker.sh store $RLS_NAME
                LogMsg "Nuked release: $RLS_NAME because its genre contains $genre which is not allowed in section $section."
                exit 0

            fi

        fi

    done

fi

if [[ "$NUKE_MOVIE_BEFORE_YEAR" == "1" && -n "$MOVIE_YEAR" && "$MOVIE_YEAR" != "N/A" ]]
then

    if [[ -n "$MOVIE_YEAR" && "$MOVIE_YEAR" -lt "${NUKE_MOVIES_BEFORE_YEAR:-0}" ]]
    then
    
        if [[ "$NUKE_ADAPTIVE" == "1" ]]
        then
        
            section=$(echo "$RLS_NAME" | cut -d'/' -f1-3)
            # Extract movie title from release name
            movie_title=$(echo $RLS_NAME | rev | cut -d'/' -f1 | rev | sed -E 's/\.[0-9]{4}\..*//' | sed 's/\./ /g')
            block_word=$(echo $movie_title | awk '{print $1}')
            
            if ! grep "^$section:^(" "$BLOCKFILE" \
                | sed -E 's#^.*:\^\(([^)]*)\)\[._-].*#\1#' \
                | tr '|' '\n' \
                | grep -Fxq "$block_word"
            then
                
                addblock "$section" "$block_word"

            fi

        fi

        $GLROOT/bin/nuker -r "$GLCONF" -N "$NUKE_USER" -n "$RLS_NAME" "$NUKE_MULTIPLER" "Movies released before $NUKE_MOVIES_BEFORE_YEAR are not allowed"
        [[ -f "$GLROOT/bin/incomplete-list-nuker.sh" ]] && $GLROOT/bin/incomplete-list-nuker.sh store $RLS_NAME
        LogMsg "Nuked release: $RLS_NAME because its release year of $MOVIE_YEAR is before $NUKE_MOVIES_BEFORE_YEAR"
        exit 0

    fi

fi

if [[ "$NUKE_ORIGIN_COUNTRY" == "1" ]]
then

    if [[ -n "$NUKE_ORIGIN_COUNTRIES" ]]
    then

        for country in $NUKE_ORIGIN_COUNTRIES
        do

            if [[ "$MOVIE_COUNTRY" == "$country" ]]
            then

                if [[ "$NUKE_ADAPTIVE" == "1" ]]
                then

                    section=$(echo $RLS_NAME | cut -d'/' -f1-3)
                    # Extract movie title from release name
                    movie_title=$(echo $RLS_NAME | rev | cut -d'/' -f1 | rev | sed -E 's/\.[0-9]{4}\..*//' | sed 's/\./ /g')
                    block_word=$(echo $movie_title | awk '{print $1}')
                    
                    if ! grep "^$section:^(" "$BLOCKFILE" \
                        | sed -E 's#^.*:\^\(([^)]*)\)\[._-].*#\1#' \
                        | tr '|' '\n' \
                        | grep -Fxq "$block_word"
                    then

                        addblock "$section" "$block_word"

                    fi

                fi

                $GLROOT/bin/nuker -r "$GLCONF" -N "$NUKE_USER" -n "$RLS_NAME" "$NUKE_MULTIPLER" "Movies from $country are not allowed"
                [[ -f "$GLROOT/bin/incomplete-list-nuker.sh" ]] && $GLROOT/bin/incomplete-list-nuker.sh store $RLS_NAME
                LogMsg "Nuked release: $RLS_NAME because its country of origin is $MOVIE_COUNTRY which is not allowed."
                exit 0

            fi

        done

    fi

fi

if [[ "$NUKE_SECTION_LANGUAGE" == "1" ]]
then

    for rawdata in $NUKE_SECTION_LANGUAGES
    do

        section="$(echo "$rawdata" | cut -d ':' -f1)"
        allowed="$(echo "$rawdata" | cut -d ':' -f2)"

        if echo "$RLS_NAME" | grep -iq "$section/"
        then

            if ! echo "$MOVIE_LANGUAGE" | grep -Eiq "$allowed"
            then

                [[ "$MOVIE_LANGUAGE" == "null" ]] || [[ "$MOVIE_LANGUAGE" == "N/A" ]] && exit 0

                if [[ "$NUKE_ADAPTIVE" == "1" ]]
                then

                    # Extract movie title from release name
                    movie_title=$(echo $RLS_NAME | rev | cut -d'/' -f1 | rev | sed -E 's/\.[0-9]{4}\..*//' | sed 's/\./ /g')
                    block_word=$(echo $movie_title | awk '{print $1}')
                    
                    if ! grep "^$section:^(" "$BLOCKFILE" \
                        | sed -E 's#^.*:\^\(([^)]*)\)\[._-].*#\1#' \
                        | tr '|' '\n' \
                        | grep -Fxq "$block_word"
                    then
                        
                        addblock "$section" "$block_word"
                    
                    fi

                fi

                $GLROOT/bin/nuker -r "$GLCONF" -N "$NUKE_USER" -n "$RLS_NAME" "$NUKE_MULTIPLER" "Language $MOVIE_LANGUAGE is not allowed"
                [[ -f "$GLROOT/bin/incomplete-list-nuker.sh" ]] && $GLROOT/bin/incomplete-list-nuker.sh store $RLS_NAME
                LogMsg "Nuked release: $RLS_NAME because its language is $MOVIE_LANGUAGE which is not allowed in section $section."
                exit 0

            fi

        fi

    done

fi

if [[ "$NUKE_SECTION_RATING" == "1" ]]
then

    for rawdata in $NUKE_SECTION_RATINGS
    do

        section="$(echo "$rawdata" | cut -d ':' -f1)"
        limit="$(echo "$rawdata" | cut -d ':' -f2)"
        
        # Convert rating to integer (TMDB uses 0-10 scale, convert to 0-5 for consistency if needed)
        if [[ -n "$MOVIE_RATING" && "$MOVIE_RATING" != "N/A" ]]
        then
            rating="$(echo "$MOVIE_RATING" | awk '{print int($1+0.5)}')"
        else
            rating=0
        fi

        if echo "$RLS_NAME" | grep -iq "$section/"
        then

            if [[ -n "$MOVIE_RATING" && "$MOVIE_RATING" != "N/A" && "$rating" -lt "$limit" ]]
            then

                if [[ "$NUKE_ADAPTIVE" == "1" ]]
                then

                    # Extract movie title from release name
                    movie_title=$(echo $RLS_NAME | rev | cut -d'/' -f1 | rev | sed -E 's/\.[0-9]{4}\..*//' | sed 's/\./ /g')
                    block_word=$(echo $movie_title | awk '{print $1}')
                    
                    if ! grep "^$section:^(" "$BLOCKFILE" \
                        | sed -E 's#^.*:\^\(([^)]*)\)\[._-].*#\1#' \
                        | tr '|' '\n' \
                        | grep -Fxq "$block_word"
                    then
                        
                        addblock "$section" "$block_word"
                    
                    fi

                fi

                $GLROOT/bin/nuker -r "$GLCONF" -N "$NUKE_USER" -n "$RLS_NAME" "$NUKE_MULTIPLER" "Rating $MOVIE_RATING is below the limit of $limit"
                [[ -f "$GLROOT/bin/incomplete-list-nuker.sh" ]] && $GLROOT/bin/incomplete-list-nuker.sh store $RLS_NAME
                LogMsg "Nuked release: $RLS_NAME because its rating $MOVIE_RATING is below the limit of $limit for section $section."
                exit 0

            fi

        fi

    done

fi

if [[ "$NUKE_SECTION_STATUS" == "1" ]]
then

    for rawdata in $NUKE_SECTION_STATUS
    do

        section="$(echo "$rawdata" | cut -d ':' -f1)"
        denied="$(echo "$rawdata" | cut -d ':' -f2)"

        if echo "$RLS_NAME" | grep -iq "$section/"
        then

            if echo "$MOVIE_STATUS" | grep -Eiq "$denied"
            then

                [[ "$MOVIE_STATUS" == "null" ]] || [[ "$MOVIE_STATUS" == "N/A" ]] && exit 0

                if [[ "$NUKE_ADAPTIVE" == "1" ]]
                then

                    # Extract movie title from release name
                    movie_title=$(echo $RLS_NAME | rev | cut -d'/' -f1 | rev | sed -E 's/\.[0-9]{4}\..*//' | sed 's/\./ /g')
                    block_word=$(echo $movie_title | awk '{print $1}')
                    
                    if ! grep "^$section:^(" "$BLOCKFILE" \
                        | sed -E 's#^.*:\^\(([^)]*)\)\[._-].*#\1#' \
                        | tr '|' '\n' \
                        | grep -Fxq "$block_word"
                    then
                        
                        addblock "$section" "$block_word"
                    
                    fi

                fi

                $GLROOT/bin/nuker -r "$GLCONF" -N "$NUKE_USER" -n "$RLS_NAME" "$NUKE_MULTIPLER" "Movie status $MOVIE_STATUS is not allowed"
                [[ -f "$GLROOT/bin/incomplete-list-nuker.sh" ]] && $GLROOT/bin/incomplete-list-nuker.sh store $RLS_NAME
                LogMsg "Nuked release: $RLS_NAME because its status is $MOVIE_STATUS which is not allowed in section $section."
                exit 0

            fi

        fi

    done

fi

if [[ "$NUKE_MOVIE" == "1" ]]
then

    if [[ -n "$NUKE_MOVIES_LIST" ]]
    then

        for title in $NUKE_MOVIES_LIST
        do

            if echo "$RLS_NAME" | grep -iq "$title"
            then

                $GLROOT/bin/nuker -r "$GLCONF" -N "$NUKE_USER" -n "$RLS_NAME" "$NUKE_MULTIPLER" "Movie not allowed"
                [[ -f "$GLROOT/bin/incomplete-list-nuker.sh" ]] && $GLROOT/bin/incomplete-list-nuker.sh store $RLS_NAME
                LogMsg "Nuked release: $RLS_NAME because movie is not allowed."
                exit 0

            fi

        done

    fi

fi

if [[ "$NUKE_CLEAN_BLOCKLIST" -eq 1 ]]
then

    current_epoch=$(date +%s)
    declare -A seen
    to_delete=()

    while IFS= read -r row
    do

        blockdate=$(echo "$row" | cut -d ':' -f3)

        # Skip invalid dates
        if ! date --date "$blockdate" &>/dev/null
        then

            continue

        fi

        block_epoch=$(date +%s --date "$blockdate")
        days=$(( (current_epoch - block_epoch) / 86400 ))

        if [[ "$days" -ge "$BLOCKDAYS" ]]
        then

            LogMsg "Automatic removal of blocks with date $blockdate"

            if [[ -z "${seen[$blockdate]}" ]]
            then

                to_delete+=( "$blockdate" )
                seen[$blockdate]=1

            fi

        fi

    done < "$BLOCKFILE"

    if (( ${#to_delete[@]} > 0 ))
    then

        sed_script=
        for d in "${to_delete[@]}"
        do

            sed_script+="/$d/d;"

        done

        "$GLROOT/bin/sed" -i -e "$sed_script" "$BLOCKFILE"

    fi

fi