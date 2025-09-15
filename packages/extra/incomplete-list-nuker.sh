#!/bin/bash
VER=1.2
#--[ Settings ]-------------------------------------------------

glroot=/glftpd
cleanup=$glroot/bin/cleanup
nukeprog=$glroot/bin/nuker
nukeuser=glftpd
reason="-Auto- Not completed for"
multiplier=5
glconf=$glroot/etc/glftpd.conf
now="$(date +%Y-%m-%d" "%H:%M:%S)"
minutes=720

# Set to 1 to also nuke when complete but missing NFO
nonfo=1

log=$glroot/ftp-data/logs/incomplete-list-nuker.log
botconf=$glroot/sitebot/scripts/pzs-ng/ngBot.conf
releaseComplete="Complete -"

#--[ Script Start ]---------------------------------------------

lockfile="$glroot/tmp/incomplete-list-nuker.lock"
if [[ -f "$lockfile" && -n "$(find "$lockfile" -mmin +20 -type f 2>/dev/null)" ]]
then
    rm -f "$lockfile"
fi

if [[ -e "$lockfile" ]]
then

    echo "Check already running"
    exit 0

fi

trap 'rm -f "$lockfile"' EXIT INT TERM
: > "$lockfile"

#--[ Preconditions ]--------------------------------------------

if [[ ! -x "$cleanup" || ! -x "$nukeprog" ]]
then

    echo "Missing binaries: cleanup or nuker."
    exit 1

fi

# derive sections from botconf if present
if [[ -n "$botconf" && -e "$botconf" ]]
then

    # Remove the wildcards from section paths for matching and fix double slashes
    sections="$(grep -E '^set[[:space:]]+paths\(' "$botconf" \
        | sed -E 's/^set paths\((.*)\)[[:space:]]+"(.*)\*"/\1:\2/' \
        | sed -E 's|\*||g;s|//$|/|' | sort)"

fi

if [[ -z "$sections" ]]
then

    echo "No sections configured (set \$botconf or \$sections)."
    exit 1

fi

#--[ Functions ]------------------------------------------------

duration_str()
{

    local mins=$1
    local h=$(( mins / 60 ))
    local m=$(( mins % 60 ))

    if (( mins < 60 ))
    then

        echo "$mins minute$([[ $mins -eq 1 ]] && echo "" || echo s)"

    elif (( m == 0 ))
    then

        echo "$h hour$([[ $h -eq 1 ]] && echo "" || echo s)"

    else

        echo "$h hour$([[ $h -eq 1 ]] && echo "" || echo s) $m minute$([[ $m -eq 1 ]] && echo "" || echo s)"

    fi

}

#--[ Main ]-----------------------------------------------------

age_str="$(duration_str "$minutes")."

IFSORIG="$IFS"
IFS=$'\n'

for section in $sections
do

    secname="$(echo "$section" | cut -d ':' -f 1)"
    secpaths="$(echo "$section" | cut -d ':' -f 2- | tr ' ' '\n')"
    
	for secpath in $secpaths
    do

        # Add glroot to section path for matching since cleanup outputs full paths
        full_secpath="$glroot$secpath"

        # Get results using the same parsing method as incomplete-list.sh
        results="$("$cleanup" "$glroot" 2>/dev/null | grep -E '^Incomplete' | tr '\"' '\n' | grep -F "$full_secpath" | grep -Ev '/Sample' | tr -s '/' | sort)"

    	[[ -z "$results" ]] && continue

	    for result in $results
    	do

	        secrel="$(echo "$result" | sed "s|$full_secpath||" | sed 's|^/||')"
    	    target="$result"
        	nukesite="${result#$glroot}"

	        # Skip if Approved_by exists
    	    if [[ $(find "$target" -maxdepth 1 -type f -iname "Approved_by*" 2>/dev/null | wc -l) -ne 0 ]]
        	then
 
            	continue
 
	        fi

    	    comp="$(ls -1 "$target/" 2>/dev/null | grep -F "$releaseComplete" | head -1)"
        	percent="$(echo "$comp" | awk '{for(i=1;i<=NF;i++) if($i~/^[0-9]+%$/){print $i; exit}}')"

	        if [[ -n "$percent" && "$percent" != "100%" ]]
    	    then

	            echo "$secname: ${secrel} is $percent complete."
	            if [[ $(find "$target" -maxdepth 0 -type d -mmin +$minutes 2>/dev/null | wc -l) -ne 0 ]]
	            then

	                echo "$now - Nuking incomplete release $secrel in section $secname" >> "$log"
	                "$nukeprog" -r "$glconf" -N "$nukeuser" -n "$nukesite" "$multiplier" "$reason $age_str"

	            fi

	        elif [[ -z "$percent" ]]
	        then

	            echo "$secname: ${secrel} has no progress marker (.sfv/Complete)."
	            if [[ $(find "$target" -maxdepth 0 -type d -mmin +$minutes 2>/dev/null | wc -l) -ne 0 ]]
	            then

	                echo "$now - Nuking release (no progress marker) $secrel in section $secname" >> "$log"
	                "$nukeprog" -r "$glconf" -N "$nukeuser" -n "$nukesite" "$multiplier" "$reason $age_str"

	            fi

	        elif (( nonfo == 1 )) && [[ $(find "$target" -maxdepth 1 -type f -iname "*.nfo" 2>/dev/null | wc -l) -eq 0 ]]
	        then

	            echo "$secname: ${secrel} is complete but missing NFO."
	            if [[ $(find "$target" -maxdepth 0 -type d -mmin +$minutes 2>/dev/null | wc -l) -ne 0 ]]
	            then

	                echo "$now - Nuking no-nfo release $secrel in section $secname" >> "$log"
	                "$nukeprog" -r "$glconf" -N "$nukeuser" -n "$nukesite" "$multiplier" "$reason $age_str"

	            fi

	        fi

		done

    done

done

echo "No more incompletes found."
IFS="$IFSORIG"
