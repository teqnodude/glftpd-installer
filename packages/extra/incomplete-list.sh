#!/bin/bash
VER=1.0
#--[ Settings ]-------------------------------------------------

glroot=/glftpd
cleanup=$glroot/bin/cleanup
botconf=/glftpd/sitebot/scripts/pzs-ng/ngBot.conf
sections=""
releaseComplete="Complete -"

# set to 1 to list fully-complete releases that are missing an NFO
nonfo=0

#--[ Script ]---------------------------------------------------

colors=$(tput colors 2>/dev/null || echo 0)
if (( colors >= 16 ))
then

    red="$(tput setaf 9)"

else

    red="$(tput bold; tput setaf 1)"

fi
grey="$(tput setaf 8 2>/dev/null)"

# derive sections from botconf if present
if [[ -n "$botconf" && -e "$botconf" ]]
then

    sections="$(grep -E '^set[[:space:]]+paths\(' "$botconf" | sed 's/^set paths(\(.*\))[[:space:]]\{1,\}"\(.*\)\*"/\1:\2/' | sort)"

fi

if [[ -z "$sections" ]]
then

    echo "No sections configured (set \$botconf or \$sections)."
    exit 1

fi

# run cleanup once and reuse
cleanup_raw="$("$cleanup" "$glroot" 2>/dev/null)"
cleanup_lines="$(printf '%s\n' "$cleanup_raw" | grep -E '^Incomplete' | tr '\"' '\n' | grep -Ev '/Sample' | tr -s '/' | sort)"

IFSORIG="$IFS"
IFS=$'\n'

found=0

for section in $sections
do

    secname="$(echo "$section" | cut -d ':' -f 1)"
    secpaths="$(echo "$section" | cut -d ':' -f 2- | tr ' ' '\n')"

    for secpath in $secpaths
    do

        results="$(printf '%s\n' "$cleanup_lines" | grep -F "$secpath")"
        [[ -z "$results" ]] && continue

        for result in $results
        do

            secrel="$(echo "$result" | sed "s|$secpath||" | tr -s '/' | sed "s|$glroot||")"
            target="$glroot/site/$secname/$secrel"

            # Approved_by gate
            if [[ $(find "$target" -maxdepth 0 -type f -iname "Approved_by*" | wc -l) -ne 0 ]]
            then

                continue

            fi

            comp="$(ls -1 "$result"/ 2>/dev/null | grep -F "$releaseComplete")"
            percent="$(awk '{for(i=1;i<=NF;i++) if($i~/^[0-9]+%$/){print $i; exit}}' <<< "$comp")"

            if [[ -n "$percent" && "$percent" != "100%" ]]
            then

                echo "$secname:${red} ${secrel}${grey} is${red} $percent ${grey}complete."
                ((found++))

            else

                if [[ -z "$percent" ]]
                then

                    echo "$secname:${red} ${secrel}${grey} has no sfv file or progress marker."
                    ((found++))

                elif (( nonfo == 1 )) && [[ $(find "$target" -maxdepth 1 -type f -iname "*.nfo" | wc -l) -eq 0 ]]
                then

                    echo "$secname:${red} ${secrel}${grey} is missing a NFO."
                    ((found++))

                fi

            fi

        done

    done

done

if (( found == 0 ))
then

    echo "No incomplete releases found."

else

    echo "No more incompletes found."

fi

IFS="$IFSORIG"
