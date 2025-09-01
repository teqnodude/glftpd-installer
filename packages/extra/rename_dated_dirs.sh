#!/bin/bash
VER=1.1
#--[ Info ]-----------------------------------------------------
#                                                               
# Rename script created by Teqno for the purpose of changing    
# format of dated dirs from MMDD to YYYY-MM-DD                  
#                                                               
#--[ Settings ]-------------------------------------------------

path=/glftpd/site
sections="0DAY EBOOKS FLAC MP3 XXX-PAYSITE"
today=$(date +%m%d)
tomorrow=$(date +%m%d)
thisyear=$(date +%Y)
lastyear=$(date +%Y --date "-1 year")

#--[ Script start ]---------------------------------------------

for section in $sections
do

    if [[ ! -d "$path/$section" ]]
    then

        echo "Section $section do not exist, skipping..."
        continue

    fi

    cd "$path/$section" || continue

    for x in *
    do

        [[ -d $x ]] || continue

        if [[ ! $x =~ ^-?[0-9]+$ ]]
        then

            echo "Dated dir $x is not of old format, skipping..."
            continue

        fi

        if (( $x >= $tomorrow ))
        then

            new="$lastyear-$(echo "$x" | sed 's/[0-9][0-9]/&-/')"
            mv "$path/$section/$x" "$path/$section/$new"

        fi

        if (( $x <= $today ))
        then

            new="$thisyear-$(echo "$x" | sed 's/[0-9][0-9]/&-/')"
            mv "$path/$section/$x" "$path/$section/$new"

        fi

    done

done
