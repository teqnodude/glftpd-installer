#!/bin/bash
VER=1.7
#--[ Info ]-----------------------------------------------------
#
# TVMaze Rescanner by Teqno
#
# This script comes without any warranty, use it at your own risk.
#
# If you want to rescan your tv releases for TVMaze info then 
# this script is for you. It grabs info from TVMaze api and
# creates an .imdb file and tag file in each release with it.
#
#--[ Settings ]-------------------------------------------------

# Location of glftpd
GLROOT="/glftpd"

# Tmp folder under $GLROOT
TMP="/tmp"

# Recommended to run in debug mode before running, set to 0 to disable.
DEBUG=0

# Set sections that should be scanned. 
# Examples: 
# /site/section: <- rescan /site/section
# /site/section:1x <- rescan /site/section/subdir
# /site/section:2x <- rescan /site/section/subdir/subdir2
# /site/seciton:3x <- rescan /site/section/subdir/subdir2/subdir3
# 
SECTIONS="
/site/TV-FLEMISH:
"

# What to exclude from scanner
EXCLUDE="^\[NUKED\]-|^\[incomplete\]-|^\[no-nfo\]-|^\[no-sample\]-"

# Do you want to preserve date & time on scanned releases
PRESERVE=1

# Do you want to skip releases that already got a .imdb file
SKIP=1

#--[ Script Start ]---------------------------------------------

lockfile="$GLROOT$TMP/tvmaze-rescan.lock"

# Improved cleanup function
cleanup() 
{

    [[ -f "$GLROOT$TMP/tvmaze-rescan.tmp" ]] && rm -f "$GLROOT$TMP/tvmaze-rescan.tmp"
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

# Colors
if command -v tput > /dev/null; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    RESET=$(tput sgr0)
else
    RED=''; GREEN=''; YELLOW=''; RESET=''
fi

rescan()
{

    local TVMAZE_VER="$(grep 'VER=' $GLROOT/bin/tvmaze.sh | cut -d'=' -f2)"
    i=0
    
    for rls_name in $(ls $1 | grep -Ev "$EXCLUDE")
    do

		if [[ ! $rls_name =~ (S[0-9]{2}E[0-9]{2}|E[0-9]{2}|[0-9]{4}\.[0-9]{2}\.[0-9]{2}|Part\.[0-9]) ]]
		then
		
			echo "  Skip: $rls_name (no TV Show)"
			continue
	
		fi


		if [[ "$SKIP" -eq 1 && -e "$1/$rls_name/.imdb" ]]
		then
		
			echo "  Skip: $rls_name (has info already)"
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
	    | tr '#' '\n' > "$GLROOT$TMP/tvmaze-rescan.tmp"
	
		SHOW_ID=$(grep -m1 'id":'        "$GLROOT$TMP/tvmaze-rescan.tmp" | cut -d':' -f2   | tr -d '"}')
		SHOW_NAME=$(grep -m1 'name":'    "$GLROOT$TMP/tvmaze-rescan.tmp" | cut -d':' -f2   | tr -d '"}')
		if [[ -z "$SHOW_NAME" ]] || [[ "$SHOW_NAME" == "N/A" ]]
		then
			
			echo "  Skip: $rls_name (no info found on TVMaze)"
			
			# Be nice to API
			sleep 1
			continue
		fi
		SHOW_LANGUAGE=$(grep -m1 'language":' "$GLROOT$TMP/tvmaze-rescan.tmp" | cut -d':' -f2 | tr -d '"}')
		SHOW_STATUS=$(grep -m1 'status":'    "$GLROOT$TMP/tvmaze-rescan.tmp" | cut -d':' -f2 | tr -d '"}')
		SHOW_TYPE=$(grep -m1 'type":'        "$GLROOT$TMP/tvmaze-rescan.tmp" | cut -d':' -f2 | tr -d '"}')
		SHOW_RATING=$(grep -m1 'rating":'    "$GLROOT$TMP/tvmaze-rescan.tmp" | cut -d':' -f3 | tr -d '"}')
		SHOW_IMDB=$(grep -m1 'imdb":'        "$GLROOT$TMP/tvmaze-rescan.tmp" | cut -d':' -f2 | tr -d '"}')
		SHOW_URL=$(grep -m1 'url":'          "$GLROOT$TMP/tvmaze-rescan.tmp" | cut -d':' -f2- | tr -d '"}')
		SHOW_COUNTRY=$(grep -m1 'country":'  "$GLROOT$TMP/tvmaze-rescan.tmp" | cut -d':' -f3 | tr -d '"}')
		SHOW_PREMIERED=$(grep -m1 'premiered":' "$GLROOT$TMP/tvmaze-rescan.tmp" | cut -d':' -f2 | tr -d '"}' | sed 's/-.*//')
	
		# genres block: still 1 pass, but slightly leaner transforms
		SHOW_GENRES=$(
	    	sed -n '/"genres"/,/]/p' "$GLROOT$TMP/tvmaze-rescan.tmp" \
		    | tr -d '[]"' | tr '\n' ' ' \
		    | sed 's/.*genres://;s/^[[:space:]]*//;s/[[:space:]]*$//'
		)
	
		# summary cleanup: simpler tag strip; keep backslash removal
		SHOW_SUMMARY=$(
		    grep -m1 'summary":' "$GLROOT$TMP/tvmaze-rescan.tmp" \
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
			| tr '#' '\n' > "$GLROOT$TMP/tvmaze-rescan.tmp"
	    
		elif [[ $rls_name =~ ([0-9]{4})\.([0-9]{2})\.([0-9]{2}) ]]
		then
	    
	    	DATE="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
		    lynx --dump "https://api.tvmaze.com/shows/$SHOW_ID/episodesbydate?date=$DATE" \
			| sed -e 's|","|"#"|g' -e 's|],"|]#"|g' -e 's|},"|}#"|g' -e 's|",|"#|g' -e 's|,"|#"|g' \
			| tr '#' '\n' > "$GLROOT$TMP/tvmaze-rescan.tmp"
	    
		elif [[ $rls_name =~ Part\.([0-9]) ]]
		then
	    
	    	SEASON=1
		    EPISODE="${BASH_REMATCH[1]}"
		    lynx --dump "https://api.tvmaze.com/shows/$SHOW_ID/episodebynumber?season=$SEASON&number=$EPISODE" \
			| sed -e 's|","|"#"|g' -e 's|],"|]#"|g' -e 's|},"|}#"|g' -e 's|",|"#|g' -e 's|,"|#"|g' \
			| tr '#' '\n' > "$GLROOT$TMP/tvmaze-rescan.tmp"
		
		fi
	
		# Pull fields once (avoid repeating in each branch)
		if [[ -s "$GLROOT$TMP/tvmaze-rescan.tmp" ]]
		then
	    
		    EP_URL=$(grep -m1 'url":'      "$GLROOT$TMP/tvmaze-rescan.tmp" | cut -d':' -f2- | tr -d '"}')
		    EP_AIR_DATE=$(grep -m1 'airdate":' "$GLROOT$TMP/tvmaze-rescan.tmp" | cut -d':' -f2  | tr -d '"}')
	    
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
	
		# Create the output content once
		TVMAZE_INFO=$(cat <<- EOF
		============================ TVMAZE INFO v$TVMAZE_VER ================================
	    
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
	    
		============================ TVMAZE INFO v$TVMAZE_VER ================================
		EOF
		)
		if (( DEBUG == 1 ))
		then
    		echo "$TVMAZE_INFO"
		    i=$(($i + 1))
		else

		    IMDB_FILE="$1/$rls_name/.imdb"
		    echo "  Scanning dir: $1/$rls_name"
	    	echo "$TVMAZE_INFO" > "$IMDB_FILE"
		    rm -f "$1/$rls_name/"*TVMAZE*
	    	touch "$1/$rls_name/[TVMAZE]=-_Score_${SHOW_RATING}_-_${SHOW_GENRES}_-_(${SHOW_TYPE})_-=[TVMAZE]"
	    	chmod 666 "$1/$rls_name/[TVMAZE]=-_Score_${SHOW_RATING}_-_${SHOW_GENRES}_-_(${SHOW_TYPE})_-=[TVMAZE]"

			if [ "$PRESERVE" -eq 1 ]
			then

				dir="$1/$rls_name"
				ref_file=""
				
				# First try .nfo files
				for f in "$dir"/*.nfo
				do

					if [[ -f "$f" ]]
					then

						ref_file="$f"
						break

					fi

				done
				
				# If no .nfo found, try .rar files
				if [[ -z "$ref_file" ]]
				then

					for f in "$dir"/*.rar
					do
					
						if [[ -f "$f" ]]
						then
						
							ref_file="$f"
							break
						
						fi

					done

				fi
				
				# Apply timestamp if reference file exists
				if [[ -n "$ref_file" ]] && [[ -f "$ref_file" ]]
				then
				
					touch -mr "$ref_file" "$dir"
				
				fi

			fi
			
		    i=$(($i + 1))

		fi
		# Be nice to API
		sleep 1
    done

}

for section in $SECTIONS
do

    sec=$(echo $section | cut -d ':' -f1)
    depth=$(echo $section | cut -d ':' -f2)

    case $depth in
		3x)

			for subdir in $(ls $GLROOT$sec)
			do

				for subdir2 in $(ls $GLROOT$sec/$subdir)
				do

				for subdir3 in $(ls $GLROOT$sec/$subdir/$subdir2)
				do

					rescan "$GLROOT$sec/$subdir/$subdir2/$subdir3"

				done

				done

			done

			i=$(($i))
			echo
			echo "Total scanned directories: $i"
			;;

		2x)

			for subdir in $(ls $GLROOT$sec)
			do

				for subdir2 in $(ls $GLROOT$sec/$subdir)
				do

				rescan "$GLROOT$sec/$subdir/$subdir2"

				done

			done

			i=$(($i))
			echo
			echo "Total scanned directories: $i"
			;;

		1x)

			for subdir in $(ls $GLROOT$sec)
			do

				rescan "$GLROOT$sec/$subdir"

			done

			i=$(($i))
			echo
			echo "Total scanned directories: $i"
			;;
			
		*)

			rescan "$GLROOT$sec"
			i=$(($i))
			echo
			echo "Total scanned directories: $i"
			;;

    esac

done

