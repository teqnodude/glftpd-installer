#!/bin/bash
VER=1.1
#--[ Info ]-----------------------------------------------------
#
# Put in crontab:
# * * * * * /glftpd/bin/incomplete-list-symlinks.sh >/dev/null 2>&1
#
#--[ Settings ]-------------------------------------------------

glroot=/glftpd
cleanup=$glroot/bin/cleanup
botconf=/glftpd/sitebot/scripts/pzs-ng/ngBot.conf
sections=""
releaseComplete="Complete -"

# create symlinks under /site/$incomplete
create=1
incomplete=INCOMPLETES

# set to 1 to also symlink fully-complete releases that are missing an NFO
nonfo=0

#--[ Script ]---------------------------------------------------

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

# ensure symlink dir
if (( create == 1 ))
then

    if [[ ! -e "$glroot/site/$incomplete" ]]
    then

        mkdir "$glroot/site/$incomplete"

    fi

    rm -f "$glroot/site/$incomplete/"*

fi

# run cleanup once and reuse (keep /Subs for special linking; exclude /Sample)
cleanup_raw="$("$cleanup" "$glroot" 2>/dev/null)"
cleanup_lines="$(printf '%s\n' "$cleanup_raw" | grep -E '^Incomplete' | tr '\"' '\n' | grep -Ev '/Sample' | tr -s '/' | sort)"

IFSORIG="$IFS"
IFS=$'\n'

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

            to_link=""

            if [[ -n "$percent" && "$percent" != "100%" ]]
            then

                echo "$secname: $secrel is $percent complete."
                to_link=1

            else

                if [[ -z "$percent" ]]
                then

                    echo "$secname: $secrel has no progress marker."
                    to_link=1

                elif (( nonfo == 1 )) && [[ $(find "$target" -maxdepth 1 -type f -iname "*.nfo" | wc -l) -eq 0 ]]
                then

                    echo "$secname: $secrel is complete but missing NFO."
                    to_link=1

                fi

            fi

            if [[ -n "$to_link" && "$create" -eq 1 ]]
            then

                # special handling for /Subs child
                if [[ "$secrel" == *"/Subs/"* || "$secrel" == *"/Subs"* ]]
                then

                    release="$(echo "$secrel" | cut -d "/" -f1)"
                    subs="$(echo "$secrel" | cut -d "/" -f2)"
                    ln -s "../$secname/$release/$subs" "$glroot/site/$incomplete/$release-$subs"
                    find "$glroot/site/$secname/$release" -type l -exec rm -f {} +

                else

                    # name symlink by last path component
                    linkname="$(basename "$secrel")"
                    ln -s "../$secname/$secrel" "$glroot/site/$incomplete/$linkname"
                    find "$glroot/site/$secname/$secrel" -type l -exec rm -f {} +

                fi

            fi

        done

    done

done

echo "No more incompletes found."
IFS="$IFSORIG"
exit 0
