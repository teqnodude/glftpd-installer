#!/bin/bash
VER=1.3
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
log=$glroot/ftp-data/logs/incomplete-list-nuker.log
botconf=$glroot/sitebot/scripts/pzs-ng/ngBot.conf
releaseComplete=" Complete "

# cleaning of [NUKED]- releases
prefix="$(grep nukedir_style $glroot/etc/glftpd.conf | awk '{print $2}' | cut -d '-' -f1)-"
cache_file=$glroot/bin/incomplete-list-nuker.cache
cleannuked=1
nukeage=720

# Set to 1 to also nuke when complete but missing NFO
nonfo=1

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

if [[ "$cleannuked" -eq 1 ]]
then

    if [[ -f "$cache_file" ]]
    then

        current_time="$(date +%s)"

        while IFS= read -r line
        do

            if [[ "$line" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})\ ([0-9]{2}:[0-9]{2}:[0-9]{2}):(.+)$ ]]
            then

                date_str="${BASH_REMATCH[1]}"
                time_str="${BASH_REMATCH[2]}"
                release_path="${BASH_REMATCH[3]}"
                release_name="$(basename "$release_path")"
                relname="${release_name#\[NUKED\]-}"

                file_timestamp="$(date -d "$date_str $time_str" +%s 2>/dev/null)"

                if [[ -n "$file_timestamp" ]]
                then

                    age_seconds=$(( current_time - file_timestamp ))
                    age_minutes=$(( age_seconds / 60 ))

                    if [[ "$age_minutes" -gt "$nukeage" ]]
                    then

                        if [[ -d "$glroot$release_path" ]]
                        then

                            echo "Removing NUKED release older than ${nukeage} minutes: $release_path"
                            sed -i "\|$relname|d" "$cache_file"
                            rm -rf "$glroot$release_path"

                        fi

                    else

                        echo "NUKED release within age limit (${age_minutes}/${nukeage} minutes): $release_path"

                    fi

                fi

                [[ ! -d "$glroot$release_path" ]] && sed -i "\|$relname|d" "$cache_file"

            fi

        done < "$cache_file"
        
    else

        touch $cache_file && chmod 666 $cache_file

    fi

else

    echo "NUKED release cleaning is disabled (cleannuked=0)"

fi


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
        	reldir="$(echo $nukesite | awk -F '/' '{print $NF}')"
        	relname="$(echo $nukesite | sed "s|$reldir|$prefix$reldir|")"
        	
	        # Skip if Approved_by exists
    	    if [[ $(find "$target" -maxdepth 1 -type f -iname "Approved_by*" 2>/dev/null | wc -l) -ne 0 ]]
        	then
 
            	continue
 
	        fi

    	    comp="$(ls -1 "$target/" 2>/dev/null | grep -i "$releaseComplete" | head -1)"
        	percent="$(echo "$comp" | awk '{for(i=1;i<=NF;i++) if($i~/^[0-9]+%$/){print $i; exit}}')"

			# Pre-calc to avoid repeated find calls
			dir_old_count="$(find "$target" -maxdepth 0 -type d -mmin +"$minutes" 2>/dev/null | wc -l)"
			nfo_count="$(find "$target" -maxdepth 1 -type f -iname "*.nfo" 2>/dev/null | wc -l)"
			

			if [[ -n "$percent" && "$percent" != "100%" ]]
			then
			
				echo "$secname: ${secrel} is $percent complete."
				if [[ "$dir_old_count" -ne 0 ]]
				then
			
					echo "$now - Nuking incomplete release $secrel in section $secname" >> "$log"
					"$nukeprog" -r "$glconf" -N "$nukeuser" -n "$nukesite" "$multiplier" "$reason $age_str"
					echo "$now:$relname" >> "$cache_file"
			
				fi
				
			elif [[ ! -z "$comp" && "$nonfo" -eq 1 && "$nfo_count" -eq 0 ]]
			then
			
				echo "$secname: ${secrel} is complete but missing NFO."
				if [[ "$dir_old_count" -ne 0 ]]
				then
			
					echo "$now - Nuking no-nfo release $secrel in section $secname" >> "$log"
					"$nukeprog" -r "$glconf" -N "$nukeuser" -n "$nukesite" "$multiplier" "$reason $age_str"
					echo "$now:$relname" >> "$cache_file"
			
				fi				
			
			elif [[ -z "$comp" ]]
			then
			
				echo "$secname: ${secrel} has no progress marker (.sfv/Complete)."
				if [[ "$dir_old_count" -ne 0 ]]
				then
			
					echo "$now - Nuking release (no progress marker) $secrel in section $secname" >> "$log"
					"$nukeprog" -r "$glconf" -N "$nukeuser" -n "$nukesite" "$multiplier" "$reason $age_str"
					echo "$now:$relname" >> "$cache_file"
					
				fi
			
			fi


		done

    done

done

echo "No more incompletes found."
IFS="$IFSORIG"
