#!/bin/bash
VER=1.6
#--[ Info ]-----------------------------------------------------#
#
# This script comes without any warranty, use it at your own risk.
#
# If you want to rescan your tv releases for TVMaze info then 
# this script is for you. It grabs info from TVMaze api and
# creates an .imdb file and tag file in each release with it.
# 
# Changelog
# 2025-08-29 : v1.6 Improved version with better error handling, performance optimizations, and safer variable usage.
# 2024-03-15 : v1.5 Optimized scanning time when preserving date and time of release.
# 2021-03-25 : v1.4 Code for airdate was not properly set.
# 2021-03-03 : v1.3 Added option for maximum width for plot summary
#                   and added skip option for releases that already have a .imdb file.
# 2021-03-02 : v1.2 Now you can scan up to 3 dirs in depth and
#                   I've also included a check to only scan TV releases that match 
#                   set regex. Made some cosmetic changes too and included a check.
#                   to prevent double instances of script.
# 2021-03-01 : v1.1 Fixed releases with year and country code.
# 2021-02-28 : v1.0 Teqno original creator.
#
#--[ Settings ]-------------------------------------------------#

# Location of glftpd
glroot="/glftpd"

# Tmp folder under $glroot
tmp="/tmp"

# Recommended to run in debug mode before running, set to 0 to disable.
debug=1

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

lockfile="$glroot$tmp/tvmaze-rescan.lock"

# Improved cleanup function
cleanup() 
{

    [[ -f "$glroot$tmp/tvmaze-rescan.tmp" ]] && rm -f "$glroot$tmp/tvmaze-rescan.tmp"
    [[ -f "$lockfile" ]] && rm -f "$lockfile"
    exit

}

# Set trap to clean up on normal exit or signals
trap cleanup EXIT INT TERM

# Check if lockfile exists and contains a running process
if [[ -e "$lockfile" ]]
then

    if read -r pid < "$lockfile" && kill -0 "$pid" 2>/dev/null
    then
    
        echo "Process $pid is still running with lockfile $lockfile. Quitting."
        exit 0
    
    else
    
        echo "Stale lockfile found. Removing and continuing."
        rm -f "$lockfile"
    
    fi

fi

# Create lockfile with current PID
echo $$ > "$lockfile"

rescan()
{

    local TVMAZE_VER="$(grep 'VER=' $glroot/bin/tvmaze.sh | cut -d'=' -f2)"
    i=0
    
    for rls_name in $(ls $1 | grep -Ev "$exclude")
    do

	if [[ ! $rls_name =~ (S[0-9]{2}E[0-9]{2}|E[0-9]{2}|[0-9]{4}\.[0-9]{2}\.[0-9]{2}|Part\.[0-9]) ]]
	then
	
	  continue
	
	fi


	if [[ "$skip" -eq 1 && -e "$1/$rls_name/.imdb" ]]
	then

	    continue

	fi

	if [[ $rls_name =~ (.*\.(S[0-9]{2}E[0-9]{2}|E[0-9]{2}|[0-9]{4}\.[0-9]{2}\.[0-9]{2}|Part\.[0-9])\.?) ]]
	then
	
	    _base="${BASH_REMATCH[1]}"
	
	else
	
	    continue
	
	fi

	SHOW="${_base%%.S[0-9][0-9]*}"
	SHOW="${SHOW%%.Part*}"
	SHOW="${SHOW%%.[0-9][0-9][0-9][0-9]*}"
	SHOW="${SHOW%.AU*}"; SHOW="${SHOW%.CA*}"; SHOW="${SHOW%.NZ*}"; SHOW="${SHOW%.UK*}"; SHOW="${SHOW%.US*}"
	SHOW="${SHOW//./ }"
	
	lynx --dump "https://api.tvmaze.com/singlesearch/shows?q=$SHOW" \
	    | sed -e 's|","|"#"|g' -e 's|],"|]#"|g' -e 's|},"|}#"|g' -e 's|",|"#|g' -e 's|,"|#"|g' \
	    | tr '#' '\n' > "$glroot$tmp/tvmaze-rescan.tmp"
	
	SHOW_ID=$(grep -m1 'id":'        "$glroot$tmp/tvmaze-rescan.tmp" | cut -d':' -f2   | tr -d '"}')
	SHOW_NAME=$(grep -m1 'name":'    "$glroot$tmp/tvmaze-rescan.tmp" | cut -d':' -f2   | tr -d '"}')
	SHOW_LANGUAGE=$(grep -m1 'language":' "$glroot$tmp/tvmaze-rescan.tmp" | cut -d':' -f2 | tr -d '"}')
	SHOW_STATUS=$(grep -m1 'status":'    "$glroot$tmp/tvmaze-rescan.tmp" | cut -d':' -f2 | tr -d '"}')
	SHOW_TYPE=$(grep -m1 'type":'        "$glroot$tmp/tvmaze-rescan.tmp" | cut -d':' -f2 | tr -d '"}')
	SHOW_RATING=$(grep -m1 'rating":'    "$glroot$tmp/tvmaze-rescan.tmp" | cut -d':' -f3 | tr -d '"}')
	SHOW_IMDB=$(grep -m1 'imdb":'        "$glroot$tmp/tvmaze-rescan.tmp" | cut -d':' -f2 | tr -d '"}')
	SHOW_URL=$(grep -m1 'url":'          "$glroot$tmp/tvmaze-rescan.tmp" | cut -d':' -f2- | tr -d '"}')
	SHOW_COUNTRY=$(grep -m1 'country":'  "$glroot$tmp/tvmaze-rescan.tmp" | cut -d':' -f3 | tr -d '"}')
	SHOW_PREMIERED=$(grep -m1 'premiered":' "$glroot$tmp/tvmaze-rescan.tmp" | cut -d':' -f2 | tr -d '"}' | sed 's/-.*//')
	
	# genres block: still 1 pass, but slightly leaner transforms
	SHOW_GENRES=$(
	    sed -n '/"genres"/,/]/p' "$glroot$tmp/tvmaze-rescan.tmp" \
	    | tr -d '[]"' | tr '\n' ' ' \
	    | sed 's/.*genres://;s/^[[:space:]]*//;s/[[:space:]]*$//'
	)
	
	# summary cleanup: simpler tag strip; keep backslash removal
	SHOW_SUMMARY=$(
	    grep -m1 'summary":' "$glroot$tmp/tvmaze-rescan.tmp" \
	    | cut -d':' -f2- \
	    | tr -d '"' | tr -d '\\' \
	    | sed 's/<[^>]*>//g'
	)

	EP_URL=""
	EP_AIR_DATE=""
	
	# Decide which API to call (no subshells)
	if [[ $rls_name =~ S([0-9]{2})E([0-9]{2}) ]]
	then
	    
	    SEASON=$((10#${BASH_REMATCH[1]}))
	    EPISODE=$((10#${BASH_REMATCH[2]}))
	    lynx --dump "https://api.tvmaze.com/shows/$SHOW_ID/episodebynumber?season=$SEASON&number=$EPISODE" \
		| sed -e 's|","|"#"|g' -e 's|],"|]#"|g' -e 's|},"|}#"|g' -e 's|",|"#|g' -e 's|,"|#"|g' \
		| tr '#' '\n' > "$glroot$tmp/tvmaze-rescan.tmp"
	    
	elif [[ $rls_name =~ ([0-9]{4})\.([0-9]{2})\.([0-9]{2}) ]]
	then
	    
	    DATE="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
	    lynx --dump "https://api.tvmaze.com/shows/$SHOW_ID/episodesbydate?date=$DATE" \
		| sed -e 's|","|"#"|g' -e 's|],"|]#"|g' -e 's|},"|}#"|g' -e 's|",|"#|g' -e 's|,"|#"|g' \
		| tr '#' '\n' > "$glroot$tmp/tvmaze-rescan.tmp"
	    
	elif [[ $rls_name =~ Part\.([0-9]) ]]
	then
	    
	    SEASON=1
	    EPISODE="${BASH_REMATCH[1]}"
	    lynx --dump "https://api.tvmaze.com/shows/$SHOW_ID/episodebynumber?season=$SEASON&number=$EPISODE" \
		| sed -e 's|","|"#"|g' -e 's|],"|]#"|g' -e 's|},"|}#"|g' -e 's|",|"#|g' -e 's|,"|#"|g' \
		| tr '#' '\n' > "$glroot$tmp/tvmaze-rescan.tmp"
		
	fi
	
	# Pull fields once (avoid repeating in each branch)
	if [[ -s "$glroot$tmp/tvmaze-rescan.tmp" ]]
	then
	    
	    EP_URL=$(grep -m1 'url":'      "$glroot$tmp/tvmaze-rescan.tmp" | cut -d':' -f2- | tr -d '"}')
	    EP_AIR_DATE=$(grep -m1 'airdate":' "$glroot$tmp/tvmaze-rescan.tmp" | cut -d':' -f2  | tr -d '"}')
	    
	fi

	for var in SHOW_GENRES SHOW_COUNTRY SHOW_LANGUAGE SHOW_NETWORK SHOW_STATUS \
		SHOW_TYPE EP_AIR_DATE SHOW_RATING SHOW_IMDB SHOW_SUMMARY \
		SHOW_PREMIERED SHOW_URL EP_URL
	do
	
	    if [[ "${!var}" == "null" || -z "${!var}" ]]
	    then
	
		declare "$var=NA"
	
	    elif [[ "$var" == "SHOW_IMDB" && "${!var}" != "NA" ]]
	    then
	
		declare "$var=https://imdb.com/title/${!var}"
	
	    fi
	
	done
	
	if [ "$debug" -eq 1 ]
	then

	    # Output to console
	    cat <<- EOF
		============================ TVMAZE INFO v$TVMAZE_VER ================================
	    
		Location.....: $1
		Show id......: $SHOW_ID
		Releasename..: $rls_name
		Title........: $SHOW_NAME
		-
		IMDB Link....: $SHOW_IMDB
		TVMaze Link..: $SHOW_URL
		Episode Link.: $EP_URL
		Genre........: $SHOW_GENRES
		Type.........: $SHOW_TYPE
		User Rating..: $SHOW_RATING
		-
		Country......: $SHOW_COUNTRY
		Language.....: $SHOW_LANGUAGE
		Network......: $SHOW_NETWORK
		Status.......: $SHOW_STATUS
		Premiered....: $SHOW_PREMIERED
		Airdate......: $EP_AIR_DATE
		-
		Plot.........: $SHOW_SUMMARY
	    
		============================ TVMAZE INFO v$TVMAZE_VER ================================
		EOF
	    
	    i=$(($i + 1))

	else

	    IMDB_FILE="$1/$rls_name/.imdb"
	    echo "Scanning dir $i : $1/$rls_name"
	    cat <<- EOF > "$IMDB_FILE"
		============================ TVMAZE INFO v$TVMAZE_VER ================================
		
		Title........: $SHOW_NAME
		-
		IMDB Link....: $SHOW_IMDB
		TVMaze Link..: $SHOW_URL
		Episode Link.: $EP_URL
		Genre........: $SHOW_GENRES
		Type.........: $SHOW_TYPE
		User Rating..: $SHOW_RATING
		-
		Country......: $SHOW_COUNTRY
		Language.....: $SHOW_LANGUAGE
		Network......: $SHOW_NETWORK
		Status.......: $SHOW_STATUS
		Premiered....: $SHOW_PREMIERED
		Airdate......: $EP_AIR_DATE
		-
		Plot.........: $(echo "$SHOW_SUMMARY" | fold -s -w $width)
		
		============================ TVMAZE INFO v$TVMAZE_VER ================================
		EOF

	    #rm -f "$1/$rls_name/"*TVMAZE*
	    TAG_FILE="$1/$rls_name/[TVMAZE]=-_Score_${SHOW_RATING}_-_${SHOW_GENRES}_-_(${SHOW_TYPE})_-=[TVMAZE]"
	    touch "$TAG_FILE" && chmod 666 "$TAG_FILE"

	    if [ "$preserve" -eq 1 ]
	    then

		dir="$1/$rls_name"
		file="$(ls -t -- "$dir" | sed -n '3p')"
		[[ -n "$file" ]] &&  touch -mr "$dir/$file" "$dir"

	    fi

	    i=$(($i + 1))

	fi

    done

}

for section in $sections
do

    sec=$(echo $section | cut -d ':' -f1)
    depth=$(echo $section | cut -d ':' -f2)

    case $depth in
    3x)

	for subdir in $(ls $glroot$sec)
	do

	    for subdir2 in $(ls $glroot$sec/$subdir)
	    do

		for subdir3 in $(ls $glroot$sec/$subdir/$subdir2)
		do

		    rescan "$glroot$sec/$subdir/$subdir2/$subdir3"

		done

	    done

	done

        i=$(($i))
	echo
	echo "Total scanned directories: $i"	
	;;

    2x)
	for subdir in $(ls $glroot$sec)
	do
	
	    for subdir2 in $(ls $glroot$sec/$subdir)
	    do
	
		rescan "$glroot$sec/$subdir/$subdir2"
	
	    done
	
	done
        
        i=$(($i))
	echo
	echo "Total scanned directories: $i"		
	;;

    1x)

	for subdir in $(ls $glroot$sec)
	do

	    rescan "$glroot$sec/$subdir"

	done

	i=$(($i))
	echo
	echo "Total scanned directories: $i"	

        ;;
    *)

	rescan "$glroot$sec"
	i=$(($i))
	echo
	echo "Total scanned directories: $i"	
	;;

    esac

done

