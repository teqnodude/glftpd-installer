#!/bin/bash
VER=1.2
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
nonfo=1

#--[ Script ]---------------------------------------------------

# derive sections from botconf if present
if [[ -n "$botconf" && -e "$botconf" ]]
then

    sections="$(grep -E '^set[[:space:]]+paths\(' "$botconf" | sed 's/^set paths(\(.*\))[[:space:]]\{1,\}"\(.*\)\*"/\1:\2/' | sed 's|\*||g' | sed 's|//$|/|' | sort)"

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
            comp="$(ls -1 "$target/" 2>/dev/null | grep -F "$releaseComplete" | head -1)"
            percent="$(echo "$comp" | awk '{for(i=1;i<=NF;i++) if($i~/^[0-9]+%$/){print $i; exit}}')"
            to_link=""

            if [[ -n "$percent" && "$percent" != "100%" ]]
            then

                echo "$secname: ${secrel} is $percent complete."
                to_link=1

            elif [[ -z "$percent" ]]
            then

                echo "$secname:${secrel} has no sfv file or progress marker."
                to_link=1

            elif (( nonfo == 1 )) && [[ $(find "$target" -maxdepth 1 -type f -iname "*.nfo" 2>/dev/null | wc -l) -eq 0 ]]
            then

                echo "$secname:${secrel} is missing a NFO."
                to_link=1

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

IFS="$IFSORIG"
