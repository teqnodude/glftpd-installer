#!/bin/bash
VER=1.3
#--[ Settings ]-------------------------------------------------

glroot=/glftpd
cleanup=$glroot/bin/cleanup
botconf=/glftpd/sitebot/scripts/pzs-ng/ngBot.conf
releaseComplete=" Complete "

# set to 1 to list fully-complete releases that are missing an NFO
nonfo=1

#--[ Script ]---------------------------------------------------

red=4
grey=14
reset=

# derive sections from botconf if present
if [[ -n "$botconf" && -e "$botconf" ]]
then

    # Remove the wildcards from section paths for matching
    sections="$(grep -E '^set[[:space:]]+paths\(' "$botconf" | sed 's/^set paths(\(.*\))[[:space:]]\{1,\}"\(.*\)\*"/\1:\2/' | sed 's|\*||g' | sed 's|//$|/|' | sort)"

fi

if [[ -z "$sections" ]]
then

    echo "No sections configured (set \$botconf or \$sections)."
    exit 1

fi

IFSORIG="$IFS"
IFS=$'\n'

found=0

for section in $sections
do

    secname="$(echo "$section" | cut -d ':' -f 1)"
    secpaths="$(echo "$section" | cut -d ':' -f 2- | tr ' ' '\n')"

    for secpath in $secpaths
    do

        # Add glroot to section path for matching since cleanup outputs full paths
        full_secpath="$glroot$secpath"
        
        # Get results using the original parsing method
        results="$("$cleanup" "$glroot" 2>/dev/null | grep -E '^Incomplete' | tr '\"' '\n' | grep -F "$full_secpath" | grep -Ev '/Sample' | tr -s '/' | sort)"
        
        [[ -z "$results" ]] && continue

        for result in $results
        do

            # Extract relative path from full section path
            secrel="$(echo "$result" | sed "s|$full_secpath||" | sed 's|^/||')"
            
            # The target is the actual result path (already includes glroot)
            target="$result"

            # Approved_by gate - check if Approved_by file exists
            if [[ $(find "$target" -maxdepth 1 -type f -iname "Approved_by*" 2>/dev/null | wc -l) -ne 0 ]]
            then

                echo "DEBUG: Skipping $target - has Approved_by file" >&2
                continue

            fi

            # Check for completion status
            comp="$(ls -1 "$target/" 2>/dev/null | grep -i "$releaseComplete" | head -1)"
            percent="$(echo "$comp" | awk '{for(i=1;i<=NF;i++) if($i~/^[0-9]+%$/){print $i; exit}}')"

            if [[ -n "$percent" && "$percent" != "100%" ]]
            then

                echo "$secname:${red} ${secrel}${reset}${grey} is${red} $percent ${grey}complete.${reset}"
                ((found++))

            elif [[ ! -z "$comp" && "$nonfo" -eq 1 && "$nfo_count" -eq 0 ]]
            then

				echo "$secname:${red} ${secrel}${reset}${grey} is missing a NFO.${reset}"
				((found++))

            elif [[ -z "$comp" ]]
            then

            	echo "$secname:${red} ${secrel}${reset}${grey} has no sfv file or progress marker.${reset}"
                ((found++))

            fi

        done

    done

done

if (( found == 0 ))
then

    echo "No incomplete releases found."

else

    echo "Found $found incomplete release(s)."

fi

IFS="$IFSORIG"
