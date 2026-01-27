#!/bin/bash
VER=1.2
#--[ Info ]----------------------------------------------------
# 
# TVMaze Symlink Maker by Teqno
# 
# This script comes without any warranty, use it at your own risk.
#
# A script that create genre symlinks for a section of series out 
# of the TVMAZE tag created by tvmaze.
# 
# 0 1 * * *	  /glftpd/bin/tvmaze-symlink-maker.sh >/dev/null 2>&1
#		
#--[ Settings ]------------------------------------------------

GLROOT=/glftpd
TMP=$GLROOT/tmp
SECTIONS="
TV-720:/site/TV-720_SORTED
"
EXCLUDE="^\[NUKED\]-|^\[incomplete\]-|^\[no-nfo\]-|^\[no-sample\]-"
# Comment out the lines below or leave them empty to disable them
SORT_BY_GENRE=Sorted.By.Genre
SORT_BY_TYPE=Sorted.By.Type
#SORT_BY_RANK=Sorted.By.Rank
#LOG=$GLROOT/ftp-data/logs/tvmaze-symlink-maker.log

#--[ Script Start ]--------------------------------------------

if [[ ! -z $LOG && ! -f $LOG ]]
then

	touch $LOG && chmod 666 $LOG

fi

[[ -z "$LOG" ]] && LOG=/dev/null

for path in $SECTIONS
do

	section="$(echo $path | cut -d ":" -f1)"
	symlink="$(echo $path | cut -d ":" -f2)"

	[[ ! -d "$GLROOT/site/$section" ]] && continue
	echo "$(date "+%Y-%m-%d %T") - Creating symlinks for section $section, please wait...." >> $LOG

	for dir in $(ls $GLROOT/site/$section | egrep -v "$EXCLUDE")
	do

		target_dir="$GLROOT/site/$section/$dir"
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
		
		if [[ -n "${SORT_BY_GENRE}" && -n "${genre}" ]]
		then

			for gen in $genre
			do

				target="$GLROOT$symlink/$SORT_BY_GENRE/$gen/$dir"
				source="$GLROOT/site/$section/$dir"
				target_dir="$(dirname "$target")"

				if [[ ! -d "$target_dir" ]]
				then

					echo "$(date "+%Y-%m-%d %T") - Creating genre dir $target_dir" >> "$LOG"
					mkdir -p "$target_dir"

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

					echo "$(date "+%Y-%m-%d %T") - Creating symlink $target -> $rel_source" >> "$LOG"
					ln -sf "$rel_source" "$target"

				fi

			done

		fi

		if [[ -n "$SORT_BY_TYPE" && -n "$type" ]]
		then

			target="$GLROOT$symlink/$SORT_BY_TYPE/$type/$dir"
			source="$GLROOT/site/$section/$dir"
			target_dir="$(dirname "$target")"

			if [[ ! -d "$target_dir" ]]
			then

				echo "$(date "+%Y-%m-%d %T") - Creating type dir $target_dir" >> "$LOG"
				mkdir -p "$target_dir"

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

				echo "$(date "+%Y-%m-%d %T") - Creating symlink $target -> $rel_source" >> "$LOG"
				ln -sf "$rel_source" "$target"

			fi

		fi

		if [[ -n "$SORT_BY_RANK" && -n "$rank" ]]
		then

			target="$GLROOT$symlink/$SORT_BY_RANK/$rank/$dir"
			source="$GLROOT/site/$section/$dir"
			target_dir="$(dirname "$target")"

			if [[ ! -d "$target_dir" ]]
			then

				echo "$(date "+%Y-%m-%d %T") - Creating rank dir $target_dir" >> "$LOG"
				mkdir -p "$target_dir"

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

				echo "$(date "+%Y-%m-%d %T") - Creating symlink $target -> $rel_source" >> "$LOG"
				ln -sf "$rel_source" "$target"

			fi

		fi

	done

	echo "$(date "+%Y-%m-%d %T") - Doing cleanup of broken links in section $section" >> $LOG
	find "$GLROOT$symlink" -xtype l -exec rm -f {} +
	find "$GLROOT$symlink" -type d -empty -exec rm -rf {} +
	echo "$(date "+%Y-%m-%d %T") - Done" >> $LOG

done
