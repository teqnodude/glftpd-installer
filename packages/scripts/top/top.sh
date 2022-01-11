#!/bin/bash
VER=1.1
#----------------------------------------------------------------#
#                                                                #
# Script is based on Tur-Oneline_Stats created by Turranius but  #
# tweaked a lot.       	 					 #
#                                                                #
#-[ Setup ]------------------------------------------------------#
#                                                                #
# Copy top.sh to /glftpd/bin, chmod 755 /glftpd/bin/top.sh       #
#                                                                #
#-[ Configuration ]----------------------------------------------#
#                                                                #
# Edit top.sh and set the following options:       		 #
#                                                                #
# glroot         = The path to your glftpd dir.                  #
#                                                                #
# stats          = Path to glftpds stats binary, seen from       #
#                  glroot above. If you need to, you may also    #
#                  specify the path to glftpd.conf here.         #
#                                                                #
# GO_TO_GIG      = This is a number. How many MB in the output   #
#                  before we convert it to GB instead?           #
#                  Set to "" to disable. It will always show MB  #
#                  if disabled.                                  #
#                                                                #
# MESSAGE        = This is what it will output for each user.    #
#                  You specify the output using "cookies".       #
#                  These are:                                    #
#                                                                #
#                  %POS%    The position of the user in the      #
#                           selected ranking list.               #
#                                                                #
#                  %USER%   The username.                        #
#                                                                #
#                  %MB%     The MB (or GB) that the %USER% is    #
#                           currently at.                        #
#                                                                #
#                  %NAME%   This is set to either MB or GB       #
#                           depending on what it currently is.   #
#                                                                #
#                  %BOLD%   Starts and stops bold output in IRC. #
#                                                                #
#                  %ULINE%  Starts and stops underlined output.  #
#                                                                #
#                  %C1%     This starts the color mode. %C1% is  #
#                           black. It goes from %C0% -> %C15%    #
#                           and corresponds to the same color-   #
#                           codes as when pressing ctrl-k in     #
#                           mirc.                                #
#                                                                #
#                           Note, to stop coloring, set %C1%     #
#                           which is black. For example:         #
#                           %C9%%USER%%C9% does not work while   #
#                           %C9%%USER%%C1% does.                 #
#                                                                #
# ENABLE_COLORS  = TRUE/FALSE. If you do not plan on using       #
#                  any colors, set this to FALSE to speed up the #
#                  execution of the script. Those cookes are not #
#                  translated if this is FALSE.                  #
#                                                                #
# EXCLUDE = Put here which group you want to exclude from stats, #
# 	    only one group is allowed. If this is set then	 #
#           INCLUDE setting does not work.            		 #
#								 #
# INCLUDE = Put here which group you want to only show stats of, #
#           only one group is allowed. If this is set then	 #
#	    EXCLUDE setting does not work.  			 #
#								 #
#--[ Other ]-----------------------------------------------------#
#                                                                #
# You execute this the same way as you would with the stats      #
# binary. It is NOT a standalone script. It just reformats the   #
# output from the stats binary to display it in one line.        #
#                                                                #
# Files, Tagline and Speed are IMO usless info (want to keep it  #
# slim when its just one line), so that information is not used. #
#                                                                #
# There is an example tcl included that you can use if you want  #
# to create your own commands.                                   #
#                                                                #
# If you like, you can modify your botscript to use this script  #
# instead of the stats binary for your normal !wkup commands and #
# the likes. Do NOT specify -r /etC/glftpd.conf in the stats= if #
# so, as the arguments are handled by the botscript itself.      #
#                                                                #
# If you want to have automatic output from time to time, you    #
# can crontab something like this:                               #
# echo `date "+%a %b %e %T %Y"` TURGEN: \"WeekTop Uploads: `/glftpd/bin/top.sh -w`\" >> /glftpd/ftp-data/logs/glftpd.log
# And it will announce the weekup stats at the time you crontab  #
# it at.                                                         #
#                                                                #
#--[ Settings ]--------------------------------------------------#

glroot="/glftpd"
stats="/bin/stats -r /glftpd/etc/glftpd.conf"

GO_TO_GIG="10000"

MESSAGE="%BOLD%%POS%%BOLD%.%C4% %USER%%C4% %C14%(%C4% %MB% %C14%%NAME% %C14%)"

ENABLE_COLORS=TRUE

EXCLUDE=""

INCLUDE=""

#--[ Script Start ]----------------------------------------------#

if [ "$FLAGS" ] && [ "$RATIO" ]
then
    mode="gl"
else
    mode="irc"
    stats="$glroot$stats"
fi

proc_cookies() {

    OUTPUT=`echo $MESSAGE | sed -e "s/%POS%/$position/g"`
    OUTPUT=`echo $OUTPUT | sed -e "s/%USER%/$user/g"`
    OUTPUT=`echo $OUTPUT | sed -e "s/%MB%/$meg/g"`
    OUTPUT=`echo $OUTPUT | sed -e "s/%NAME%/$NAME/g"`
    OUTPUT=`echo $OUTPUT | sed -e "s/%BOLD%//g"`
    OUTPUT=`echo $OUTPUT | sed -e "s/%ULINE%//g"`

    if [ "$ENABLE_COLORS" = "TRUE" ]
    then
	OUTPUT=`echo $OUTPUT | sed -e "s/%C0%/0/g" | sed -e "s/%C1%/1/g" | sed -e "s/%C2%/2/g" | sed -e "s/%C3%/3/g" | sed -e "s/%C4%/4/g" | sed -e "s/%C5%/5/g" | sed -e "s/%C6%/6/g" | sed -e "s/%C7%/7/g" | sed -e "s/%C8%/8/g" | sed -e "s/%C9%/9/g" | sed -e "s/%C10%/10/g" | sed -e "s/%C11%/11/g" | sed -e "s/%C12%/12/g" | sed -e "s/%C13%/13/g" | sed -e "s/%C14%/14/g" | sed -e "s/%C15%/15/g"`
    else
	OUTPUT=`echo $OUTPUT | sed -e "s/%C0%//g" | sed -e "s/%C1%//g" | sed -e "s/%C2%//g" | sed -e "s/%C3%//g" | sed -e "s/%C4%//g" | sed -e "s/%C5%//g" | sed -e "s/%C6%//g" | sed -e "s/%C7%//g" | sed -e "s/%C8%//g" | sed -e "s/%C9%//g" | sed -e "s/%C10%//g" | sed -e "s/%C11%//g" | sed -e "s/%C12%//g" | sed -e "s/%C13%//g" | sed -e "s/%C14%//g" | sed -e "s/%C15%//g"`
    fi
}

args="$@"

if [ -z "$args" ]
then
    $stats -h
    exit 0
fi

if [ ! -z "$EXCLUDE" ] && [ -z "$INCLUDE" ]
then
    $stats $args -g "$EXCLUDE" > $glroot/tmp/stats.tmp
elif [ -z "$EXCLUDE" ] && [ ! -z "$INCLUDE" ]
then
    $stats $args -o "$INCLUDE" > $glroot/tmp/stats.tmp
else 
    $stats $args > $glroot/tmp/stats.tmp
fi


if [ ! -e "$glroot/tmp/stats.tmp" ]
then
    echo "No output file from \"$stats $args\" - make sure it's working."
    exit 0
fi
 
if [ -z "`grep -- "------------------------" "$glroot/tmp/stats.tmp"`" ]
then
    echo "Help:"
    $stats -h
    exit 0
fi
i=1

for rawdata in `egrep "^\[" "$glroot/tmp/stats.tmp" | tr -s ' ' '~' | grep -v "~0GiB~"`
do 
    NAME="GB"
    username="`echo "$rawdata" | cut -d '~' -f2`"
    user="`ls $glroot/ftp-data/users | grep "$username" | grep -v "default.user"`"
    if [ `cat $glroot/ftp-data/users/$user | grep FLAGS | grep 6 | wc -l` = 0 ]
    then
        position="$((i++))"
        position=`printf "%2.0d\n" $position | sed "s/ /0/"`
	rawdata2="`echo "$rawdata" | tr '~' ' '`"
	for rawdata3 in $rawdata2
	do
	    if [ "`echo "$rawdata3" | grep "GiB$"`" ]
	    then
    		meg="`echo "$rawdata3" | tr -d '[:alpha:]'`"
    	        break
            fi
	done
	if [ "$GO_TO_GIG" ] && [ "$meg" -ge "$GO_TO_GIG" ]
	then
	    NAME="TB"
	    meg=$[$meg/1024]
	fi

        proc_cookies
	if [ -z "$OUTMESSAGE" ]
	then
	    OUTMESSAGE="$OUTPUT"
	else
	    OUTMESSAGE="$OUTMESSAGE\n$OUTPUT"
	fi
    fi
done
echo -e "$OUTMESSAGE"

[ -e "$glroot/tmp/stats.tmp" ] && rm -f "$glroot/tmp/stats.tmp"
