#!/bin/bash
VER=1.0
#--[ Info ]-----------------------------------------------------
#
# TMDB Symlink Maker by Teqno
#
# This script comes without any warranty, use it at your own risk.
#
# A script that creates genre symlinks for a section of movies from
# the IMDB/TMDB tag created by psxc-imdb and tmdb.
# 
# 0 1 * * *	  /glftpd/bin/tmdb-symlink-maker.sh >/dev/null 2>&1
#
#--[ Settings ]-------------------------------------------------

GLROOT=/glftpd
TMP=$GLROOT/tmp
SECTIONS="
ARCHIVE/MOVIES/X264-1080:/site/ARCHIVE/MOVIES/X264-1080_MOVIES_SORTED
"

EXCLUDE="^\[NUKED\]-|^\[incomplete\]-|^\[no-nfo\]-|^\[no-sample\]-"
# Comment out the lines below or leave them empty to disable them
SORT_BY_GENRE=Sorted.By.Genre
SORT_BY_RANK=Sorted.By.Rank
LOG=$GLROOT/ftp-data/logs/imdb-scan.log

#--[ Script Start ]---------------------------------------------


if [ ! -f "$LOG" ]
then

	touch $LOG && chmod 666 $LOG

fi

lockfile="$GLROOT$TMP/tmdb-symlink-maker.lock"

# Improved cleanup function
cleanup()
{

    [[ -f "$GLROOT$TMP/tmdb-symlink-maker.tmp" ]] && rm -f "$GLROOT$TMP/tmdb-symlink-maker.tmp"
    [[ -f "$lockfile" ]] && rm -f "$lockfile"
    exit

}

# Set trap to clean up on normal exit or signals
trap cleanup EXIT INT TERM

# Check if lockfile exists and contains a running process
if [[ -e "$lockfile" ]]
then

    if read -r pid < "$lockfile" && kill -0 "$pid" 2>/dev/null
    then

        echo "Process $pid is still running with lockfile $lockfile. Quitting."
        exit 0

    else

        echo "Stale lockfile found. Removing and continuing."
        rm -f "$lockfile"

    fi

fi

# Create lockfile with current PID
echo $$ > "$lockfile"


for path in $SECTIONS
do

	section=$(echo $path | cut -d ":" -f1)
	symlink=$(echo $path | cut -d ":" -f2)
	[ ! -d "$GLROOT/site/$section" ] && continue
	echo "$(date "+%Y-%m-%d %T") - Creating symlinks for section $section, please wait...." >> $LOG

	for dir in $(ls $GLROOT/site/$section | egrep -v "$EXCLUDE")
	do

		rank="$(ls $GLROOT/site/$section/$dir | grep -E "IMDB|TMDB" | egrep -o "Score_(NA|[0-9]|[0-9].[0-9])" | cut -d "_" -f2 | sed 's|.[0-9]||')"
	    year="$(ls $GLROOT/site/$section/$dir | grep -E "IMDB|TMDB" | egrep -o "([0-9][0-9][0-9][0-9])" | tr -s '()')"
		genres="$(ls $GLROOT/site/$section/$dir | grep -E "IMDB|TMDB" | grep -o "Score_.*" | sed -e 's/Score_([0-9.]\+)_-_//g' -e 's/Score_\([0-9]\(\.[0-9]\)\?\|NA\)_-_//g' -e 's/(.*//' -e 's/_-_/ /g' -e 's/-/ /g' -e 's/_/ /g' -e 's/Science Fiction/Sci-Fi/g' -e 's/Sci Fi/Sci-Fi/g' -e 's/ Sci / Sci-Fi /g' -e 's/ Sci$/ Sci-Fi/' -e 's/^Sci$/Sci-Fi/' | sed -E 's/\bSci\b/Sci-Fi/' | sed -e 's/Sci-Fi-Fi/Sci-Fi/g' -e 's/TV Movie//')"

		for genre in $genres
    	do

			if [ ! -z "$SORT_BY_GENRE" ] && [ ! -z "$genre" ]
			then

			    if [ ! -d "$GLROOT$symlink/$SORT_BY_GENRE/$genre" ]
				then
					echo "$(date "+%Y-%m-%d %T") - Creating genre dir $GLROOT$symlink/$SORT_BY_GENRE/$genre" >> $LOG
					mkdir -p $GLROOT$symlink/$SORT_BY_GENRE/$genre
			    fi

			    if [ ! -L "$GLROOT$symlink/$SORT_BY_GENRE/$genre/$dir" ]
			    then

					echo "$(date "+%Y-%m-%d %T") - Creating symlink $GLROOT$symlink/$SORT_BY_GENRE/$genre/$dir" >> $LOG
					target="$GLROOT$symlink/$SORT_BY_GENRE/$genre/$dir"
					source="$GLROOT/site/$section/$dir"
					mkdir -p "$(dirname "$target")"

					if command -v realpath >/dev/null 2>&1
					then

		    			src_abs=$(realpath "$source")
					    tgt_dir_abs=$(realpath "$(dirname "$target")")
					    rel_source=$(realpath --relative-to="$tgt_dir_abs" "$src_abs")

					else

		    			echo "Realpath is required but not installed. Please install coreutils (provides realpath) or adjust your script."
					    exit 1

					fi

					ln -sf "$rel_source" "$target"

			    fi
			    
			fi
			
	    done
	
	    if [ ! -z "$SORT_BY_RANK" ] && [ ! -z "$rank" ]
    	then

			if [ ! -d "$GLROOT$symlink/$SORT_BY_RANK/$rank" ]
			then
		    	echo "$(date "+%Y-%m-%d %T") - Creating rank dir $GLROOT$symlink/$SORT_BY_RANK/$rank" >> $LOG
			    mkdir -p $GLROOT$symlink/$SORT_BY_RANK/$rank
			fi

			if [ ! -L "$GLROOT$symlink/$SORT_BY_RANK/$rank/$dir" ]
			then

			    echo "$(date "+%Y-%m-%d %T") - Creating symlink $GLROOT$symlink/$SORT_BY_RANK/$rank/$dir" >> $LOG
			    target="$GLROOT$symlink/$SORT_BY_RANK/$rank/$dir"
	    		source="$GLROOT/site/$section/$dir"
		    	mkdir -p "$(dirname "$target")"

			    if command -v realpath >/dev/null 2>&1
		    	then
					src_abs=$(realpath "$source")
					tgt_dir_abs=$(realpath "$(dirname "$target")")
					rel_source=$(realpath --relative-to="$tgt_dir_abs" "$src_abs")

			    else

					echo "realpath is required but not installed. Please install coreutils (provides realpath) or adjust your script."
					exit 1

	    		fi

			    ln -sf "$rel_source" "$target"

			fi
	    fi
    
	done

	echo "$(date "+%Y-%m-%d %T") - Doing cleanup of broken links in section $section" >> $LOG
	find $GLROOT$symlink -xtype l -exec rm -f {} +
	find $GLROOT$symlink -type d -empty -exec rm -rf {} +
	echo "$(date "+%Y-%m-%d %T") - Done" >> $LOG

done
