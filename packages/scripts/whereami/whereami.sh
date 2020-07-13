#!/bin/bash
VER=1.7
###############################################################
# WhereAmI by Turranius ( http://www.grandis.nu/glftpd/ )     #
###                                                         ###
# Simple script to show where you are in weektop, monthtop    #
# etc etc. Also works fine for groups.                        #
# Will also show who is in front of you, and who is after.    #
# Ment to be used in irc with the .tcl script that comes with #
# this package.                                               #
#                                                             #
# Since version 1.7, it can also display a "hall of shame"    #
# for nukes.                                                  #
#                                                             #
###                                                         ###
#                                                             #
# Installation:                                               #
# Copy whereami.sh to /glftpd/bin (default).                  #
# Make it executable to the user running the bot. (chmod 755) #
# Edit STATSBIN below to wherever your stats command is       #
# (see Requirements:) and also path to glftpd.conf.           #
#                                                             #
# Edit MBLIMIT to when you want it to convert to GB instead   #
# of MB. Looks better with 92GB instead of 94208MB I think.   #
# The number is in MB.                                        #
# Set it to "" to disable (always use MB).                    #
#                                                             #
# Edit USERDIR to where your users are.                       #
#                                                             # 
# Copy whereami.tcl to your bots /scripts folder and add the  #
# following to your bots .conf file, at the bottom:           #
# source scripts/whereami.tcl                                 #
# Edit whereami.tcl and change the path to wheerami.sh IF you #
# did not put it in /glftpd/bin.                              #
# If you wish to change the command users type to execute it, #
# change the 'bind pub - !alup pub:alup' lines. Only the      #
# !alup needs to be changed, not the pub:alup                 #
# Rehash the bot when ready.                                  #
# If you change there, you might want to change the help text #
# It is right below the part where you should not edit in     #
# this script.                                                #
###                                                         ###
# Commands in whereami.tcl are:                               #
# Usage: !alup <username>                                     #
# !alup, !aldn = Alltime up, Alltime down.                    #
# !mnup, !mndn = Month up, Month down.                        #
# !wkup, !wkdn = Week up, Week down.                          #
# !tdup, !tddn = Today up, Today down.                        #
# !nuketop     = Shows the "hall of shame" for nukes.         #
#                                                             #
# For groups: !galup <group>                                  #
# !galup, !galdn = Alltime up, Alltime down.                  #
# Well, all the commands for users works for groups, part     #
# from nuketop, just add a g infront of them.                 #
#                                                             #
# Note: Run any command without any arguments for a brief     #
# description.                                                #
#                                                             #
# If you want to try it from shell, its whereami.sh user a u  #
# for alup. Run stats to get the arguments.                   #
# For nuketop, its: whereami.sh nuketop user                  #
#                                                             #
###                                                         ###
# Requirements:                                               #
# This script uses glFtpD 'stats' which comes with glftpd.    #
# If it is not in your /glftpd/bin dir, look for whereever    #
# you unpacked glftpd.                                        #
# Just run /glftpd/bin/stats to check.                        #
#                                                             #
# The "nuketop" function does not use the stats binary. Its a #
# totally seperate function in this script.                   #
#                                                             #
###############################################################
# Changelog:                                                  #
#                                                             #
# 1.7   : Added a nuketop as requested by rade.               #
#         It will show the hall of shame for nukes.           #
#         New .tcl for this, so make sure to replace it and   #
#         rehash the bot. If you want to try this function    #
#         from shell, try: ./whereami.sh nuketop username     #
#                                                             #
#         From irc, per default, its !nuketop <username>      #
#                                                             #
#         It sorts first on times nuked and secondly on MB    #
#         amount nuked.                                       #
#                                                             #
#         Should both those numbers be the same, it will sort #
#         on when the last nuke happened and the latest user  #
#         to be nuked will be the "winner" (higher position). #
#                                                             #
# 1.6.1 : Another xoLax(c) bug found. Would still report the  #
#         wrong position for some users. Even more fixed so   #
#         it shouldnt happen.                                 #
#                                                             #
#         Fixed an error that would appear on some systems    #
#         where it had problems reading any position with '1' #
#         in it (never saw it myself). Thanks somayo.         #
#                                                             #
# 1.6 : - User positions were reported wierd. Should be good  #
#         now. Thanks xoLax for finding it.                   #
#                                                             #
#         When finding the position of the defined user, it   #
#         now greps only the username. So if someone has your #
#         exact name in their tagline, it wont matter anymore.#
#                                                             #
# 1.5 : - Changed when grepping group/username from           #
#         'grep -w "$1"' to 'grep " $1 "' to make it not get  #
#         a hit on the wrong group etc. Thanks LPC.           #
#                                                             #
# 1.4 : - In 1.3, I changed from using expr to using bash     #
#         itself when counting numbers. Seems bash does not   #
#         like to add, for instance, 08+1. Has to be 8+1.     #
#         This could cause "Value too great for base" errors. #
#         So, went back to using expr instead.                #
# 1.3 : - Rewrote how it gets files and MB. Had cut problems  #
#         before but it should work better now.               #
#       - Replaced all awk's with cut's too.                  #
#       - Using bash for calculations instead of expr.        #
#       - Updated whereami.tcl to 1.1. Only set the binary    #
#         once now.                                           #
# 1.2 : If a user had 11 chars in the username, it would crap #
#       out. Thanks Peza.                                     #
# 1.1 : Added MBLIMIT.                                        #
# 1.0 : Initial release.                                      #
###                                                         ###
# Settings:

STATSBIN="/glftpd/bin/stats -r /etc/glftpd.conf"
MBLIMIT="10000"
USERDIR="/glftpd/ftp-data/users"
TMP=/tmp

#################################################################
# No changes needed below here unless you want to change output #
#################################################################

## Show help.
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "WhereAmI $VER. Use: !command <username/group>. Commands are, for users: alup,aldn,mnup,mndn,wkup,wkdn,tdup,tddn,nuketop. For groups, just put a g infront of any user command (except nuketop), like !galup <group>"
  exit 0
fi

if [ "$1" = '.' ]; then
  echo "User does not exist.. try again."
  exit 0
fi

if [ -z "$TMP" ]; then
  TMP="/tmp"
fi

## Nuketop is a totally seperate procedure.
if [ "`echo "$1" | tr [:upper:] [:lower:]`" = "nuketop" ]; then
  if [ -z "$2" ]; then
    echo "Please specify a username to check nuketop."
    exit 0
  elif [ ! -e "$USERDIR/$2" ]; then
    echo "User $2 does not exist."
    exit 0
  fi

  if [ -e "$TMP/nuketop.tmp" ]; then
    rm -f "$TMP/nuketop.tmp"
  fi

  num=0
  for each in `grep "^NUKE\ " $USERDIR/* | grep -v "NUKE [0-9]* 0" | sort -k 3,3nr -k4,4nr -k2,2nr | cut -d ':' -f1`; do
    num=$[$num+1]
    username="`basename $each`"
    echo "$num@$username" >> $TMP/nuketop.tmp
  done
  
  USERPOSRAW="`grep "@$2$" $TMP/nuketop.tmp`"

  if [ -z "$USERPOSRAW" ]; then
    echo "Nothing found for $2. Misspelled or no nukes registered for $2"
    exit 0
  fi
  USERPOS="`echo "$USERPOSRAW" | cut -d '@' -f1`"
  USERNAME="`echo "$USERPOSRAW" | cut -d '@' -f2`"
  USERTIMES="`grep "^NUKE\ " $USERDIR/$2 | cut -d ' ' -f3`"
  USERMB="`grep "^NUKE\ " $USERDIR/$2 | cut -d ' ' -f4`"
  if [ "$MBLIMIT" ]; then
    USERMB="$( echo "$USERMB" | tr -d '[:alpha:]' )"
    if [ "$USERMB" -gt "$MBLIMIT" ]; then
      USERMB="$( expr "$USERMB" \/ "1024" )"
      USERMB="$USERMB GB"
    else
      USERMB="$USERMB MB"
    fi
  fi

  ## IF this user is first.
  if [ "$USERPOS" = "1" ]; then
    AFTERPOSRAW="`grep "^2@" $TMP/nuketop.tmp`"
    if [ -z "$AFTERPOSRAW" ]; then
      echo "$USERNAME is 1st and ONLY on the list. Nuked $USERTIMES times with $USERMB nuked."
    else
      AFTERPOS="2"
      AFTERNAME="`echo "$AFTERPOSRAW" | cut -d '@' -f2`"
      AFTERTIMES="`grep "^NUKE\ " $USERDIR/$AFTERNAME | cut -d ' ' -f3`"
      AFTERMB="`grep "^NUKE\ " $USERDIR/$AFTERNAME | cut -d ' ' -f4`"
      if [ "$MBLIMIT" ]; then
        AFTERMB="$( echo "$AFTERMB" | tr -d '[:alpha:]' )"
        if [ "$AFTERMB" -gt "$MBLIMIT" ]; then
          AFTERMB="$( expr "$AFTERMB" \/ "1024" )"
          AFTERMB="$AFTERMB GB"
        else
          AFTERMB="$AFTERMB MB"
        fi
      fi
      echo "$USERNAME is 1st with $USERTIMES nukes in $USERMB, followed by $AFTERNAME with $AFTERTIMES nukes in $AFTERMB nuked"      
    fi
    exit 0
  fi

  ## If this user is last.
  if [ "$num" = "$USERPOS" ]; then
    BEFOREPOS=$[$num-1]
    BEFOREPOSRAW="`grep "^$BEFOREPOS@" $TMP/nuketop.tmp`"
    BEFORENAME="`echo "$BEFOREPOSRAW" | cut -d '@' -f2`"
    BEFORETIMES="`grep "^NUKE\ " $USERDIR/$BEFORENAME | cut -d ' ' -f3`"
    BEFOREMB="`grep "^NUKE\ " $USERDIR/$BEFORENAME | cut -d ' ' -f4`"
    if [ "$MBLIMIT" ]; then
      BEFOREMB="$( echo "$BEFOREMB" | tr -d '[:alpha:]' )"
      if [ "$BEFOREMB" -gt "$MBLIMIT" ]; then
        BEFOREMB="$( expr "$BEFOREMB" \/ "1024" )"
        BEFOREMB="$BEFOREMB GB"
      else
        BEFOREMB="$BEFOREMB MB"
      fi
    fi

    echo "$USERNAME is last at "#"$USERPOS(Tihi) with $USERTIMES nukes in $USERMB. In front, at "#"$BEFOREPOS is $BEFORENAME with $BEFORETIMES nukes in $BEFOREMB."
    exit 0
  fi

  ## This user is neither first or last:
  BEFOREPOS=$[$USERPOS-1]
  BEFOREPOSRAW="`grep "^$BEFOREPOS@" $TMP/nuketop.tmp`"
  BEFORENAME="`echo "$BEFOREPOSRAW" | cut -d '@' -f2`"
  BEFORETIMES="`grep "^NUKE\ " $USERDIR/$BEFORENAME | cut -d ' ' -f3`"
  BEFOREMB="`grep "^NUKE\ " $USERDIR/$BEFORENAME | cut -d ' ' -f4`"
  if [ "$MBLIMIT" ]; then
    BEFOREMB="$( echo "$BEFOREMB" | tr -d '[:alpha:]' )"
    if [ "$BEFOREMB" -gt "$MBLIMIT" ]; then
      BEFOREMB="$( expr "$BEFOREMB" \/ "1024" )"
      BEFOREMB="$BEFOREMB GB"
    else
      BEFOREMB="$BEFOREMB MB"
    fi
  fi

  AFTERPOS=$[$USERPOS+1]
  AFTERPOSRAW="`grep "^$AFTERPOS@" $TMP/nuketop.tmp`"
  AFTERNAME="`echo "$AFTERPOSRAW" | cut -d '@' -f2`"
  AFTERTIMES="`grep "^NUKE\ " $USERDIR/$AFTERNAME | cut -d ' ' -f3`"
  AFTERMB="`grep "^NUKE\ " $USERDIR/$AFTERNAME | cut -d ' ' -f4`"
  if [ "$MBLIMIT" ]; then
    AFTERMB="$( echo "$AFTERMB" | tr -d '[:alpha:]' )"
    if [ "$AFTERMB" -gt "$MBLIMIT" ]; then
      AFTERMB="$( expr "$AFTERMB" \/ "1024" )"
      AFTERMB="$AFTERMB GB"
    else
      AFTERMB="$AFTERMB MB"
    fi
  fi

  echo "Ahead of $USERNAME at "#"$BEFOREPOS is $BEFORENAME with $BEFORETIMES nukes in $BEFOREMB. $USERNAME is "#"$USERPOS with $USERTIMES nukes in $USERMB. Behind them both at "#"$AFTERPOS comes $AFTERNAME with $AFTERTIMES nukes in $AFTERMB"

  if [ -e "$TMP/nuketop.tmp" ]; then
    rm -f "$TMP/nuketop.tmp"
  fi

  exit 0  
fi
  

## Get all stats data for specified user.
USERDATA="$( $STATSBIN -$2 -$3 -x 500 | grep "\[*\]\ $1\ " | tr -d '[' | tr -d ']' )"

## Didnt get any data.
if [ -z "$USERDATA" ]; then
  echo "Nothing found for $1. Misspelled or nothing is registered for this period."
  exit 0
fi

USERPOS="$( echo "$USERDATA" | cut -d ' ' -f1 | tr -d '[' | tr -d ']' )"
if [ -z "`echo "$USERPOS" | grep ".."`" ]; then
  USERPOS=0$USERPOS
fi

USERBEFORENR=`expr "$USERPOS" \- "1"`
if [ -z "`echo "$USERBEFORENR" | grep ".."`" ]; then
  USERBEFORENR=0$USERBEFORENR
fi

USERAFTERNR=`expr "$USERPOS" \+ "1"`
if [ -z "`echo "$USERAFTERNR" | grep ".."`" ]; then
  USERAFTERNR=0$USERAFTERNR
fi

if [ "$USERPOS" = "01" ]; then
  USERBEFOREDATA="NONE"
else
  USERBEFOREDATA="$( $STATSBIN -$2 -$3 -x 500 | grep '^\['$USERBEFORENR'\] ' )"
fi

USERAFTERDATA="$( $STATSBIN -$2 -$3 -x 500 | grep '^\['$USERAFTERNR'\] ' )"
if [ -z "$USERAFTERDATA" ]; then
  USERAFTERDATA="NONE"
fi

USERNAME="$( echo $USERDATA | cut -d ' ' -f2 )"
for each in $USERDATA; do
  USERFILES=$USERMEG
  USERMEG=$last
  last=$each
done
unset each; unset last

USERFILES="$( echo "$USERFILES" | tr -d '[:alpha:]' )"

if [ "$MBLIMIT" ]; then
  USERMEG="$( echo "$USERMEG" | tr -d '[:alpha:]' )"
  if [ "$USERMEG" -gt "$MBLIMIT" ]; then
    USERMEG="$( expr "$USERMEG" \/ "1024" )"
    USERMEG="$USERMEG GB"
  else
    USERMEG="$USERMEG MB"
  fi
fi

if [ "$USERBEFOREDATA" != "NONE" ]; then
  USERBEFOREPOS="$USERBEFORENR"
  USERBEFORENAME="$( echo $USERBEFOREDATA | cut -d ' ' -f2 )"

  for each in $USERBEFOREDATA; do
    USERBEFOREFILES=$USERBEFOREMEG
    USERBEFOREMEG=$last
    last=$each
  done
  unset each; unset last
  USERBEFOREFILES="$( echo "$USERBEFOREFILES" | tr -d '[:alpha:]' )"

  if [ "$MBLIMIT" ]; then
    USERBEFOREMEG="$( echo "$USERBEFOREMEG" | tr -d '[:alpha:]' )"
    if [ "$USERBEFOREMEG" -gt "$MBLIMIT" ]; then
      USERBEFOREMEG="$( expr "$USERBEFOREMEG" \/ "1024" )"
      USERBEFOREMEG="$USERBEFOREMEG GB"
    else
      USERBEFOREMEG="$USERBEFOREMEG MB"
    fi
  fi
fi

if [ "$USERAFTERDATA" != "NONE" ]; then
  USERAFTERPOS="$USERAFTERNR"
  USERAFTERNAME="$( echo $USERAFTERDATA | cut -d ' ' -f2 )" 

  for each in $USERAFTERDATA; do
    USERAFTERFILES=$USERAFTERMEG
    USERAFTERMEG=$last
    last=$each
  done
  unset each; unset last
  USERAFTERFILES="$( echo "$USERAFTERFILES" | tr -d '[:alpha:]' )"

  if [ "$MBLIMIT" ]; then
    USERAFTERMEG="$( echo "$USERAFTERMEG" | tr -d '[:alpha:]' )"
    if [ "$USERAFTERMEG" -gt "$MBLIMIT" ]; then
      USERAFTERMEG="$( expr "$USERAFTERMEG" \/ "1024" )"
      USERAFTERMEG="$USERAFTERMEG GB"
    else
      USERAFTERMEG="$USERAFTERMEG MB"
    fi
  fi
fi

if [ "$USERBEFOREDATA" = "NONE" ]; then
  if [ "$USERAFTERDATA" = "NONE" ]; then
    echo "$USERNAME is 1st and ONLY on the list with $USERFILES files and $USERMEG"
  else
    echo "$USERNAME is 1st with $USERFILES files and $USERMEG, followed by $USERAFTERNAME with $USERAFTERFILES files and $USERAFTERMEG"
  fi
else
  if [ "$USERAFTERDATA" = "NONE" ]; then
    echo "$USERNAME is last at "#"$USERPOS(Tihi) with $USERFILES"F" in $USERMEG. In front, at "#"$USERBEFOREPOS is $USERBEFORENAME with $USERBEFOREFILES"F" in $USERBEFOREMEG."
  else
    echo "Ahead of $USERNAME at "#"$USERBEFOREPOS is $USERBEFORENAME with $USERBEFOREFILES"F" and $USERBEFOREMEG. $USERNAME is "#"$USERPOS with $USERFILES"F" and $USERMEG. Behind them both at "#"$USERAFTERPOS comes $USERAFTERNAME with $USERAFTERFILES"F" and $USERAFTERMEG."
  fi
fi

exit 0
