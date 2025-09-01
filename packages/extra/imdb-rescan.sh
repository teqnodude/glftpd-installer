#!/bin/bash
VER=1.2

#--[ Settings ]-------------------------------------------------

sections="
X264
"

glroot=/glftpd
tmp=/tmp
pid=/ftp-data/logs/psxc-imdb.log.pid
noimdbtag=no_imdb_tag.txt 
doublenfo=double_nfo.txt
timestamp=1
onlytime=0

#--[ Script start ]---------------------------------------------

if ! mkdir -p "$tmp" 2>/dev/null
then

    mkdir -p "$tmp"

fi

banner_width="90"

print_status_start()
{

    local prefix="$1"
    local text="$2"
    local status_text="please wait"
    local total_width=$banner_width
    local done_length=6  # Length of "[DONE]" with colors

    # Calculate the full text including prefix
    local full_text="${prefix}: ${text} "
    local full_text_length=${#full_text}
    local status_length=${#status_text}

    # Calculate dots needed
    local dots_needed=$((total_width - full_text_length - status_length - done_length -2))

    # Generate dots
    local dots=""
    if [ $dots_needed -gt 0 ]; then
        dots=$(printf '%*s' $dots_needed | tr ' ' '.')
    fi

    printf "%s%s %s " "$full_text" "$dots" "$status_text"

}


print_status_done()
{

    echo -e "[\e[32mDone\e[0m]"

}

wait_for_imdb_idle()
{

    print_status_start "Waiting for psxc-imdb to finish"
    
    sleep 5

    until [[ ! -s "$pid" ]]
    do

        sleep 2

    done

    print_status_done
    echo

}

if [[ "$onlytime" != 1 ]]
then

    for section in $sections
    do

        # Ensure fresh, existing index files
        : > "$tmp/$doublenfo"
        : > "$tmp/$noimdbtag"

        echo
        print_status_start "Creating $section index of releases missing IMDb tags"

        find "/site/$section" -mindepth 1 -maxdepth 1 -type d -print0 | while IFS= read -r -d '' dir
        do

            if ! find "$dir" -mindepth 1 -maxdepth 1 -printf '%f\n' | grep -Eq '\[IMDB\]='
            then

                shopt -s nullglob nocaseglob
                nfos=( "$dir"/*.nfo )
                shopt -u nocaseglob

                if (( ${#nfos[@]} == 1 ))
                then

                    if grep -qi 'imdb\.com' "${nfos[0]}"
                    then

                        echo "$dir" >> "$tmp/$noimdbtag"

                    fi

                fi

            fi

        done

        print_status_done
        echo

        if [[ -s "$tmp/$noimdbtag" ]]
        then

            print_status_start "Cleaning $section index (removing symlinks, subfixes, and dirfixes)"
            sed -i '/no-nfo\|subfix\|dirfix/Id' "$tmp/$noimdbtag"
            print_status_done
            echo

            print_status_start "Rescanning releases from the cleaned $section"

            while IFS= read -r x
            do

                cd "$x" || continue

                shopt -s nullglob nocaseglob
                nfos=( ./*.nfo )
                shopt -u nocaseglob

                if (( ${#nfos[@]} > 1 ))
                then

                    echo "$x" >> "$tmp/$doublenfo"

                fi

                if (( ${#nfos[@]} >= 1 ))
                then

                    nfo="${nfos[0]}"

                    if grep -qi 'imdb\.com' "$nfo"
                    then

                        echo "1" > /ftp-data/logs/psxc-imdb-rescan.tmp
                        /bin/psxc-imdb.sh "$nfo"

                    fi

                fi

                cd - >/dev/null || true

            done < "$tmp/$noimdbtag"

			print_status_done
            echo

        else

            echo "No candidates found for section $section"
            echo

        fi

    done

    if [[ "$timestamp" = 1 ]]
    then
    
    	wait_for_imdb_idle

        for section in $sections
        do

            print_status_start "Fixing timestamps for $section"
            cd "/site/$section" || { print_status_done; continue; }

            for dir in /site/$section/*
            do

                [[ -d "$dir" ]] || continue

                file="$(ls -tp -- "$dir" | grep -v '/$' | sed -n '3p')"

                if [[ -n "$file" ]]
                then

                    touch -mr "$dir/$file" "$dir"

                fi

            done

            print_status_done
            echo

        done

    fi

else

    if [[ "$timestamp" = 1 ]]
    then
    
        for section in $sections
        do

            print_status_start "Fixing timestamps for $section"
            cd "/site/$section" || { print_status_done; continue; }

            for dir in /site/$section/*
            do

                [[ -d "$dir" ]] || continue

                file="$(ls -tp -- "$dir" | grep -v '/$' | sed -n '3p')"

                if [[ -n "$file" ]]
                then

                    touch -mr "$dir/$file" "$dir"

                fi

            done

            print_status_done
            echo

        done

    fi

fi
