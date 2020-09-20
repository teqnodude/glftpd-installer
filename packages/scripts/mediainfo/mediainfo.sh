#!/bin/bash
VER=1.7
#---------------------------------------------------------------#
#                                                               #
# Mediainfo by Teqno                                       	#
#								#
# It extracts info from *.rar file for related releases to	#
# give the user the ability to compare quality.			#
#								#
#--[ Settings ]-------------------------------------------------#

GLROOT=/glftpd
TMP=$GLROOT/tmp
TMPFILE=$TMP/mediainfo.txt
COLOR1=7 # Orange
COLOR2=14 # Dark grey
COLOR3=4 # Red
SECTIONS="TV-720 TV-1080 TV-2160 TV-NO TV-NORDIC X264-1080 X265-2160"

#--[ Script Start ]----------------------------------------------#

SECTIONS=`for SEC in $SECTIONS; do echo -e "$COLOR3$SEC $COLOR2|"; done`
SECTIONS=`echo $SECTIONS | sed 's/|$//'`

HELP="
${COLOR2}Please enter full releasename ie ${COLOR3}Terminator.Salvation.2009.THEATRICAL.1080p.BluRay.x264-FLAME\n
${COLOR2}Only works for releases in: $SECTIONS\n
"

INPUT=`echo "$@" | cut -d " " -f2`
TV=`echo $INPUT | grep -o ".*.S[0-9][0-9]E[0-9][0-9].\|.*.E[0-9][0-9].\|.*.[0-9][0-9][0-9][0-9].[0-9][0-9].[0-9][0-9]." | sed 's|^/||'`
if [[ `echo $INPUT | sed 's/[0-9][0-9][0-9][0-9]p//' | grep -o ".*.[0-9][0-9][0-9][0-9]." | sed 's|^/||' | cut -d"/" -f4` ]]
then
    MOVIE=`echo $INPUT | sed 's/[0-9][0-9][0-9][0-9]p//' | grep -o ".*.[0-9][0-9][0-9][0-9]." | sed 's|^/||'`
else
    MOVIE=`echo $INPUT | sed 's|[0-9][0-9][0-9][0-9]p.*||'`
fi

if [ -z $INPUT ]
then
    echo -e $HELP
else
    if [ -z $TV ] 
    then
	case $INPUT in
	    *.2160p.*)
    	    section=X265-2160
	    release="$MOVIE*"
	    ;;
	    *.1080p.*)
	    section=X264-1080
	    release="$MOVIE*"
	    ;;
	    *)
	    echo -e $HELP
	    exit 0
	    ;;
	esac
    else
	case $INPUT in
            *.2160p.*)
            section=TV-2160
            release="$TV*2160p*"
            ;;
            *.DAN[iI]SH.1080p.*|*.SWED[iI]SH.1080p.*|*.FINNISH.1080p.*)
            section=TV-NORDIC
            release="$TV*1080p*"
            ;;
            *.NORWEG[iI]AN.1080p.*)
            section=TV-NO
            release="$TV*1080p*"
            ;;
            *.1080p.BluRay.*)
            section=TV-BLURAY
            release="$TV*1080p*"
            ;;
            *.1080p.*)
            section=TV-1080
            release="$TV*1080p*"
            ;;
            *.DAN[iI]SH.720p.*|*.SWED[iI]SH.720p.*|*.FINNISH.720p.*)
            section=TV-NORDIC
            release="$TV*720p*"
            ;;
            *.NORWEG[iI]AN.720p.*)
            section=TV-NO
            release="$TV*720p*"
            ;;
            *.720p.*)
            section=TV-720
            release="$TV*720p*"
            ;;
            *)
            echo -e $HELP
            exit 0
            ;;
	esac
    fi

    if [ ! -d $GLROOT/site/$section/$INPUT ]
    then
        echo "Release not found"
        exit 0
    else
        if [ "$(find $GLROOT/site/$section/$INPUT -type f -name '* Complete -*' | wc -l )" != "0" ]
        then
            echo "Release incomplete"
        exit 0
        else
            cd $GLROOT/bin
            if [ ! -d $TMP ]; then mkdir -m777 $GLROOT/tmp ; fi
            for info in `ls $GLROOT/site/$section | grep -iv "\[NUKED\]\|\[INCOMPLETE\]\|DIRFIX\|SAMPLEFIX" | grep "$release"`
            do
                if [ $(find $GLROOT/site/$section/$info -type f -name "* Complete -*" | wc -l ) = "0" ]
                then
		    for media in `ls $GLROOT/site/$section/$info | grep ".*.rar" | head -1`
                    do
                	if [[ `./mediainfo-rar $GLROOT/site/$section/$info/$media | grep failed | wc -l` = "1" ]] ; then echo "Couldn't extract information" ; exit 0 ; fi
                	./mediainfo-rar $GLROOT/site/$section/$info/$media > $TMPFILE
                        release=`cat $TMPFILE | grep "^Filename" | cut -d ":" -f2 | sed -e "s|$GLROOT/site/$section/||" -e 's|/.*||' -e 's/ //'`
                        echo -en "${COLOR1}$release${COLOR2}"
                        filesize=`cat $TMPFILE | grep "File size*" | grep "MiB\|GiB" | cut -d ":" -f2 | sed 's/ //'`
                        echo -en " |${COLOR1} $filesize${COLOR2}"
			duration=`cat $TMPFILE | sed -n '/General/,/Video/p' | grep "^Duration" | uniq | cut -d ":" -f2 | sed 's/ //'`
                        echo -en " |${COLOR1} $duration${COLOR2}"
                        obitrate=`cat $TMPFILE | sed -n '/General/,/Video/p' | grep -v "Overall bit rate mode" | grep "Overall bit rate" | cut -d ":" -f2 | sed 's/ //'`
                        if [ "$obitrate" ]; then echo -en " | Overall:${COLOR1} $obitrate${COLOR2}" ; fi
                        vbitrate=`cat $TMPFILE | sed -n '/Video/,/Audio/p' | grep "^Bit rate  " | cut -d ":" -f2 | sed 's/ //'`
                        if [ "$vbitrate" ]; then echo -en " | Video:${COLOR1} $vbitrate${COLOR2}" ; fi
                        nbitrate=`cat $TMPFILE | sed -n '/Video/,/Forced/p' | grep "^Nominal bit rate  " | cut -d ":" -f2 | sed 's/ //'`
                        if [ "$nbitrate" ]; then  echo -en " | Video Nominal:${COLOR1} $nbitrate${COLOR2}" ; fi
                        if [ -z "`cat $TMPFILE | sed -n '/Audio #1/,/Forced/p'`" ]; then audio="Audio" ;  else audio="Audio #1" ; fi
                        abitrate=`cat $TMPFILE | sed -n "/$audio/,/Forced/p" | grep "^Bit rate  " | cut -d ":" -f2 | sed 's/ //'`
                        if [ "$abitrate" ]; then echo -en " | Audio:${COLOR1} $abitrate${COLOR2}" ; fi
                        mabitrate=`cat $TMPFILE | sed -n "/$audio/,/Forced/p" | grep "^Maximum bit rate  " | cut -d ":" -f2 | sed 's/ //'`
                        if [ "$mabitrate" ]; then echo -en " | Max Audio:${COLOR1} $mabitrate${COLOR2}" ; fi
                        formtitle=`cat $TMPFILE | sed -n "/$audio/,/Forced/p" | grep "^Title  " | cut -d ":" -f2 | sed 's/ //'`
                        if [[ "$formtitle" =~ "DTS-HD" ]]
                    	then
                    	    echo -en " |${COLOR1} $formtitle${COLOR2}"
                    	else
                    	    format=`cat $TMPFILE | sed -n "/$audio/,/Forced/p" | grep "^Format  " | cut -d ":" -f2 | sed -e 's/ //' -e 's/UTF\-8//'`
                            if [ "$format" ]; then echo -en " |${COLOR1} $format${COLOR2}" ; fi
                            channels=`cat $TMPFILE | sed -n "/$audio/,/Forced/p" | grep "^Channel(s)" | cut -d ":" -f2 | sed 's/ //'`
                            if [ "$channels" ]; then echo -en "${COLOR1} $channels${COLOR2}" ; fi
                        fi
                        language=`cat $TMPFILE | sed -n "/$audio/,/Forced/p" | grep "^Language  " | cut -d ":" -f2 | sed 's/ //' | head -1`
                        if [ "$language" ]; then echo -en "${COLOR1} $language${COLOR2}" ; fi
                        echo
                    done
                    rm $TMPFILE
                fi
            done
        fi
    fi
fi

exit 0
