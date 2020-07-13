#!/bin/bash
VER=1.6
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

#--[ Script start ]---------------------------------------------#

ARGS=`echo "$@" | cut -d ' ' -f2- | sed 's:[]\[\^\$\.\*\/]:\\\\&:g'`
INPUT=`echo "$@" | cut -d ' ' -f2-`
if [ "$ARGS" = "" ]
then
	echo '
	'$irctrigger' help - To view help about regexp and blocking / unblocking releases / groups
	'$irctrigger' list sections - To list current blocklist for sections
	'$irctrigger' list groups - To list current blocklist for groups
	'$irctrigger' search <release/group> - To search for a specific release / group under DENYGROUPS and DENYDIRS
	'$irctrigger' add release <sectionname> <regexp> - To block a release in existing section on first line that matches
        '$irctrigger' edit section <sectionname> startword <regexp> - To edit and add to existing block of words in existing section on first line that matches
        '$irctrigger' edit section <sectionname> startword - To edit and remove existing block of word in existing section on first line that matches
	'$irctrigger' add newline release <sectionname> <regexp> - To block a release in an existing section on a new line
	'$irctrigger' add newsection <oldsectionname> <newsectionname> <regexp> - To block a release in a new section on a new line with existing section as reference point
	'$irctrigger' del release <sectionname> <regexp> - To unblock a release in specified section
	'$irctrigger' del section <sectionname> - To delete all rows of an old section
	'$irctrigger' add group <groupname> - To block group site wide
	'$irctrigger' del group <groupname> - To unblock group site wide
	'
fi 

if [ "$ARGS" = "help" ]
then
	echo '
	This script looks after the first line of sections that       
	matches when blocking so if you have specified the same       
	section numerous times to give a better view in shell then    
	you should be aware of this. This is necessary or the script  
	would simply insert the block on all matching rows which      
	causes redundancy.
		
	---------------------------------------
										
	Blocking / Unblocking releases
		
        It is considered good practice to use \. or \- when blocking
        releases instead of just the word to ensure that block occurs correctly.
		
        Example: '$irctrigger' add release TV-HD \.MULTi\-
        Result: /site/TV-HD:\.MULTi\-
		
        Example: /site/TV-HD:\.MULTi\-
        Result: '$irctrigger' del release TV-HD \.MULTI\-
		
        When blocking releases that is starting or ending with something
        then you do this. ^ = Starting - $ = Ending
		
        Example: '$irctrigger' add release TV-HD ^Start.Test\.
        Result: /site/TV-HD:^Start.Test\.
		
        Example: '$irctrigger' add release TV-HD Test.End$
        Result: /site/TV-HD:Test.End$
		
        Example: /site/TV-HD:^Start.Test
        Result: '$irctrigger' del TV-HD ^Start.Test
		
        Example: /site/TV-HD:Start.End$
        Result: '$irctrigger' del TV-HD Start.End$

        When blocking words

        Example: '$irctrigger' add release 0DAY [._-](word)[._-]
        Result: /site/0DAY:[._-](word)[._-]

        Adding wordblock to existing block

        Example: /site/0DAY:[._-](word)[._-]
        Do: '$irctrigger' edit section 0DAY word newword
        Result: /site/0DAY:[._-](newword|word)[._-]

        Removing wordblock from existing block

        Example: /site/0DAY:[._-](newword|word)[._-]
        Do: '$irctrigger' edit section 0DAY newword
        Result: /site/0DAY:[._-](word)[._-]
		
        When blocking/unblocking a group for a specific section you do this.
		
        Example: '$irctrigger' add release TV-HD \-GROUPNAME$
        Result: /site/TV-HD:\-GROUPNAME$
		
        Example: /site/TV-HD:\-GROUPNAME$
        Result: '$irctrigger' del release TV-HD \-GROUPNAME$
				
	---------------------------------------
										
	Blocking / Unblocking groups
										
	When blocking a group you do this.
										
	Example: '$irctrigger' add group GROUPNAME
	Result: DENYGROUPS="/site:\-GROUPNAME$
										
	When unblocking a group you do this
										
	Example: DENYGROUPS="/site:\-GROUPNAME$
	Result: '$irctrigger' del group GROUPNAME
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
        sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep --color=always -i "$search"
        if [ "`sed -n "/DENYGROUPS/,/ALLOWDIRS/p" $predircheck | grep --color=always -i "$search" | wc -l`" = 0 ]
        then
                echo "$search not found in blocklist"
        fi
fi

if [[ "$ARGS" = "add release"* ]]
then
	section=`echo $ARGS | awk -F " " '{print $3}'`
	regexp=`echo $ARGS | awk -F " " '{print $4}'`
	regexpc=`echo $INPUT | awk -F " " '{print $4}'`
	echo "Blocking $regexpc in section $section"
	$glroot/bin/sed -i "0,/\/site\/$section:/s/$section:/$section:$regexp|/" $predircheck
	$glroot/bin/sed -i "/\/site\/$section:/ s/|$//gI" $predircheck
	$glroot/bin/sed -i "/\/site\/$section:/ s/||/|/gI" $predircheck
fi

if [[ "$ARGS" = "add newline release"* ]]
then
	section=`echo $ARGS | awk -F " " '{print $4}'`
	regexp=`echo $ARGS | awk -F " " '{print $5}'`
	regexpc=`echo $INPUT | awk -F " " '{print $5}'`
	echo "Blocking $regexpc in section $section on a new line"
	$glroot/bin/sed -i "0,/.*\/site\/$section.*/s/.*\/site\/$section.*/\/site\/$section:$regexp|\n&/" $predircheck
	$glroot/bin/sed -i "/\/site\/$section:/ s/|$//gI" $predircheck
	$glroot/bin/sed -i "/\/site\/$section:/ s/||/|/gI" $predircheck
fi

if [[ "$ARGS" = "add newsection"* ]]
then
	osection=`echo $ARGS | awk -F " " '{print $3}'`
	nsection=`echo $ARGS | awk -F " " '{print $4}'`
	regexp=`echo $ARGS | awk -F " " '{print $5}'`
	regexpc=`echo $INPUT | awk -F " " '{print $5}'`
	echo "Blocking $regexpc in new section $nsection"
	$glroot/bin/sed -i "0,/.*\/site\/$osection.*/s/.*\/site\/$osection.*/\/site\/$nsection:$regexp|\n&/" $predircheck
	$glroot/bin/sed -i "/\/site\/$nsection:/ s/|$//gI" $predircheck
fi

if [[ "$ARGS" = "edit section"* ]]
then
        section=`echo $ARGS | awk -F " " '{print $3}'`
        startword=`echo $ARGS | awk -F " " '{print $4}'`
	startwordc=`echo $INPUT | awk -F " " '{print $4}'`
        regexp=`echo $ARGS | awk -F " " '{print $5}'`
        regexpc=`echo $INPUT | awk -F " " '{print $5}'`
        if [ ! -z $regexp ]
        then
            echo "Adding wordblock $regexpc in section $section"
            $glroot/bin/sed -i "/\/site\/$section:/ s/$startword/$regexp|$startword/" $predircheck
            $glroot/bin/sed -i "/\/site\/$section:/ s/\\|$//gI" $predircheck
            $glroot/bin/sed -i "/\/site\/$section:/ s/||/|/gI" $predircheck
        else
            echo "Removing wordblock $startwordc in section $section"
            $glroot/bin/sed -i "/\/site\/$section:/ s/$startword//" $predircheck
            $glroot/bin/sed -i "/\/site\/$section:/ s/|)/)/gI" $predircheck
            $glroot/bin/sed -i "/\/site\/$section:/ s/(|/(/gI" $predircheck
            $glroot/bin/sed -i "/\/site\/$section:/ s/||/|/gI" $predircheck

        fi
fi

if [[ "$ARGS" = "del release"* ]]
then
	section=`echo $ARGS | awk -F " " '{print $3}'`
	regexp=`echo $ARGS | awk -F " " '{print $4}'`
	regexpc=`echo $INPUT | awk -F " " '{print $4}'`
	echo "Unblocking $regexpc in section $section"
	$glroot/bin/sed -i "/\/site\/$section:/ s/$regexp//g" $predircheck
	$glroot/bin/sed -i "/\/site\/$section:/ s/\/site\/$section:|/\/site\/$section:/gI" $predircheck
	$glroot/bin/sed -i "/\/site\/$section:/ s/|$//gI" $predircheck
	$glroot/bin/sed -i "/\/site\/$section:/ s/||/|/gI" $predircheck
fi

if [[ "$ARGS" = "del section"* ]]
then
	section=`echo $ARGS | awk -F " " '{print $3}'`
	echo "Removed all rows containing section: $section"
	$glroot/bin/sed -i "/\/site\/$section/d" $predircheck
fi

if [[ "$ARGS" = "add group"* ]]
then
	group=`echo $ARGS | awk -F " " '{print $3}'`
	echo "Blocking group $group"
	$glroot/bin/sed -i "/^DENYGROUPS=/ s/\"$/|\\\-$group\\\$\"/" $predircheck
fi

if [[ "$ARGS" = "del group"* ]]
then
	group=`echo $ARGS | awk -F " " '{print $3}'`
	echo "Unblocking group $group"
	$glroot/bin/sed -i "/^DENYGROUPS=/ s/\\\\-$group\\\$//gI" $predircheck
	$glroot/bin/sed -i "/^DENYGROUPS=/ s/|\"/\"/gI" $predircheck
	$glroot/bin/sed -i "/^DENYGROUPS=/ s/||/|/gI" $predircheck
	$glroot/bin/sed -i "/^DENYGROUPS=/ s/\/site:|/\/site:/gI" $predircheck
fi

exit 0
