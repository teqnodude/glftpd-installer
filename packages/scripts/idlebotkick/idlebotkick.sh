#!/bin/bash
VER=2.3.1
#------------------------------------------------------------#
# IdleBotKick - Kick Idlers or a specific User               #
#------------------------------------------------------------#
# A script for kicking all idlers, or a specific user.       #
# This is done from irc, usally by @ only.                   #
#                                                            #
# Running this with !kick only (default trigger) will kick   #
# everyone in the state of Idle. A verify time can be        #
# specified so that it verifies that they are still idle.    #
# You may also do !kick <username> and it will kick only     #
# that user from site (no verify time).                      #
#                                                            #
#--[ Thanks ]------------------------------------------------#
#                                                            #
# 2.0 decoy- for suggesting verify timer/skipping killbin.   #
#     zio/psxc for helping me with getting ncftp to work.    #
# 2.1 _qarf for suggesting GEXCLUDE ( exclude on groups ).   #
# 2.2 Me, for adding GROUPDIRS support ! heh.                #
# 2.3 Now uses ftp instead of ncftpls. No other changes.     #
#     tur-ftpwho no longer included in this package. Get the #
#     seperate tur-ftpwho ckage from my site instead.        #
# 2.3.1 Removed -v from two executions of the ftp binary as  #
#       that apparently ment Verbose (oops).                 #
#                                                            #
#--[ Installation ]------------------------------------------#
# Copy idlebotkick.sh to /glftpd/bin                         #
# Chmod it to 755                                            #
# Copy idlebotkick.tcl to your bots "config" folder.         #
# Edit idlebotkick.tcl to see some short instructions.       #
# Add idlebotkick.tcl to your bots config file and rehash it.#
#  The tcl is set to only allow this to ops by default.      #
#                                                            #
# This script uses tur-ftpwho to list idlers etc.            #
# Its a seperate package also available from www.grandis.nu  #
# Install that one first and make sure it works.             #
#                                                            #
# It uses the default 'ftp' binary.                          #
#                                                            #
# Some notes about some settings.                            #
# VERIFYTIME is the time between finding a idle user and     #
# verifying that he is still idle. This is a delay in the    #
# script and the problem is that it halts the bot during     #
# this time. So.. Dont set this too high. 4-15 seconds       #
# should be fine.                                            #
#                                                            #
# 'kickuser=' is the user that will log in and do 'site kill'"
# This user must have access to this command. By default, he #
# must have flag E for 'site kill/swho'. <- MAKE SURE !      #
# You should give him flag 4 as well, so he can log in even  #
# if site is full.                                           #
#                                                            #
# If you use "localhost" in host and run into problems,      #
# try with 127.0.0.1 instead. One report of localhost not    #
# working.                                                   #
#                                                            #
# If you set TESTON="TRUE" below, you may run:               #
# ./idlebotkick.sh test                                      #
# from shell to test your settings.                          #
#                                                            #
# Now then. Change the settings below.                       #
#                                                            #
#-[ Settings ]-----------------------------------------------#

WHOBIN=/glftpd/bin/tur-ftpwho  # Full path to tur-ftpwho
USERDIR=/glftpd/ftp-data/users # Path to users
SHOWKICKS="TRUE"               # Show who we kick, etc? 
                               # TRUE/FALSE

EXCLUDE="glftpd"   # Excluded users, space delimited.

GEXCLUDE="Admin"      # Excluded groups, space delimited.

## Dont kick users if they are in any of these dirs.
GROUPDIRS="
/site/PRE
"

VERIFYTIME="10"                # Time to delay for verify.

ftp="/usr/bin/ncftpls"             # Path to the ftp binary.
kickuser="glftpd"              # User that will log in to kick.
pass="glftpd"                  # Password for above user.
host="127.0.0.1"               # Host to connect to.
port="changeme"                      # Port to connect to.

TESTON="FALSE"                  # Allows running ./idlebotkick.sh test
                               # to display if it works or not.

BOLD=""                      # Dont change this one :)

## Some text for you to edit, if you have SHOWKICKS on TRUE.
## Start and stop bold with $BOLD

# Idlers kick (no argument given).
SHOWHEAD="Kicking idle user(s) $BOLD"
SHOWFOOT="$BOLD, byyye!"
SHOWNOIDLERS="No idlers online, leech later"

# User kick (argument given).
USERKICK="Username:$BOLD $1$BOLD Has Been Ejected."
NOUSERKICK="Username:$BOLD $1$BOLD was not found online."
USEREXCLUDED="$BOLD$1$BOLD Nope Cant kick them - well could be they'll kick me back and they hurt"


#################################################
# No changes below here                         #
#################################################

if [ -z "$EXCLUDE" ]; then
  EXCLUDE="R3j3jr3l3r"
fi

proc_test() {
  echo "Testing that everything works as it should."
  echo "It should log in and do a site user $kickuser."
  echo "Running: echo -e \"user $kickuser $pass\nsite user $kickuser\" | $ftp -vn $host $port"

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
  echo -e "user $kickuser $pass\nsite user $kickuser" | $ftp -vn $host $port
  echo ""
  echo "If you see the userfile for $kickuser above, its all good."
  echo "Also make sure he has access to 'site kill' and has flag 4."
}

if [ "$1" = "test" ] && [ "$TESTON" = "TRUE" ]; then
  proc_test
  exit 0
fi

if [ ! -e $ftp ]; then
  echo "Cant find $ftp."
  exit 1
fi

if [ -z "$1" ]; then
  SEXCLUDE="$( echo "$EXCLUDE" | tr -s ' ' '|' )"
  for rawdata in `$WHOBIN | grep -w "Idle:" | sed -e 's/-NEW-/NotLoggedIn/' | egrep -v "$SEXCLUDE" | tr -d ' '`; do
    unset EXCLUDEDBYGROUP
    user="$( echo $rawdata | cut -d '^' -f1 )"
    dir="$( echo $rawdata | cut -d '^' -f4 )"
    unset EXCLUDEDBYGROUP

    ## Check group exclude
    for egroup in $GEXCLUDE; do
      if [ "$( grep -x "GROUP $egroup" $USERDIR/$user )" ]; then
        EXCLUDEDBYGROUP="TRUE"
      fi
    done
  
    ## Check groupdir exclude
    if [ "$dir" ]; then
      for groupdir in $GROUPDIRS; do
        if [ "$( echo "$dir" | grep -F "$groupdir" )" ]; then
          EXCLUDEDBYGROUP="TRUE"
        fi
      done
    fi

    if [ "$EXCLUDEDBYGROUP" != "TRUE" ]; then
      upid="$( echo $rawdata | cut -d '^' -f2 )"
      if [ -z "$VERIFYTIME" ]; then
        if [ -z "$USERS" ]; then
          USERS="$user"
          KUSERS="$user"
        else
          USERS="$USERS $user"
          KUSERS="$USERS|$user"
        fi
        if [ -z "$PIDS" ]; then
          PIDS="$upid"
        else
          PIDS="$PIDS $upid"
        fi
      else
        if [ -z "$KUSERS" ]; then
          KUSERS="$user"
        else
          KUSERS="$KUSERS|$user"
        fi
      fi
    fi
  done

  if [ "$VERIFYTIME" != "" -a "$KUSERS" != "" ]; then
    if [ "$SHOWKICKS" = "TRUE" ]; then
      NUSERS="$( echo "$KUSERS" | tr -s '|' ' ' )"
      echo "Kept an eye on $BOLD$NUSERS$BOLD for the past $VERIFYTIME seconds."
      FOUND="TRUE"
    fi
    sleep $VERIFYTIME

    for rawdata in `$WHOBIN | grep -w "Idle:" | sed -e 's/-NEW-/NotLoggedIn/' | egrep "$KUSERS" | egrep -v "$SEXCLUDE" | tr -d ' '`; do
      user="$( echo $rawdata | cut -d '^' -f1 )"
      upid="$( echo $rawdata | cut -d '^' -f2 )"
      if [ -z "$USERS" ]; then
        USERS="$user"
      else
        USERS="$USERS $user"
      fi
      if [ -z "$PIDS" ]; then
        PIDS="$upid"
      else
        PIDS="$PIDS $upid"
      fi
    done   
  fi

  if [ "$SHOWKICKS" = "TRUE" ]; then
    if [ -z "$USERS" ]; then
      if [ "$FOUND" = "TRUE" ]; then
        echo "No users idling anymore."
      else
        echo "$SHOWNOIDLERS"
      fi
    else
      echo "$SHOWHEAD$USERS$SHOWFOOT"
    fi
  fi

  if [ "$PIDS" ]; then
    for pid in $PIDS; do
      echo -e "user $kickuser ${pass}\nsite kill $pid" | $ftp -n $host $port
    done
  fi
fi

## A user was specified.
if [ "$1" ]; then
  SEXCLUDE="$( echo $EXCLUDE | tr -s ' ' '|' )"

  ## Check on group
  for egroup in $GEXCLUDE; do
    if [ "$( grep "GROUP $egroup" $USERDIR/$1 )" ]; then
      echo "$USEREXCLUDED"
      exit 0
    fi
  done

  CHECKEXCLUDE="$( echo "$EXCLUDE" | grep -w $1 )"
  if [ "$CHECKEXCLUDE" ]; then
    echo "$USEREXCLUDED"
    exit 0
  fi
  for rawdata in `$WHOBIN | grep -w -- "$1" | tr -d ' '`; do
    user="$( echo $rawdata | cut -d '^' -f1 )"
    upid="$( echo $rawdata | cut -d '^' -f2 )"
    if [ -z "$PIDS" ]; then
      PIDS="$upid"
    else
      PIDS="$PIDS $upid"
    fi
  done
  if [ "$SHOWKICKS" = "TRUE" ]; then
    if [ -z "$PIDS" ]; then
      echo "$NOUSERKICK"
    else
      echo "$USERKICK"
    fi
  fi
  if [ "$PIDS" ]; then
    for pid in $PIDS; do
      echo -e "user $kickuser $pass\nsite kill $pid" | $ftp -n $host $port
    done
  fi
fi


