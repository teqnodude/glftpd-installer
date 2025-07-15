#!/bin/bash
VER=1.24
#--[ Info ]-----------------------------------------------------#
# 
# A script that create genre symlinks for a section of movies out 
# of the IMDB tag created by psxc-imdb.
# 
# 0 1 * * *	  /glftpd/bin/imdb-scan.sh index >/dev/null 2>&1
#		
#--[ Settings ]-------------------------------------------------#

glroot=/glftpd
tmp=$glroot/tmp
sections="
X264-1080:/site/X264-1080_MOVIES_SORTED
X265-2160:/site/X265-2160_MOVIES_SORTED
ARCHIVE/MOVIES/X264-1080:/site/ARCHIVE/MOVIES/X264-1080_MOVIES_SORTED
ARCHIVE/MOVIES/X265-2160:/site/ARCHIVE/MOVIES/X265-2160_MOVIES_SORTED
"
exclude="^\[NUKED\]-|^\[incomplete\]-|^\[no-nfo\]-|^\[no-sample\]-"
# Comment out the lines below or leave them empty to disable them
sort_by_genre=Sorted.By.Genre
sort_by_rank=Sorted.By.Rank
log=$glroot/ftp-data/logs/imdb-scan.log

#--[ Script Start ]---------------------------------------------#

if [ -z "$1" ]
then
    echo "./imdbrating.sh index - to create the symlinks"
fi

if [ "$1" = "index" ]
then
    if [ ! -f "$log" ]
    then
        touch $log && chmod 666 $log
    fi
    for path in $sections
    do
	section=`echo $path | cut -d ":" -f1`
	symlink=`echo $path | cut -d ":" -f2`
	[ ! -d "$glroot/site/$section" ] && continue
	echo "`date "+%Y-%m-%d %T"` - Creating symlinks for section $section, please wait...." >> $log
	for dir in `ls $glroot/site/$section | egrep -v "$exclude"`
	do
	    rank="`ls $glroot/site/$section/$dir | grep IMDB | egrep -o "Score_(NA|[0-9]|[0-9].[0-9])" | cut -d "_" -f2 | sed 's|.[0-9]||'`"
	    year="`ls $glroot/site/$section/$dir | grep IMDB | egrep -o "([0-9][0-9][0-9][0-9])" | tr -s '()'`"
	    genres="`ls $glroot/site/$section/$dir | grep IMDB | grep -o "Score_.*" | sed -e 's/(.*//' -e 's/Score_\([0-9]\(\.[0-9]\)\?\|NA\)_-_//' | sed -e 's/-/ /g' -e 's/Sci Fi/Sci-Fi/' -e 's/Sci/Sci-Fi/' -e 's/Sci-Fi-Fi/Sci-Fi/' -e 's/_//g' -e 's/Score//'`"
	    for genre in $genres
	    do
		if [ ! -z "$sort_by_genre" ] && [ ! -z "$genre" ]
		then
  
		    if [ ! -d "$glroot$symlink/$sort_by_genre/$genre" ]
		    then
			echo "`date "+%Y-%m-%d %T"` - Creating genre dir $glroot$symlink/$sort_by_genre/$genre" >> $log
			mkdir -pm777 $glroot$symlink/$sort_by_genre/$genre
		    fi
      
		    if [ ! -L "$glroot$symlink/$sort_by_genre/$genre/$dir" ]
		    then
			echo "`date "+%Y-%m-%d %T"` - Creating symlink $glroot$symlink/$sort_by_genre/$genre/$dir" >> $log
                        target="$glroot$symlink/$sort_by_genre/$genre/$dir"
                        source="$glroot/site/$section/$dir"
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
	
		if [ ! -z "$sort_by_rank" ] && [ ! -z "$rank" ]
  		then
    
                    if [ ! -d "$glroot$symlink/$sort_by_rank/$rank" ]
                    then
                        echo "`date "+%Y-%m-%d %T"` - Creating rank dir $glroot$symlink/$sort_by_rank/$rank" >> $log
                        mkdir -pm777 $glroot$symlink/$sort_by_rank/$rank
                    fi
		    
                    if [ ! -L "$glroot$symlink/$sort_by_rank/$rank/$dir" ]
                    then
                        echo "`date "+%Y-%m-%d %T"` - Creating symlink $glroot$symlink/$sort_by_rank/$rank/$dir" >> $log
                        target="$glroot$symlink/$sort_by_rank/$rank/$dir"
                        source="$glroot/site/$section/$dir"
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
	done
 
	echo "`date "+%Y-%m-%d %T"` - Doing cleanup of broken links in section $section" >> $log
	find $glroot$symlink -xtype l -exec rm -f {} +
 	find $glroot$symlink -type d -empty -exec rm -rf {} +
	echo "`date "+%Y-%m-%d %T"` - Done" >> $log
    done
fi

exit 0
