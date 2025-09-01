#!/bin/bash
VER=1.1
#--[ Settings ]-------------------------------------------------

glroot=/glftpd
cleanup=$glroot/bin/cleanup
nukeprog=$glroot/bin/nuker
nukeuser=glftpd
reason="-Auto- Not completed for"
multiplier=5
glconf=$glroot/etc/glftpd.conf
now="$( date +%Y-%m-%d" "%H:%M:%S )"
minutes=720

# Set to 1 to also nuke when complete but missing NFO
nonfo=0

log=$glroot/ftp-data/logs/incomplete-list-nuker.log
botconf=/glftpd/sitebot/scripts/pzs-ng/ngBot.conf
sections=""
releaseComplete="Complete -"

#--[ Script Start ]---------------------------------------------

lockfile="$glroot/tmp/incomplete-list-nuker.lock"
[[ -f "$lockfile" ]] && [[ -n "$(find "$lockfile" -mmin +20 -type f 2>/dev/null)" ]] && rm -f "$lockfile"

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

if [[ -n "$botconf" && -e "$botconf" ]]
then

    sections="$(grep -E '^set[[:space:]]+paths\(' "$botconf" | sed 's/^set paths(\(.*\))[[:space:]]\{1,\}"\(.*\)\*"/\1:\2/')"

fi

if [[ -z "$sections" ]]
then

    echo "No sections configured (set \$botconf or \$sections)."
    exit 1

fi

#--[ Main ]-----------------------------------------------------

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

age_str="$(duration_str "$minutes")."

IFSORIG="$IFS"
IFS=$'\n'

for section in $sections
do

    secname="$(echo "$section" | cut -d ':' -f 1)"
    secpaths="$(echo "$section" | cut -d ':' -f 2- | tr ' ' '\n')"

    for secpath in $secpaths
    do

        results="$("$cleanup" "$glroot" 2>/dev/null \
                    | grep -E '^Incomplete' \
                    | tr '\"' '\n' \
                    | grep -F "$secpath" \
                    | grep -Ev '/Sample|/Subs' \
                    | tr -s '/' \
                    | sort)"

        if [[ -z "$results" ]]
        then

            continue

        fi

        for result in $results
        do

            secrel="$(echo "$result" | sed "s|$secpath||" | tr -s '/' | sed "s|$glroot||")"
            target="$glroot/site/$secname/$secrel"
            nukesite="/site/$secname/$secrel"

            comp="$(ls -1 "$result"/ 2>/dev/null | grep -F "$releaseComplete")"
            percent="$(awk '{for(i=1;i<=NF;i++) if($i~/^[0-9]+%$/){print $i; exit}}' <<< "$comp")"

            if [[ -n "$percent" && "$percent" != "100%" ]]
            then

                echo "$secname: ${secrel} is $percent complete."
                if [[ $(find "$target" -maxdepth 0 -type f -iname "Approved_by*" | wc -l) == 0 ]]
                then

                    find "$target" -maxdepth 0 -type d -mmin +$minutes \
                        -exec sh -c 'echo "'"$now"' - Nuking incomplete release '"$secrel"' in section '"$secname"'" >> "'"$log"'"' ';' \
                        -exec "$nukeprog" -r "$glconf" -N "$nukeuser" -n "$nukesite" "$multiplier" "$reason $age_str" ';'

                fi

            else

                if [[ -z "$percent" ]]
                then

                    echo "$secname: ${secrel} has no .sfv file."
                    if [[ $(find "$target" -maxdepth 0 -type f -iname "Approved_by*" | wc -l) == 0 ]]
                    then

                        find "$target" -maxdepth 0 -type d -mmin +$minutes \
                            -exec sh -c 'echo "'"$now"' - Nuking release (no progress marker) '"$secrel"' in section '"$secname"'" >> "'"$log"'"' ';' \
                            -exec "$nukeprog" -r "$glconf" -N "$nukeuser" -n "$nukesite" "$multiplier" "$reason $age_str" ';'

                    fi

                else

                    # percent == 100% (complete); optionally nuke if missing NFO
                    if (( nonfo == 1 )) && [[ $(find "$target" -maxdepth 1 -type f -iname "*.nfo" | wc -l) == 0 ]]
                    then

                        echo "$secname: ${secrel} is missing NFO."
                        if [[ $(find "$target" -maxdepth 0 -type f -iname "Approved_by*" | wc -l) == 0 ]]
                        then

                            find "$target" -maxdepth 0 -type d -mmin +$minutes \
                                -exec sh -c 'echo "'"$now"' - Nuking no-nfo release '"$secrel"' in section '"$secname"'" >> "'"$log"'"' ';' \
                                -exec "$nukeprog" -r "$glconf" -N "$nukeuser" -n "$nukesite" "$multiplier" "$reason $age_str" ';'

                        fi

                    fi

                fi

            fi

        done

    done

done

echo "No more incompletes found."
IFS="$IFSORIG"
