#!/bin/bash
VER=1.1
#--[ Intro ]---------------------------------------------------------#
#                                                                    #
# Tur-Undupe. A script to let users undupe single files through irc. #
#                                                                    #
# I previously used eur0dance's public undupe, but it has a few      #
# shortcomings in that it dosnt specify if something went wrong or   #
# similar. Plus, this one is 100% standalone from your botscript.    #
#                                                                    #
# So I decided to make my own that checks if the files can be        #
# executed, if the dupefile can be written to, that the user         #
# specified really has flag C and that the file was indeed unduped.  #
# It will also tell you who duped the undupe file and when.          #
#                                                                    #
#--[ Install ]-------------------------------------------------------#
#                                                                    #
# Copy tur-undupe.sh to /glftpd/bin. Make it executable (chmod 755). #
#-                                                                  -#
# Copy tur-undupe.tcl to your bots scripts dir and load it in the    #
#  config file.                                                      #
#  If you previously used eur0dance's undupe script in your bot,     #
#  either remove that or just load this one AFTER the botscript.     #
#-                                                                  -#
# The most important part: The undupe binary in /glftpd/bin          #
# must be executed as root since the permissions on the dupefile     #
# changes. So, chmod +s /glftpd/bin/undupe                           #
# Also, make sure the undupe binary works for you. A number of       #
# glftpd distributions comes with an undupe binary that just dosnt   #
# work. Run it from shell ( /glftpd/bin/undupe ) and it should give  #
# you the help text. If it does, fine. If not and its just a blank   #
# response, you'll need to recompile it from source:                 #
#  rm /glftpd/bin/undupe                                             #
#  cd /glftpd/bin/sources                                            #
#  gcc -o /glftpd/bin/undupe undupe.c                                #
# Remember to redo the permissions on the file.                      #
#                                                                    #
# If your linux distro dosnt support +s, you'll need to find a way   #
# so that the undupe binary is always executed as root (sudo etc).   #
#                                                                    #
# Errors like "unduping blabla - FAILED" means we cant write to the  #
# dupefile.                                                          #
#                                                                    #
#-                                                                  -#
# Change the settings below:                                         #
#                                                                    #
#--[ Settings ]------------------------------------------------------#
#                                                                    #
# undupe   = Path to the undupe binary. Comes with glftpd.           #
#                                                                    #
# dupelist = Path to the dupelist binary. Comes with glftpd.         #
#                                                                    #
#            NOTE: If you do not have glftpd.conf in /etc, you'll    #
#            need to edit dupelist.c and change the path manually.   #
#            if((fp = fopen("/etc/glftpd.conf", "r")) == NULL)       #
#                            ^^^^^^^^^^^^^^^^                        #
#            Then recomple the source:                               #
#            gcc -o /glftpd/bin/dupelist dupelist.c                  #
#                                                                    #
#            Run it from shell. Make sure it spits out a lot of      #
#            filenames.                                              #
#                                                                    #
# dupefile = Full path to the dupefile file.                         #
#                                                                    #
# glconf   = Full path to glftpd.conf                                #
#                                                                    #
# datebin  = We use some functions that requires 'date -d'. Not all  #
#            date binaries support that. FBSD users needs to         #
#            compile the sh-utils package and use the full path to   #
#            'gdate' here.                                           #
#            Otherwise, if date is in your path, leave this empty or #
#            specify full path it (Most people can leave it empty).  #
#                                                                    #
# username = Username that will do the unduping. This user must      #
#            exist and have flag C.                                  #
#                                                                    #
# usersdir = Path to your users.                                     #
#                                                                    #
# header   = This will be the header or all output to irc.           #
#                                                                    #
#--[ Usage ]---------------------------------------------------------#
#                                                                    #
# The default trigger is !undupe <filename>.                         #
# No filename will result in a 'usage' text.                         #
# Only single files can be unduped for security reasons. No, * does  #
# not work.                                                          #
#                                                                    #
# If, when unduping, it says something like 12421Days, 9hours...     #
# then you probably have different times in glftpd and shell. The    #
# time inside glftpd needs to match that in the shell.               #
# Run 'site time' inside glftpd and check if thats the case. If it   #
# is, check the FAQ for glftpd for how to fix it.                    #
# Also see Changelog entry for version 1.1.                          #
#                                                                    #
#--[ Changelog ]-----------------------------------------------------#
#                                                                    #
# 1.1    : Some glftpd systems seems to have problems writing the    #
#          correct upload time into the dupefile, making that a 0.   #
#          Actually, it seems the glftpds undupe binary sets some    #
#          files to 0 seconds. I'm not sure on when.                 #
#          This looks dumb when it says that something is 13388 days #
#          old at the time of the undupe.                            #
#          The fix is very advanced! If filetime is 0, do not even   #
#          try to calculate the age and dont display anything about  #
#          the age.                                                  #
#          WHO uploaded it will still be displayed.                  #
#                                                                    #
# 1.0.1  : Removed the check if we can write to the dupefile. It was #
#          not accurate since the undupe binary should run as root   #
#          but running the check if we could write to it was done by #
#          the user running the bot.                                 #
#                                                                    #
#          Changed the installation procedure above.                 #
#                                                                    #
#--[ Configure ]-----------------------------------------------------#

undupe=/glftpd/bin/undupe
dupelist=/glftpd/bin/dupelist
dupefile=/glftpd/ftp-data/logs/dupefile
glconf=/glftpd/etc/glftpd.conf
datebin=""

username=glftpd
usersdir=/glftpd/ftp-data/users

#header="\002 [UNDUPE] -"
header=""

bold=""
dgry=14
lred=4
lgrn=9

#--[ Script Start ]--------------------------------------------------#

## Text if no argument is given. You can change this one if you like.
proc_usage() {
  echo -e "$header Tur-Undupe $VER 2003-2006."
  echo -e "$header Specify a single file to undupe too."
  exit 0
}

if [ -z "$datebin" ]; then
  datebin="date"
fi

A1="$1"

proc_calctime() {
  DAYDIFF=0
  MINDIFF=0
  SECDIFF=0

  let DIFF=$datum_2-$datum_1;

  if [ $DIFF -lt 0 ]; then
    let DIFF=DIFF*-1
  fi

  let PERC=$DIFF/60;
  let ORA=$PERC/60;
  let DAYDIFF=$ORA/24;
  let HOURDIFF=$ORA-24*$DAYDIFF;
  let MINDIFF=$PERC-60*$ORA
  let SECDIFF=$DIFF-60*$PERC
  
  if [ "$DAYDIFF" != "0" ]; then
    if [ "$DAYDIFF" -gt "1" ]; then
      timeago=$DAYDIFF"Days"
    else
      timeago=$DAYDIFF"Day"
    fi
  fi
  if [ "$HOURDIFF" != "0" ]; then
    if [ "$HOURDIFF" -gt "1" ]; then
      if [ -z "$timeago" ]; then
        timeago="$HOURDIFF""Hours"
      else
        timeago="$timeago, $HOURDIFF""Hours"
      fi
    else
      if [ -z "$timeago" ]; then
        timeago="$HOURDIFF""Hour"
      else
        timeago="$timeago, $HOURDIFF""Hour"
      fi
    fi
  fi
  if [ "$MINDIFF" != "0" ]; then
    if [ "$MINDIFF" -gt "1" ]; then
      if [ -z "$timeago" ]; then
        timeago="$MINDIFF""Mins"
      else
        timeago="$timeago, $MINDIFF""Mins"
      fi
    else
      if [ -z "$timeago" ]; then
        timeago="$MINDIFF""Min"
      else
        timeago="$timeago, $MINDIFF""Min"
      fi
    fi
  fi
  if [ "$SECDIFF" != "0" ]; then
    if [ "$SECDIFF" -gt "1" ]; then
      if [ -z "$timeago" ]; then
        timeago="$SECDIFF""Secs"
      else
        timeago="$timeago, $SECDIFF""Secs"
      fi
    else
      if [ -z "$timeago" ]; then
        timeago="$SECDIFF""Sec"
      else
        timeago="$timeago, $SECDIFF""Sec"
      fi
    fi
  fi
  if [ -z "$timeago" ]; then
    timeago="some time"
  fi
}

proc_checkexist() {
  unset rawdata; unset filename; unset filetime; unset filewho
  rawdata=`$dupelist | tr -s '\t' '^' | grep "^$A1\^" | head -n1`
  if [ "$rawdata" ]; then
    filename=`echo "$rawdata" | cut -d '^' -f1`
    filetime=`echo "$rawdata" | cut -d '^' -f2`
    filewho=`echo "$rawdata" | cut -d '^' -f3`
  fi
}

proc_verify() {
  if [ "$NOCHECK" != "TRUE" ]; then
    if [ ! -e "$usersdir/$username" ]; then
      echo -e "$header Error. Defined user '$username' does not exist in usersdir."
      echo -e "$header If this is a jailed installation and/or you are sure he has flag C, then add NOCHECK=TRUE"
      echo -e "$header somewhere in the script."
      exit 0
    elif [ ! -r "$usersdir/$username" ]; then
      echo -e "$header Error. Defined user $username can not be read for verification of flag C."
      echo -e "$header If this is a jailed installation and/or you are sure he has flag C, then add NOCHECK=TRUE"
      echo -e "$header somewhere in the script."
      exit 0
    elif [ -z "`grep "^FLAGS [0-9a-zA-Z]*C" $usersdir/$username`" ]; then
      echo -e "$header Error. Defined user '$username' does not have permission to undupe (flag C)."
      echo -e "$header If this is a jailed installation and/or you are sure he has flag C, then add NOCHECK=TRUE"
      echo -e "$header somewhere in the script."
      exit 0
    elif [ -z "`$datebin --help | grep "\-d\,"`" ]; then
      echo -e "$header Error. It does not seem like your date binary supports the -d option."
      echo -e "$header Download a GNU compliant date binary (FBSD, compile sh-utils for gdate)"
      echo -e "$header and specify it as datebin in this script."
      echo -e "$header Add NOCHECK=TRUE somewhere in the script to skip this check."
      exit 0
    fi
  fi

  if [ ! -e "$glconf" ]; then
    echo -e "$header Can not find glftpd.conf. Verify glconf setting."
    exit 0
  elif [ ! -x "$undupe" ]; then
    echo -e "$header Can not execute undupe. Check path and perms."
    exit 0
  elif [ ! -x "$dupelist" ]; then
    echo -e "$header Can not execute dupelist. Check path and perms."
    exit 0
  fi
}

if [ -z "$A1" ]; then
  proc_usage
elif [ -z "`echo "$A1" | grep ".."`" ]; then
  proc_usage
fi

proc_verify

proc_checkexist

if [ -z "$filename" ]; then
  echo "${lred}$A1${dgry} was not found in dupefile."
  if [ -z "`$dupelist | head -n1`" ]; then
    echo -e "In fact, it dosnt seem like anything is duped from running dupelist. You might need to recompile it."
  fi
  exit 0
else
  if [ "$filetime" != "0" ]; then
    datum_2=`$datebin +%s`
    datum_1="$filetime"
    proc_calctime
    echo -en "${dgry}Unduping ${lred}$A1${dgry}, uploaded by ${lred}$filewho${dgry} -${lred} $timeago${dgry} ago"
  else
    echo -en "${dgry}Unduping ${lred}$A1${dgry}, uploaded by ${lred}$filewho"
  fi
  #$undupe -u ${username} -r ${glconf} -f ${A1} | grep "DontShowThisText"
  $undupe -f ${A1} | grep "DontShowThisText"
  proc_checkexist
  if [ "$filename" ]; then
    if [ "$NOCHECK" = "TRUE" ]; then
      echo -e " -${lred} FAILED${dgry}! - Set NOCHECK to FALSE to see why."
    else
      echo -e " -${lred} FAILED"
    fi
  else
    echo -e " -${lgrn} OK${dgry}!"
  fi
fi

exit 0
