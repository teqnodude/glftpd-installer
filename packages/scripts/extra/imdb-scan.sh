#!/bin/bash
VER=1.1
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
sort_by_genre=Sorted.By.Genre
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
	    rating="`ls $glroot/site/$section/$dir | grep -o "Score_.*" | cut -d "_" -f2`"
	    year="`ls $glroot/site/$section/$dir | grep -o "(.*)" | grep -v COMPLETE | grep -o "[0-9][0-9][0-9][0-9]"`"
	    genre="`ls $glroot/site/$section/$dir | grep -o "Score_.*" | cut -d "_" -f4`"
	    if [ ! -z "$rating" ]
	    then
		if [ ! -d "$glroot$symlink/$sort_by_genre/$genre" ]
		then
		    echo "`date "+%Y-%m-%d %T"` - Creating genre dir $glroot$symlink/$sort_by_genre/$genre" >> $log
		    mkdir -pm777 $glroot$symlink/$sort_by_genre/$genre
		fi
		if [ ! -L "$glroot$symlink/$sort_by_genre/$genre/$dir" ]
		then
		    echo "`date "+%Y-%m-%d %T"` - Creating symlink $glroot$symlink/$sort_by_genre/$genre/$dir" >> $log
                    depth=`echo $section | grep -o '/' | wc -l`
                    case $depth in
                        3)
                        ln -s "../../../../../../$section/$dir" "$glroot$symlink/$sort_by_genre/$genre/$dir"
                        rm -f "../../../../../../$section/$dir/$dir"
                        ;;
                        2)
                        ln -s "../../../../../$section/$dir" "$glroot$symlink/$sort_by_genre/$genre/$dir"
                        rm -f "../../../../../$section/$dir/$dir"
                        ;;
                        1)
                        ln -s "../../../../$section/$dir" "$glroot$symlink/$sort_by_genre/$genre/$dir"
                        rm -f "../../../../$section/$dir/$dir"
                        ;;
                        0)
                        ln -s "../../../$section/$dir" "$glroot$symlink/$sort_by_genre/$genre/$dir"
                        rm -f "../../../$section/$dir/$dir"
                        ;;
                    esac
		fi
	    fi
	done
	echo "`date "+%Y-%m-%d %T"` - Doing cleanup of broken links in section $section" >> $log
	find $glroot$symlink -xtype l -exec rm -f {} +
	echo "`date "+%Y-%m-%d %T"` - Done" >> $log
    done
fi

exit 0
