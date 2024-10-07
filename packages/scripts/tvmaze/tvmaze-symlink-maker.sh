#!/bin/bash
VER=1.04
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
sort_by_genre=Sorted.By.Genre
sort_by_type=Sorted.By.Type
#log=$glroot/ftp-data/logs/tvmaze-symlink-maker.log

#--[ Script Start ]---------------------------------------------#

if [ -z "$1" ]
then
    echo "./tvmaze-symlink-maker.sh index - to create the symlinks"
fi

if [ "$1" = "index" ]
then
    if [[ ! -z $log && ! -f $log ]]
    then
        touch $log && chmod 666 $log
    fi

    [ -z $log ] && log=/dev/null

    for path in $sections
    do
	section=`echo $path | cut -d ":" -f1`
	symlink=`echo $path | cut -d ":" -f2`
	[ ! -d "$glroot/site/$section" ] && continue
	echo "`date "+%Y-%m-%d %T"` - Creating symlinks for section $section, please wait...." >> $log

	for dir in `ls $glroot/site/$section | egrep -v "$exclude"`
	do
	    genre="`ls $glroot/site/$section/$dir | egrep -v "IMDB|COMPLETE" | grep -o "Score_.*" | sed -e 's/(.*//' -e 's/Score_\([0-9]\(\.[0-9]\)\?\|NA\)_-_//' | tr -s "_" " " | sed 's/ - / /g'`"
	    type="`ls $glroot/site/$section/$dir | egrep -v "IMDB|COMPLETE" | grep -o "(.*)" | tr -d '()'| tr -s " " "_"`"

	    if [ ! -z "$genre" ]
	    then
		for gen in $genre
		do
		    if [ ! -d "$glroot$symlink/$sort_by_genre/$gen" ]
		    then
			echo "`date "+%Y-%m-%d %T"` - Creating genre dir $glroot$symlink/$sort_by_genre/$gen" >> $log
			mkdir -pm777 $glroot$symlink/$sort_by_genre/$gen
		    fi

		    if [ ! -L "$glroot$symlink/$sort_by_genre/$gen/$dir" ]
		    then
			echo "`date "+%Y-%m-%d %T"` - Creating symlink $glroot$symlink/$sort_by_genre/$gen/$dir" >> $log
			ln -s "../../../$section/$dir" "$glroot$symlink/$sort_by_genre/$gen/$dir"
		    fi
		done

		if [ ! -d "$glroot$symlink/$sort_by_type/$type" ]
		then
		    echo "`date "+%Y-%m-%d %T"` - Creating type dir $glroot$symlink/$sort_by_type/$type" >> $log
		    mkdir -pm777 $glroot$symlink/$sort_by_type/$type
		fi

		if [ ! -L "$glroot$symlink/$sort_by_type/$type/$dir" ]
		then
		    echo "`date "+%Y-%m-%d %T"` - Creating symlink $glroot$symlink/$sort_by_type/$type/$dir" >> $log
		    ln -s "../../../$section/$dir" "$glroot$symlink/$sort_by_type/$type/$dir"
		fi
	    fi
	done

	echo "`date "+%Y-%m-%d %T"` - Doing cleanup of broken links in section $section" >> $log
	find $glroot$symlink -xtype l -exec rm -f {} +
 	find $glroot$symlink -type d -empty -exec rm {} +
	echo "`date "+%Y-%m-%d %T"` - Done" >> $log

    done
fi

exit 0
