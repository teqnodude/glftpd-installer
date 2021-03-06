#!/bin/bash
VER=1.71
#--[ Intro ]----------------------------------------------------#
#                                                       	#
# Tur-predircheck_manager. A script for lazy people to block  	#
# and unblock groups and releases in sections from within irc   #
#                                                       	#
# Who do I recomend to run this? Well, nobody since if  	#
# you accidently allow someone access to this who       	#
# shouldnt, he/she can do anything basically.           	#
#                                                       	#
# The tcl is locked to a single chan that the executor  	#
# must be in and it is also locked by default so the    	#
# user must be added to THIS bot with flag o (just      	#
# being an @ is not enough).                            	#
# By THIS bot, I mean the one that the tcl is loaded on 	#
#                                                       	#
#-[ Install ]---------------------------------------------------#
#                                                       	#
# Copy tur-predircheck_manager.sh to /glftpd/bin and chmod 755. #
# Copy sed to /glftpd/bin and chmod u+s.                        #
# Copy tur-predircheck_manager.tcl to your eggdrop scripts dir. #
# Edit it and check the settings in it. When done, load         #
# it in the bots config file and rehash the bot.                #
#								#
#--[ Info ]-----------------------------------------------------#
#								#		
# This script looks after the first line of sections that 	#
# matches when blocking so if you have specified the same 	#
# section numerous times to give a better view in shell then 	#
# you should be aware of this. This is necessary or the script 	#
# would simply insert the block on all matching rows which 	#
# causes redunancy.						#
# 								#
# Sections needs to be added to the tur-predircheck.sh before	#
# a block with this script works				#
#								#
# Addon created by Teqno					#
#								#	
#--[ Settings ]-------------------------------------------------#

glroot="/glftpd"		
predircheck="$glroot/bin/tur-predircheck.sh"
irctrigger="!block"

# How long should the block line under DENYDIRS be allowed to be before making a new line
length=210

#--[ Script start ]---------------------------------------------#

ARGS=`echo "$@" | cut -d ' ' -f2- | sed 's:[]\[\^\$\.\*\/]:\\\\&:g'`
INPUT=`echo "$@" | cut -d ' ' -f2-`
COLOR1=4
COLRST=
if [ "$ARGS" = "" ]
then
    echo '
    '$irctrigger' list sections - To list current blocklist for sections
    '$irctrigger' list groups - To list current blocklist for groups
    '$irctrigger' search <release/group> - To search for a specific release / group under DENYGROUPS and DENYDIRS
    '$irctrigger' add release <sectionname> <show/movie> - To block based on showname/moviename
    '$irctrigger' del release <sectionname> <show/movie> - To unblock based on showname/moviename
    '$irctrigger' add word <sectionname> <word> - To block based on a word in releasename
    '$irctrigger' del word <sectionname> <word> - To unblock based on a word in releasename
    '$irctrigger' add section group <sectionname> <groupname> - To block based on groupname
    '$irctrigger' del section group <sectionname> <groupname> - To unblock based on groupname
    '$irctrigger' del section rows <sectionname> - To delete all rows of a section
    '$irctrigger' add group <groupname> - To block group sitewide
    '$irctrigger' del group <groupname> - To unblock group sitewide
    '
fi 

if [ "$ARGS" = "list sections" ]
then
    $glroot/bin/sed -n '/DENYDIRS=\"/,/\"/p' $predircheck
fi

if [ "$ARGS" = "list groups" ]
then
    $glroot/bin/sed -n '/DENYGROUPS=\"/,/$/p' $predircheck
fi

if [[ "$ARGS" = "search"* ]]
then
    search=`echo $ARGS | awk -F " " '{print $2}'`
    [ -z "$search" ] && echo "Please enter a word to search for" && exit 0
    sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep --color=always -i "$search"
    if [ "`sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep --color=always -i "$search" | wc -l`" = 0 ]
    then
        echo "The block${COLOR1} $search ${COLRST}was not found in blocklist"
    fi
fi

if [[ "$ARGS" = "add release"* ]]
then
    section=`echo $ARGS | awk -F " " '{print $3}'`
    regexp=`echo $ARGS | awk -F " " '{print $4}'`
    regexpc=`echo $INPUT | awk -F " " '{print $4}'`
    if [ -z "$section" ] || [ -z "$regexp" ]
    then
	 echo "You need to specify section and release"
	exit 0
    fi
    if [ "`sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep "$section:^(" | grep --color=always -i "$regexpc" | wc -l`" -eq 1 ]
    then
        echo "The block${COLOR1} $regexpc ${COLRST}was found in blocklist, block not added."
        sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep "$section" | grep --color=always -i "$regexpc"
        exit 0
    fi
    echo "Blocking${COLOR1} $regexpc ${COLRST}in section ${COLOR1}$section"
    if [ ! "`sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep "$section:^("`" ]
    then
	$glroot/bin/sed -i "/INCOMPLETE/a /site/$section:^($regexp)[._-]" $predircheck
	sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep "$section:^(" | grep --color=always -i "$regexpc"
    else
	if [ "`sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep "$section:^(" | head -1 | wc -c`" -ge "$length" ]
	then
	    $glroot/bin/sed -i "/\/site\/$section:^(/a /site/$section:^($regexp)[._-]" $predircheck
	    sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep "$section:^(" | grep --color=always -i "$regexpc"
	else
	    startword=`grep "$section:^(" $predircheck | tail -2 | head -1 | sed -e 's/\^(//' -e 's/)\[._-]//' | cut -d':' -f2 | cut -d'|' -f1`
	    $glroot/bin/sed -i "/\/site\/$section:^(/ s/$startword/$regexp|$startword/" $predircheck
	    sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep "$section:^(" | grep --color=always -i "$regexpc"
	fi
    fi
fi

if [[ "$ARGS" = "add word"* ]]
then
    section=`echo $ARGS | awk -F " " '{print $3}'`
    regexp=`echo $ARGS | awk -F " " '{print $4}'`
    regexpc=`echo $INPUT | awk -F " " '{print $4}'`
    if [ -z "$section" ] || [ -z "$regexp" ]
    then
	echo "You need to specify section and word"
	exit 0
    fi
    if [ "`sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep "$section:\[\." | grep --color=always -i "$regexpc" | wc -l`" -eq 1 ]
    then
        echo "The block${COLOR1} $regexpc ${COLRST}was found in blocklist, block not added."
        sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep "$section" | grep --color=always -i "$regexpc"
        exit 0
    fi
    echo "Blocking${COLOR1} $regexpc ${COLRST}in section ${COLOR1}$section"
    if [ ! "`sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep "$section:\[\."`" ]
    then
	$glroot/bin/sed -i "/INCOMPLETE/a /site/$section:[._-]($regexp)[._-]" $predircheck
	sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep "$section:\[\." | grep --color=always -i "$regexpc"
    else
	if [ "`sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep "$section:\[\." | tail -1 | wc -c`" -ge "$length" ]
	then
	    $glroot/bin/sed -i "/\/site\/$section:\[\./a /site/$section:[._-]($regexp)[._-]" $predircheck
	    sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep "$section:\[\." | grep --color=always -i "$regexpc"
	else
	    startword=`grep "$section:\[._-]" $predircheck | tail -2 | head -1 | sed -e 's/\[._-](//' -e 's/)\[._-]//' | cut -d':' -f2 | cut -d'|' -f1`
	    $glroot/bin/sed -i "/\/site\/$section:\[\./ s/$startword/$regexp|$startword/" $predircheck
	    sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep "$section:\[\." | grep --color=always -i "$regexpc"
	fi
    fi
fi

if [[ "$ARGS" = "add section group"* ]]
then
    section=`echo $ARGS | awk -F " " '{print $4}'`
    regexp=`echo $ARGS | awk -F " " '{print $5}'`
    regexpc=`echo $INPUT | awk -F " " '{print $5}'`
    if [ -z "$section" ] || [ -z "$regexp" ]
    then
	echo "You need to specify section and group"
	exit 0
    fi
    if [ "`sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep "$section:\[-\]" | grep --color=always -i "\-$regexpc$" | wc -l`" -eq 1 ]
    then
        echo "The block${COLOR1} $regexpc ${COLRST}was found in blocklist, block not added."
        sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep "$section" | grep --color=always -i "$regexpc"
        exit 0
    fi
    echo "Blocking${COLOR1} $regexpc ${COLRST}in section ${COLOR1}$section"
    if [ ! "`sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep "$section:\[-"`" ]
    then
        $glroot/bin/sed -i "/INCOMPLETE/a /site/$section:[-]($regexp)$" $predircheck
	sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep "$section:\[-\]" | grep --color=always -i "$regexpc"
    else
        if [ "`sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep "$section:\[-" | tail -1 | wc -c`" -ge $length ]
        then
            $glroot/bin/sed -i "/\/site\/$section:\[\-/a /site/$section:[-]($regexp)$" $predircheck
	    sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep "$section:\[-\]" | grep --color=always -i "$regexpc"
        else
	    startword=`grep "$section:\[-" $predircheck | tail -2 | sed 's/\[-](//' | tr -d ')$' | cut -d':' -f2 | cut -d'|' -f1`
            $glroot/bin/sed -i "/\/site\/$section:\[\-/ s/$startword/$regexp|$startword/" $predircheck
	    sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep "$section:\[-\]" | grep --color=always -i "$regexpc"
        fi
    fi
fi


if [[ "$ARGS" = "del release"* ]]
then
    section=`echo $ARGS | awk -F " " '{print $3}'`
    regexp=`echo $ARGS | awk -F " " '{print $4}'`
    regexpc=`echo $INPUT | awk -F " " '{print $4}'`
    if [ "`sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep "$section:\^\(" | grep --color=always -i "$regexpc" | wc -l`" -eq 1 ]
    then
        echo "Unblocking${COLOR1} $regexpc ${COLRST}in section ${COLOR1}$section"
        $glroot/bin/sed -i "/\/site\/$section:^(/ s/$regexpc//" $predircheck
        $glroot/bin/sed -i "/\/site\/$section:^(/ s/|)/)/gI" $predircheck
        $glroot/bin/sed -i "/\/site\/$section:^(/ s/(|/(/gI" $predircheck
        $glroot/bin/sed -i "/\/site\/$section:^(/ s/||/|/gI" $predircheck
	$glroot/bin/sed -i "/()/d" $predircheck
	sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep "$section:\^\("
    else
	echo "The block${COLOR1} $regexpc ${COLRST}was not found in blocklist"
    fi
fi

if [[ "$ARGS" = "del word"* ]]
then
    section=`echo $ARGS | awk -F " " '{print $3}'`
    regexp=`echo $ARGS | awk -F " " '{print $4}'`
    regexpc=`echo $INPUT | awk -F " " '{print $4}'`
    if [ "`sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep "$section:\[._-\]" | grep --color=always -i "$regexpc" | wc -l`" -eq 1 ]
    then
        echo "Unblocking${COLOR1} $regexpc ${COLRST}in section ${COLOR1}$section"
        $glroot/bin/sed -i "/\/site\/$section:\[._-/ s/$regexpc//" $predircheck
        $glroot/bin/sed -i "/\/site\/$section:\[._-/ s/|)/)/gI" $predircheck
        $glroot/bin/sed -i "/\/site\/$section:\[._-/ s/(|/(/gI" $predircheck
        $glroot/bin/sed -i "/\/site\/$section:\[._-/ s/||/|/gI" $predircheck
	$glroot/bin/sed -i "/()/d" $predircheck
	sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep "$section:\[._-\]"
    else
	echo "The block${COLOR1} $regexpc ${COLRST}was not found in blocklist"
    fi
fi

if [[ "$ARGS" = "del section group"* ]]
then
    section=`echo $ARGS | awk -F " " '{print $4}'`
    regexp=`echo $ARGS | awk -F " " '{print $5}'`
    regexpc=`echo $INPUT | awk -F " " '{print $5}'`
    if [ "`sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep "$section:\[-\]" | grep --color=always -i "$regexpc" | wc -l`" -eq 1 ]
    then
        echo "Unblocking${COLOR1} $regexpc ${COLRST}in section ${COLOR1}$section"
        $glroot/bin/sed -i "/\/site\/$section:\[-/ s/$regexpc//" $predircheck
        $glroot/bin/sed -i "/\/site\/$section:\[-/ s/|)/)/gI" $predircheck
        $glroot/bin/sed -i "/\/site\/$section:\[-/ s/(|/(/gI" $predircheck
        $glroot/bin/sed -i "/\/site\/$section:\[-/ s/||/|/gI" $predircheck
	$glroot/bin/sed -i "/()/d" $predircheck
	sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep "$section:\[-\]"
    else
	echo "The block${COLOR1} $regexpc ${COLRST}was not found in blocklist"
    fi
fi

if [[ "$ARGS" = "del section rows"* ]]
then
    section=`echo $ARGS | awk -F " " '{print $4}'`
    if [ "`sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep "$section" | wc -l`" -eq 0 ]
    then
	echo "Section${COLOR1} $section ${COLRST}not found in blocklist"
    else
	echo "Removed all rows containing section:${COLOR1} $section"
        $glroot/bin/sed -i "/\/site\/$section/d" $predircheck
	$glroot/bin/sed -n '/DENYDIRS=\"/,/\"/p' $predircheck    
    fi
fi

if [[ "$ARGS" = "add group"* ]]
then
    group=`echo $ARGS | awk -F " " '{print $3}'`
    if [ "`grep "^DENYGROUPS" $predircheck | grep "$group"`" ]
    then
        echo "Group${COLOR1} $group ${COLRST}already added"
        exit 0
    else
        echo "Blocking group ${COLOR1}$group"
	if [ "`grep '^DENYGROUPS=""' $predircheck | wc -l`" -eq 1 ]
	then
	    $glroot/bin/sed -i "/^DENYGROUPS=/ s/\"$/\/site:[-]($group)$\"/" $predircheck
	    grep "^DENYGROUPS" $predircheck | grep --color=always "$group"
	else
            startword=`grep "^DENYGROUPS" $predircheck | sed 's/\[-](//' | tr -d ')$' | cut -d ':' -f2 | cut -d'|' -f1 | tr -d '"'`
            $glroot/bin/sed -i "/DENYGROUPS/ s/$startword/$group|$startword/" $predircheck
	    grep "^DENYGROUPS" $predircheck | grep --color=always "$group"
	fi
    fi
fi

if [[ "$ARGS" = "del group"* ]]
then
    group=`echo $ARGS | awk -F " " '{print $3}'`
    if [ "`grep "^DENYGROUPS" $predircheck | grep $group`" ]
    then
        echo "Unblocking group${COLOR1} $group"
        $glroot/bin/sed -i "/\/site:/ s/\b$group\b//" $predircheck
        $glroot/bin/sed -i "/\/site:/ s/|)/)/gI" $predircheck
        $glroot/bin/sed -i "/\/site:/ s/(|/(/gI" $predircheck
        $glroot/bin/sed -i "/\/site:/ s/||/|/gI" $predircheck
	$glroot/bin/sed -i "/\/site:/ s/\/site:\[-]()\\$//" $predircheck
	grep "^DENYGROUPS" $predircheck
    else
        echo "Group${COLOR1} $group ${COLRST}not found"
    fi
fi

exit 0
