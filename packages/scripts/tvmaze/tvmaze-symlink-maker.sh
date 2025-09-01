#!/bin/bash
VER=1.1
#--[ Info ]-----------------------------------------------------#
# 
# A script that create genre symlinks for a section of series out 
# of the TVMAZE tag created by tvmaze.
# 
# 0 1 * * *	  /glftpd/bin/tvmaze-symlink-maker.sh index >/dev/null 2>&1
#		
#--[ Settings ]-------------------------------------------------#

glroot=/glftpd
tmp=$glroot/tmp
sections="
TV-720:/site/TV-720_SORTED
TV-1080:/site/TV-1080_SORTED
TV-2160:/site/TV-2160_SORTED
TV-HD:/site/TV-HD_SORTED
TV-NL:/site/TV-NL_SORTED
"
exclude="^\[NUKED\]-|^\[incomplete\]-|^\[no-nfo\]-|^\[no-sample\]-"
# Comment out the lines below or leave them empty to disable them
sort_by_genre=Sorted.By.Genre
sort_by_type=Sorted.By.Type
sort_by_rank=Sorted.By.Rank
#log=$glroot/ftp-data/logs/tvmaze-symlink-maker.log

#--[ Script Start ]---------------------------------------------#

if [[ -z "$1" ]]
then

    echo "./tvmaze-symlink-maker.sh index - to create the symlinks"

fi

if [[ "$1" = "index" ]]
then

    if [[ ! -z $log && ! -f $log ]]
    then

        touch $log && chmod 666 $log

    fi

    [[ -z "$log" ]] && log=/dev/null

    for path in $sections
    do

	section="$(echo $path | cut -d ":" -f1)"
	symlink="$(echo $path | cut -d ":" -f2)"

	[[ ! -d "$glroot/site/$section" ]] && continue
	echo "$(date "+%Y-%m-%d %T") - Creating symlinks for section $section, please wait...." >> $log

	for dir in $(ls $glroot/site/$section | egrep -v "$exclude")
	do

	    target_dir="$glroot/site/$section/$dir"
	    ls_output=$(ls "$target_dir")
	    
	    genre=$(
		echo "$ls_output" \
		| egrep -v "IMDB|COMPLETE" \
		| grep -o "Score_.*" \
		| sed -e 's/(.*//' -e 's/Score_10\|Score_\([0-9]\(\.[0-9]\)\?\|NA\)_-_//' \
		| tr -s "_" " " \
		| sed 's/ - / /g'
	    )
	    
	    type=$(
		echo "$ls_output" \
		| egrep -v "IMDB|COMPLETE" \
		| grep -o "(.*)" \
		| tr -d '()' \
		| tr -s " " "_"
	    )
	    
	    rank=$(
		echo "$ls_output" \
		| egrep -v "IMDB|COMPLETE" \
		| grep -o "Score_.*" \
		| cut -d '_' -f2 \
		| sed 's|.[0-9]||'
	    )
	    
            if [[ -n "${sort_by_genre}" && -n "${genre}" ]]
            then

                for gen in $genre
                do

                    target="$glroot$symlink/$sort_by_genre/$gen/$dir"
                    source="$glroot/site/$section/$dir"
                    target_dir="$(dirname "$target")"

                    if [[ ! -d "$target_dir" ]]
                    then

                        echo "$(date "+%Y-%m-%d %T") - Creating genre dir $target_dir" >> "$log"
                        mkdir -pm777 "$target_dir"

                    fi

                    if command -v realpath >/dev/null 2>&1
                    then

                        rel_source=$(realpath --relative-to="$target_dir" "$source")

                    else

                        echo "realpath is required for relative symlinks."
                        exit 1

                    fi

                    if [[ ! -L "$target" ]]
                    then

                        echo "$(date "+%Y-%m-%d %T") - Creating symlink $target -> $rel_source" >> "$log"
                        ln -sf "$rel_source" "$target"

                    fi

                done

            fi

	    if [[ -n "$sort_by_type" && -n "$type" ]]
            then

                target="$glroot$symlink/$sort_by_type/$type/$dir"
                source="$glroot/site/$section/$dir"
                target_dir="$(dirname "$target")"

                if [[ ! -d "$target_dir" ]]
                then

                    echo "$(date "+%Y-%m-%d %T") - Creating type dir $target_dir" >> "$log"
                    mkdir -pm777 "$target_dir"

                fi

                if command -v realpath >/dev/null 2>&1
                then

                    rel_source=$(realpath --relative-to="$target_dir" "$source")

                else

                    echo "realpath is required for relative symlinks."
                    exit 1

                fi

                if [[ ! -L "$target" ]]
                then

                    echo "$(date "+%Y-%m-%d %T") - Creating symlink $target -> $rel_source" >> "$log"
                    ln -sf "$rel_source" "$target"

                fi

            fi

            if [[ -n "$sort_by_rank" && -n "$rank" ]]
            then

                target="$glroot$symlink/$sort_by_rank/$rank/$dir"
                source="$glroot/site/$section/$dir"
                target_dir="$(dirname "$target")"

                if [[ ! -d "$target_dir" ]]
                then

                    echo "$(date "+%Y-%m-%d %T") - Creating rank dir $target_dir" >> "$log"
                    mkdir -pm777 "$target_dir"

                fi

                if command -v realpath >/dev/null 2>&1
                then

                    rel_source=$(realpath --relative-to="$target_dir" "$source")

                else

                    echo "realpath is required for relative symlinks."
                    exit 1

                fi

                if [[ ! -L "$target" ]]
                then

                    echo "$(date "+%Y-%m-%d %T") - Creating symlink $target -> $rel_source" >> "$log"
                    ln -sf "$rel_source" "$target"

                fi

            fi

 	done

	echo "$(date "+%Y-%m-%d %T") - Doing cleanup of broken links in section $section" >> $log
	find "$glroot$symlink" -xtype l -exec rm -f {} +
 	find "$glroot$symlink" -type d -empty -exec rm -rf {} +
	echo "$(date "+%Y-%m-%d %T") - Done" >> $log

    done

fi
