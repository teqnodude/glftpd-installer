#!/bin/bash
VER=1.3.1
#--[ Intro ]--------------------------------------------#
#                                                       #
# Tur-IrcAdmin. A script for lazy people to do just     #
# about anything as if logged on to the site.           #
#                                                       #
# Who do I recomend to run this? Well, nobody since if  #
# you accidently allow someone access to this who       #
# shouldnt, he/she can do anything basically.           #
#                                                       #
# The tcl is locked to a single chan that the executor  #
# must be in and it is also locked by default so the    #
# user must be added to THIS bot with flag o (just      #
# being an @ is not enough).                            #
# By THIS bot, I mean the one that the tcl is loaded on #
#                                                       #
#-[ Install ]-------------------------------------------#
#                                                       #
# Copy tur-ircadmin.sh to /glftpd/bin and chmod 755.    #
#                                                       #
# Copy tur-ircadmin.tcl to your bots config dir. Edit   #
# it and check the settings in it. When done, load      #
# it in the bots config file and rehash the bot.        #
#                                                       #
#--[ Settings ]-----------------------------------------#
#                                                       #
# ftp  =   Full path to ftp.                            #
#                                                       #
# user   = The username that will log on to the site    #
#          and do the stuff. Make sure he has access to #
#          everything you want him to be able to do.    #
#          This user should NOT have flag 5 (color).    #
#                                                       #
# pass   = The above users password.                    #
#                                                       #
# host   = Hostname to log into. Just the hostname.     #
#                                                       #
# port   = Port of above hostname.                      #
#                                                       #
# log    = Log all commands to this file. Since the     # 
#          syslog log will contain only the name of the # 
#          user specified above, you might want another # 
#          log to check who made what.                  # 
#          Set to "" to disable.                        # 
#          Create this file and set chmod 666 on it.    # 
#                                                       #
# maxlines       = Maximum number of lines to echo back #
#                  to irc. Just so bot dosnt time out.  #
#                                                       #
# alignleft      = Remove the first space from output.  #
#                  TRUE/FALSE.                          #
#                                                       #
# mergespaces    = Merge spaces together? Less text,    #
#                  uglier output. TRUE/FALSE            #
#                                                       #
# merge          = Single chars, space seperated. Any   #
#                  of these will be merged down to 1 if #
#                  there are multiple ones besides one  #
#                  another. Example: ----- would make - #
#                  By default its turned off with a #   #
#                                                       #
# remove         = Single chars, space seperated. These #
#                  will be deleted totally.             #
#                  By default its turned off with a #   #
#                                                       #
# hideemptylines = Dont output empty lines. TRUE/FALSE. #
#                                                       #
# clean          = This is what to clean up and not     #
#                  show in the output. Its a standard   #
#                  egrep -v line. Dont edit if you dont #
#                  understand it.                       #
#                                                       #
# teston = If this is set to TRUE, you may run          #
# ./tur-ircadmin.sh test                                #
# from shell to see if ftp works. Once verified, set    #
# it to FALSE.                                          #
#                                                       #
#--[ Info ]---------------------------------------------#
#                                                       #
# Thats about it. If you want to try it from shell, you #
# must specify a name as first argument for logging     #
# purposes. Dosnt have to be any existing user. For     #
# example: tur-ircadmin.sh ostnisse user turranius      #
# would show userinfo for turranius and log it as if    #
# ostnisse ran the command.                             #
#                                                       #
# Make sure to lock it tight in the tcl so nobody can   #
# use it unless you want them too.                      #
#                                                       #
#--[ Changelog ]----------------------------------------#
#                                                       #
#   1.3.1 : Added some more cleanup for crap that would #
#           appear on some distros.                     #
#                                                       #
#           A new option called "clean".                #
#           Here we define what not to show, but dont   #
#           play with this one if you do not understand #
#           the format.                                 #
#           Just a standard egrep -v "$clean" line.     #
#                                                       #
#     1.3 : Now uses 'ftp' instead of 'ncftp'. Someone  #
#           sent me a diff on tur-addip for doing this  #
#           which I forgot. Lost the email but found    #
#           diff file which I used. Let me know who you #
#           are to be credited properly :)              #
#                                                       #
#           Should help those who had "unknown terminal"#
#           errors and similar with ncftp.              #
#                                                       #
#           If upgrading, make sure to test it first.   #
#           hostname should no longer have ftp://       #
#                                                       #
#     1.2 : Added a filter for that "Thank you for      #
#           using NcFTP Client" messages that NcFTP     #
#           spits out randomly.                         #
#                                                       #
#           Changed 'ncftp' to '$ncftp'. Previously it  #
#           would ignore the ncftp argument and only    #
#           work if the ncftp binary was in your path   #
#           which it, obviously, is for me =)           #
#                                                       #
# Tcl 1.1 : Just changed the mainchan arg to mainchania #
#           It used the same as tur-addip so if you had #
#           both, one of them didnt work.               #
#                                                       #
#--[ Contact ]------------------------------------------#
#                                                       #
# http://www.grandis.nu/glftpd - http://grandis.mine.nu #
#                                                       #
#--[ Settings ]-----------------------------------------#

ftp=/bin/ftp
user=glftpd
pass=glftpd
host=localhost
port=changeme

log=/glftpd/ftp-data/logs/tur-ircadmin.log

maxlines=25

alignleft=TRUE
mergespaces=FALSE
# merge="- ~ ="
# remove="| > +"
hideemptylines=TRUE

clean="^230 User $user|^221-|Remote system type is | mode to transfer files\."

teston=FALSE

#--[ Script Start ]-------------------------------------#

NICK="$1"

if [ -z "$2" -a "$1" != "test" ]; then
  echo "Got no command. Quitting."
  exit 0
fi

ARGS=`echo "$@" | cut -d ' ' -f2-`

proc_log() {
  if [ "$log" ]; then
    echo `date "+%a %b %e %T %Y"`" : $NICK : $ARGS" >> $log
  fi
}

if [ "$log" ]; then
  if [ ! -w "$log" ]; then
    echo "Error. Cant write to logfile. Create it and set chmod 666 on it."
    exit 0
  fi
fi

if [ ! -x "$ftp" ]; then
  echo "Error. Can not execute $ftp. Make sure its there and executable by the user running this bot."
  exit 0
fi

proc_test() {
  echo "Testing that everything works as it should."
  echo "It should log in and show the userstats for $user"
  echo "Running: echo -e \"user $user $pass\nsite user $user\" | $ftp -vn $host $port"

  until [ -n "$go" ]; do
    echo -n "Ready to go? [Y]es [N]o: "
    read go
    case $go in
      [Nn])
        exit 0
        continue
        ;;
      [Yy])
        echo " "
        go=n
        ;;
      *)
       unset go
       continue
       ;;
    esac
  done
  unset go

  echo ""
  echo -e "user $user $pass\nsite user $user" | $ftp -vn $host $port
  echo ""
  echo "If you see the info for $user above the login is good. You must make sure he has"
  echo "permissions to do whatever you wish to use this script for."
}

if [ "$1" = "test" -a "$teston" = "TRUE" ]; then
  proc_test
  exit 0
fi

proc_log "$ARGS"

RESULT=`echo -e "user $user $pass\nsite $ARGS" | $ftp -vn $host $port | grep -A$maxlines "^230 User $user" | egrep -v "$clean" | cut -c 5- | tr ' ' '^'`

num=0
for rawline in $RESULT; do
  num=$[$num+1]

  if [ "$alignleft" = "TRUE" ]; then
    rawline=`echo $rawline | sed -e 's/^\^//'`
  fi
  if [ "$mergespaces" = "TRUE" ]; then
    rawline=`echo $rawline | tr -s '^'`
  fi
  if [ "$merge" ]; then
    for mergechar in $merge; do
      rawline=`echo $rawline | tr -s "$mergechar"`
    done
  fi
  if [ "$remove" ]; then
    for removechar in $remove; do
      rawline=`echo $rawline | tr -d "$removechar"`
    done
  fi

  if [ "$hideemptylines" = "TRUE" ]; then
    if [ "$rawline" ]; then
      echo "$rawline" | tr '^' ' '
    fi
  else
    echo "$rawline" | tr '^' ' '
  fi
done

if [ "$num" = "$maxlines" ]; then
  echo "Force output break after $maxlines lines."
fi

exit 0