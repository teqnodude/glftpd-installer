#!/bin/bash
VER=1.3
#--[ Intro ]-------------------------------------------------------------#
#                                                                        #
# Tur-AddIp. A script to allow users to add, del and list their own IPs. #
# Also, the tagline can be changed with this script.                     #
#                                                                        #
# There are a lot of scripts out there to let users do this, but they    #
# all rely on their own checks to make sure everything is ok (atleast    #
# the ones I've seen).                                                   #
#                                                                        #
# I figured, "Why rely on the script checking everything when glftpd can #
# do it for me?". I mean, all the rules for how the IPs should look are  #
# already in glftpd.conf.                                                #
#                                                                        #
# So, this script uses ftp to log on as a siteop and add the IP. Then    #
# the rules apply as always. No editing the userfile directly. Just add  #
# it as normal.                                                          #
# Same goes for listing, deleting IPs as well as changing tagline.       #
#                                                                        #
# Since this script holds the username and password for a siteop, it     #
# might be best to install it only if you have trusted shell users on    #
# the box or a jailed enviroment.                                        #
#                                                                        #
#--[ Installation ]------------------------------------------------------#
#                                                                        #
# Copy tur-addip.sh to /glftpd/bin and chmod it to 755.                  #
#                                                                        #
# Copy tur-addip.tcl to your bots config dir and edit it. Change         #
# the mainchan to your irc channel. Users must be in this channel to be  #
# able to /msg botname !addip or they'll be ignored.                     #
# Now add it to the bots config and rehash the bot.                      #
#                                                                        #
# Change the settings.                                                   #
#                                                                        #
#--[ Settings ]----------------------------------------------------------#
#                                                                        #
# ftp        = Full path to the ftp binary.                              #
#                                                                        #
# user       = The local user that will do all the adds/dels/lists.      #
#              He MUST have access to the commands: user, addip, delip & #
#              change (site change tagline).                             #
#                                                                        #
# pass       = The above users password.                                 #
#                                                                        #
# host       = The hostname of the site                                  #
#                                                                        #
# port       = The port of the above host.                               #
#                                                                        #
# nonoflags  = Flags, seperated by spaces that should NOT be able to use #
#              this script. Say you're a siteop somewhere. Someone in    #
#              the chan gets your addline (and you are stupid enough to  #
#              give them the PW you normally use), then they can !addip  #
#              on your site on your account, log on and do lots of harm. #
#              Therefor, by default, flags 1,2 and 7 are disabled.       #
#              If this does not concern you, set it to "" to disable.    #
#                                                                        #
# max_ips    = Max number of IPs that can be added to a user. If the     #
#              user has this many or more IPs already in his userfile    #
#              then using the 'add' command will not be possible until   #
#              he dels some.                                             #
#              Set to "" to disable this check.                          #
#                                                                        #
# passchk    = Full path to passchk. Comes with this package but you     #
#              might already have one installed. If you do, make sure    #
#              it gives the output MATCH when running ok. If it gives    #
#              something else, like MATCH! then you can always search    #
#              for MATCH in this script and replace it with MATCH!       #
#              Use 'gcc -o /glftpd/bin/passchk passchk.c' to compile.    #
#              It also comes precompiled on a RH9 box.                   #
#                                                                        #
# passwd     = Full path to glftpds passwd file.                         #
#                                                                        #
# usersdir   = Full path to the dir holding all your users.              #
#                                                                        #
# listonadd  = When adding an IP, do you also want it to show all added  #
#              IPs afterwards? Good reminder for users to clean it up.   #
#                                                                        #
# listondel  = Same as above, but for deleting IPs.                      #
#                                                                        #
# teston     = TRUE/FALSE. Enables the command 'test' which will log in  #
#              and display the information about the defined user above. #
#              Use this to test that all the settings are correct. When  #
#              it looks good, set this to FALSE so users cant run it.    #
#                                                                        #
# log        = File for logging all commands. Set to "" to disable.      #
#                                                                        #
#--[ Info ]--------------------------------------------------------------#
#                                                                        #
# Once you have everything configure, try running it from shell like:    #
# ./tur-addip.sh <username> <password> test                              #
# Make sure teston is set to TRUE first.                                 #
#                                                                        #
# If the above works, su to the user running the bot and try it again.   #
#                                                                        #
# Run it without any args to get a list of available commands (test does #
# not show up in this list).                                             #
#                                                                        #
#--[ Changelog ]---------------------------------------------------------#
#                                                                        #
# 1.3 : Added the max_ips option to limit how many IPs a user can add    #
#       using this script. Should he be over the limit, he can always    #
#       del some or ask a siteop to add it.                              #
#                                                                        #
# 1.2 : Changed so it uses the standard ftp binary instead of ncftp.     #
#       Go through the options again as some of them changed (host etc)  #
#                                                                        #
#       Added ability for users to also use this script to change their  #
#       tagline. Note that you need to replace tur-addip.tcl for this to #
#       work.                                                            #
#                                                                        #
# 1.1 : Added nonoflags so you can disable this script for those who     #
#       could cause damage if their password leaked out (siteops/gadmin) #
#                                                                        #
#--[ Contact ]-----------------------------------------------------------#
#                                                                        #
#                   http://www.grandis.nu/glftpd                         #
#                                                                        #
# Credits goes to Cruxis for helping me with the tcl channel check.      #
#                                                                        #
#--[ Config area ]-------------------------------------------------------#

ftp=/usr/bin/ftp
user=glftpd
pass=glftpd
host=localhost
port=changeme

nonoflags=""
max_ips="5"

passchk=/glftpd/bin/passchk
passwd=/glftpd/etc/passwd
usersdir=/glftpd/ftp-data/users

listonadd=TRUE
listondel=TRUE

teston=FALSE

log=/glftpd/ftp-data/logs/tur-addip.log


#--[ Script Start ]------------------------------------------------------#

## Procedure for showing help.
proc_help() {
  echo "Tur-Addip $VER Usage:"
  echo "NOTE: Everything is being logged. Abuse leads to deluser!"
  echo "!addip <username> <password> <function>"
  echo "Functions are: "
  echo "list          = List all your IPs"
  echo "add <IP>      = Adds an IP."
  echo "del <#>       = Dels an IP. Specify the IP or the number shown when running 'list'"
  echo "tag <tagline> = Changes tagline."
  exit 0
}

proc_log() {
  if [ "$log" ]; then
    echo `date "+%a %b %e %T %Y"`" : $@" >> $log
  fi
}

## Some general checks if everything can be execute and read.
if [ ! -x "$ftp" ]; then
  echo "Error. Can not execute ftp. Check path and perms."
  exit 0
elif [ ! -x "$passchk" ]; then
  echo "Error. passchk can not be executed. Check path and perms."
  exit 0
elif [ ! -d "$usersdir" ]; then
  echo "Error. Usersdir does not exist or arent a directory."
  exit 0
elif [ ! -r "$passwd" ]; then
  echo "Error. passwd can not be read. Check path and perms."
  exit 0
fi
if [ "$log" ]; then
  if [ ! -e "$log" ]; then
    echo "Log file; $log does not exist. Create it and set chmod 666 on it."
    exit 0
  elif [ ! -w "$log" ]; then
    echo "I cant write to $log. Set chmod 666 on it."
    exit 0
  fi
fi

## Checking if 3 arguments was used. Show the help otherwise.
if [ -z "$1" -o -z "$2" -o -z "$3" ]; then
  proc_help
fi

## Put all arguments into other arguments.
USERNAME="$1"
PASSWORD="$2"
ACTION="$3"
ACTION="`echo "$ACTION" | tr '[:upper:]' '[:lower:]'`"
CURIP="$4"
ALLARGS="$* " ## Used for proc_tag.

## Check if the specified user exists.
if [ ! -e "$usersdir/$USERNAME" ]; then
  echo "User $USERNAME does not exist."
  exit 0
else
  if [ "$nonoflags" ]; then
    for badflag in $nonoflags; do
      if [ "`grep "^FLAGS " "$usersdir/$USERNAME" | cut -d ' ' -f2 | grep "$badflag"`" ]; then
        echo "You have flag $badflag and cant use the functions of this script."
        exit 0
      fi
    done
  fi

  if [ "$max_ips" ] && [ "$ACTION" = "add" ]; then
    ips="0"
    for each in `grep "^IP " "$usersdir/$USERNAME" | cut -d ' ' -f1`; do
      ips=$[$ips+1]
    done
    if [ "$ips" -ge "$max_ips" ]; then
      echo "You have $ips IPs added. You need to delete some to get below max limit of $max_ips."
      exit 0
    fi
  fi

fi

## Check if the password matches.
if [ "`$passchk $USERNAME $PASSWORD $passwd`" != "MATCH" ]; then
  echo "Password not accepted for user $USERNAME"
  exit 0
fi

## Procedure for listing IPs
proc_list() {
  echo "Current IPs added to $USERNAME"
  for USERIP in `
    echo -e "user $user $pass\nsite user $USERNAME" | $ftp -vn $host $port | grep "IP[0-9]:" | tr -s ' ' | cut -d ' ' -f3- | tr -d '|'
  `; do
    USERIP="`echo "$USERIP" | tr '^' ' '`"
    if [ "`echo "$USERIP" | grep "IP[0-9]\:"`" ]; then
      POS="$USERIP"
    else
      echo "$POS $USERIP"
      unset POS
      GOTONE="TRUE"
    fi
  done

  proc_log "$USERNAME checks list of added IPs"

  if [ -z "$GOTONE" ]; then
    echo "No IPs found..."
  fi
}

## Procedure for adding IPs
proc_add() {
  if [ -z "$CURIP" ]; then
    proc_help; exit 0
  elif [ -z "`echo "$CURIP" | grep "\@"`" ]; then
    echo "IP must be in ident@ip format."
    exit 0
  fi

  proc_log "$USERNAME tries to add an IP: $CURIP"

  RESULT="`echo -e "user $user $pass\nsite addip $USERNAME $CURIP" | $ftp -vn $host $port | grep -B1 "Command Successful." | grep -v "Command Successful." | cut -d ' ' -f2-`"

  if [ "$RESULT" ]; then
    echo "$RESULT"
  else
    echo "No result. Make sure the user specified as 'user' have addip permissions and that he can log in."
    exit 0
  fi

  if [ "$listonadd" = "TRUE" ]; then
    unset log
    proc_list
  fi
}

## Procedure for deleting IPs
proc_del() {
  if [ -z "$CURIP" ]; then
    proc_help; exit 0
  fi

  proc_log "$USERNAME tries to del an IP: $CURIP"

  RESULT="`echo -e "user $user $pass\nsite delip $USERNAME $CURIP" | $ftp -vn $host $port | grep -B1 "Done$" | grep -v "Done$" | cut -d ' ' -f2-`"
  
  if [ "$RESULT" ]; then
    echo "$RESULT"
  else
    echo "No result. Make sure the user specified as 'user' have delip permissions and that he can log in."
    exit 0
  fi

  if [ "$listondel" = "TRUE" ]; then
    unset log
    proc_list
  fi
}

## Procedure for changing tagline.
proc_tag() {
  TAGLINE="`echo "$ALLARGS" | cut -d ' ' -f4-`"
  if [ -z "$TAGLINE" ]; then
    proc_help; exit 0
  fi

  proc_log "$USERNAME tries to change tagline to: $TAGLINE"

  RESULT="`echo -e "user $user $pass\nsite change $USERNAME tagline $TAGLINE" | $ftp -vn $host $port | grep "Command Successful."`"

  if [ "$RESULT" ]; then
    RESULT="`echo "$RESULT" | cut -d ' ' -f2-`"
    echo "$RESULT"
    echo "Tagline changed to: $TAGLINE"
  else
    echo "No result. Make sure the user specified as 'user' have 'site change' permissions and that he can log in."
  fi
  exit 0
}

## Procedure for running the test.
proc_test() {
  if [ "$teston" != "TRUE" ]; then
    proc_help; exit 0
  fi

  proc_log "$USERNAME runs a test."
  echo "Testing that everything works as it should."
  echo "It should log in and show the userstats for $user"
  echo "Make sure that $user has access to '-usersothers', '-addip', '-delip' & 'site change'"
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
  echo "permissions to list other users, add ips, del ips and 'site change'"
}

## Main menu.
case $ACTION in
  [lL][iI][sS][tT]) proc_list; exit 0;;
  [aA][dD][dD])     proc_add;  exit 0;;
  [dD][eE][lL])     proc_del;  exit 0;;
  [tT][aA][gG])     proc_tag;  exit 0;;
  [tT][eE][sS][tT]) proc_test; exit 0;;
  *)                proc_help; exit 0;;
esac

echo "How did I get here? bug."
exit 0
