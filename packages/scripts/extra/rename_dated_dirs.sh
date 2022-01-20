#!/bin/bash
VER=1.0
#################################################################
#                                                               #
# Rename script created by Teqno for the purpose of changing    #
# format of dated dirs from MMDD to YYYY-MM-DD                  #
#                                                               #
#--[ Settings ]-------------------------------------------------#

path=/glftpd/site
sections="0DAY EBOOKS FLAC MP3 XXX-PAYSITE"
today=`date +%m%d`
tomorrow=`date +%m%d`
thisyear=`date +%Y`
lastyear=`date +%Y --date "-1 year"`

#--[ Script start ]---------------------------------------------#

for section in $sections
do
    if [ ! -d "$path/$section" ]
    then
        echo "Section $section do not exist, skipping..."
        continue
    fi
    cd $path/$section
    for x in `ls $path/$section`
    do
        if [ `echo "$x" | grep -E ^\-?[0-9]+$ | wc -l` = 0 ]
        then
    	    echo "Dated dir $x is not of old format, skipping..."
            continue
        fi
        if [ "$x" -ge "$tomorrow" ]
        then
            new=`echo $x | sed 's/[0-9][0-9]/&-/' | sed -ne 's/.*/$lastyear-&/p'`
            mv $path/$section/$x $path/$section/$new
        fi
        if [ "$x" -le "$today" ]
        then
            new=`echo $x | sed 's/[0-9][0-9]/&-/' | sed -ne 's/.*/$thisyear-&/p'`
            mv $path/$section/$x $path/$section/$new
        fi
    done
done

exit 0
