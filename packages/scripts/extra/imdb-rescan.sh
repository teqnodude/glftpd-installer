#!/bin/bash
VER=1.0
#--[ Intro ]----------------------------------------------------#
# 								#
# A script that scans releases for the imdb tag created by 	#
# psxc-imdb and if the tag is not found it's added to an index 	#
# that later is processed and rescanned by psxc-imdb. It also	#
# creates an index of those releases that contain more than one	#
# nfo that requires personal attention to resolve 		#
#								#
#-[ Install ]---------------------------------------------------#
#								#
# Copy this to /glftpd/bin and chmod it 755. Then go over the 	#
# settings and run the script manually like this:		#
# chroot /glftpd /bin/imdb-rescan.sh				#
#								#
#--[ Settings ]-------------------------------------------------#

sections="
X264-1080
ARCHIVE/MOVIES/X264-1080
"

glroot=/glftpd 			# location of glftpd
tmp=/tmp 			# name of tmp folder inside glftpd 		
noimdbtag=no_imdb_tag.txt 	# name of index for missing imdb tag
doublenfo=double_nfo.txt 	# name of index for double nfo
timestamp=1 			# to keep timestamp on folders
onlytime=0			# not rescan, only preserve timestamp

#--[ Script start ]---------------------------------------------#

if [ "$onlytime" != 1 ]
then
    for section in $sections
    do
	>$tmp/$doublenfo
	>$tmp/$noimdbtag
	echo
	echo -n "Creating index of missing imdb tags, please wait...                 "
	for x in `ls /site/$section`
	do
	    if [ `ls /site/$section/$x | grep "*IMDB*" | wc -l` = 0 ]
	    then
		if [ `ls /site/$section/$x | grep "*.nfo" | wc -l` = 1 ]
		then
		    if [ `cat /site/$section/$x/*.nfo | grep -i "*imdb.com*" | wc -l` = 1 ]
		    then
			echo "$x lack an imdb tag, added to index"
			echo "/site/$section/$x" >> $tmp/$noimdbtag
		    fi
		fi
	    fi
	done
	echo -e "[\e[32mDone\e[0m]"
	echo
	echo -n "Cleaning index fron symlinks, subfixes and dirfixes, please wait... "
	sed -i '/[nN][oO]-[nN][fF][oO]\|[sS][uU][bB][fF][iI][xX]\|[dD][iI][rR][fF][iI][xX]/d' $tmp/$noimdbtag
	echo -e "[\e[32mDone\e[0m]"
	echo
	echo -n "Rescanning releases based on the clean index, please wait...        "
	for x in `cat $tmp/$noimdbtag`
	do
	    cd $x
	    nfo=`ls -1 | grep *.nfo`
	    [[ 1 -lt "$(echo "$nfo" | wc -l)" ]] && echo "$glroot$x" >> $tmp/$doublenfo
	    if [ ! -z $nfo ]
	    then
		if [ `cat $x/$nfo | grep -i "*imdb.com*" | wc -l` = 0 ]
		then
		    echo "1" > $glroot/ftp-data/logs/psxc-imdb-rescan.tmp
		    /bin/psxc-imdb.sh $x/$nfo
		fi
	    fi
	    cd ..
	done
	echo -e "[\e[32mDone\e[0m]"
	echo
    done
    
    if [ "$timestamp" = 1 ]
    then
	for section in $sections
	do
	    echo -n "Fixing timestamp for section $section, please wait...               "
	    cd /site/$section
	    find . -type d -print0 | while read -r -d '' dir; do file="$(find "$dir" -maxdepth 1 -type f  -printf '%T+ %p\n' | sort -r | head -5 | tail -1 | cut -d' ' -f2-)";if [ -n "$file" ]; then touch "$dir" -mr "$file"; fi; done
	    echo -e "[\e[32mDone\e[0m]"
	done
    fi

else

    if [ "$timestamp" = 1 ]
    then
        for section in $sections
        do
	    echo
            echo -n "Fixing timestamp for section $section, please wait...               "
            cd /site/$section
            find . -type d -print0 | while read -r -d '' dir; do file="$(find "$dir" -maxdepth 1 -type f  -printf '%T+ %p\n' | sort -r | head -5 | tail -1 | cut -d' ' -f2-)";if [ -n "$file" ]; then touch "$dir" -mr "$file"; fi; done
            echo -e "[\e[32mDone\e[0m]"
        done
    fi

fi

exit 0