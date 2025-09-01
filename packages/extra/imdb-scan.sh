#!/bin/bash
VER=1.3
#--[ Info ]-----------------------------------------------------
#
# Creates genre and rank symlinks for movie sections based on
# IMDB tags created by psxc-imdb.
#
# Example cron:
#   0 1 * * *   /glftpd/bin/imdb-scan.sh index >/dev/null 2>&1
#
#--[ Settings ]-------------------------------------------------

glroot=/glftpd
tmp=$glroot/tmp

sections="
X264-1080:/site/X264-1080_MOVIES_SORTED
X265-2160:/site/X265-2160_MOVIES_SORTED
ARCHIVE/MOVIES/X264-1080:/site/ARCHIVE/MOVIES/X264-1080_MOVIES_SORTED
ARCHIVE/MOVIES/X265-2160:/site/ARCHIVE/MOVIES/X265-2160_MOVIES_SORTED
"

exclude="^\[NUKED\]-|^\[incomplete\]-|^\[no-nfo\]-|^\[no-sample\]-"

# Comment out or set empty to disable
sort_by_genre=Sorted.By.Genre
sort_by_rank=Sorted.By.Rank

log=$glroot/ftp-data/logs/imdb-scan.log

#--[ Script Start ]---------------------------------------------

logmsg()
{

    echo "$(date '+%Y-%m-%d %T') - $*" >> "$log"

}

safe_ln()
{

    local source=$1
    local target=$2

    mkdir -p "$(dirname "$target")"

    if command -v realpath >/dev/null 2>&1
    then

        local src_abs
        local tgt_dir_abs
        local rel_source

        src_abs=$(realpath "$source")
        tgt_dir_abs=$(realpath "$(dirname "$target")")
        rel_source=$(realpath --relative-to="$tgt_dir_abs" "$src_abs")
        ln -sf "$rel_source" "$target"

    else

        echo "realpath is required but not installed." >&2
        exit 1

    fi

}

#--[ Script Start ]---------------------------------------------#

if [[ -z $1 ]]
then

    echo "$0 index - to create the symlinks"
    exit 1

fi

if [[ $1 == index ]]
then

    if [[ ! -f $log ]]
    then

        touch "$log"
        chmod 666 "$log"

    fi

    while IFS=: read -r section symlink
    do

        if [[ ! -d $glroot/site/$section ]]
        then

            continue

        fi

        logmsg "Creating symlinks for section $section: please wait..."

        for dir in $(ls "$glroot/site/$section" | grep -Ev "$exclude")
        do

            # Extract rank (integer part of Score_X or NA)
            rank=$(
                ls "$glroot/site/$section/$dir" \
                | grep -E IMDB \
                | grep -Eo "Score_(NA|[0-9]|[0-9]\.[0-9])" \
                | cut -d "_" -f2 \
                | sed 's|\.[0-9]||'
            )

            # Extract year (unused below but kept for parity)
            year=$(
                ls "$glroot/site/$section/$dir" \
                | grep -E IMDB \
                | grep -Eo "([0-9]{4})" \
                | tr -d '()'
            )

            # Extract genres and normalize
            genres=$(
                ls "$glroot/site/$section/$dir" \
                | grep -E IMDB \
                | grep -o "Score_.*" \
                | sed -e 's/(.*//' \
                      -e 's/Score_\([0-9]\(\.[0-9]\)\?\|NA\)_-_//' \
                | sed -e 's/-/ /g' \
                      -e 's/Sci Fi/Sci-Fi/' \
                      -e 's/Sci/Sci-Fi/' \
                      -e 's/Sci-Fi-Fi/Sci-Fi/' \
                      -e 's/_//g' \
                      -e 's/Score//'
            )

            for genre in $genres
            do

                if [[ -n $sort_by_genre && -n $genre ]]
                then

                    if [[ ! -d $glroot$symlink/$sort_by_genre/$genre ]]
                    then

                        logmsg "Creating genre dir $glroot$symlink/$sort_by_genre/$genre"
                        mkdir -pm777 "$glroot$symlink/$sort_by_genre/$genre"

                    fi

                    if [[ ! -L $glroot$symlink/$sort_by_genre/$genre/$dir ]]
                    then

                        logmsg "Creating symlink $glroot$symlink/$sort_by_genre/$genre/$dir"
                        safe_ln "$glroot/site/$section/$dir" "$glroot$symlink/$sort_by_genre/$genre/$dir"

                    fi

                fi

                if [[ -n $sort_by_rank && -n $rank ]]
                then

                    if [[ ! -d $glroot$symlink/$sort_by_rank/$rank ]]
                    then

                        logmsg "Creating rank dir $glroot$symlink/$sort_by_rank/$rank"
                        mkdir -pm777 "$glroot$symlink/$sort_by_rank/$rank"

                    fi

                    if [[ ! -L $glroot$symlink/$sort_by_rank/$rank/$dir ]]
                    then

                        logmsg "Creating symlink $glroot$symlink/$sort_by_rank/$rank/$dir"
                        safe_ln "$glroot/site/$section/$dir" "$glroot$symlink/$sort_by_rank/$rank/$dir"

                    fi

                fi

            done

        done

        logmsg "Doing cleanup of broken links in section $section"
        find "$glroot$symlink" -xtype l -exec rm -f {} +
        find "$glroot$symlink" -type d -empty -exec rm -rf {} +
        logmsg "Done"

    done <<< "$sections"

fi
