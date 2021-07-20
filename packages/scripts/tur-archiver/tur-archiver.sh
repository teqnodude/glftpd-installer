#!/bin/bash
VER=2.5

#--[ Intro ]--------------------------------------------------------#
#                                                                   #
# Tur-Archiver 2.x is a total rewrite from 1.x. It can copy, move   #
# or make symlinks from whatever you want, to wherever you want.    #
#                                                                   #
# It is NOT a spacemaker and shouldnt be used as such.              #
#                                                                   #
# Its more ment as a "sorter" of some kind. You specify WHERE it    #
# should look, WHAT it should look for and WHERE you want to put it.#
# By putting it, I mean either copy, move or make a symlink to it.  #
#                                                                   #
#--[ Installation ]-------------------------------------------------#
#                                                                   #
# Copy tur-archiver.sh to /glftpd/bin and chmod it to 700 or so.    #
#                                                                   #
# The included file_date binary is only needed if you wish to set a #
# time, in minutes, before this script touches it. If so, either    #
# copy the binary to /glftpd/bin or compile the source:             #
# gcc -o /glftpd/bin/file_date file_date.c                          #
#                                                                   #
#--[ Settings ]-----------------------------------------------------#
#                                                                   #
# GLROOT     = Simple the root of your glftpd dir.                  #
#              This is automatically added to the front of each     #
#              source and destination dir you soon choose.          #
#                                                                   #
# SITEROOT   = Path to 'site', from $GLROOT. /site is usually ok.   #
#                                                                   #
# today      = Incase you wish to use this in dated dirs, this will #
#              automatically set $today to todays dated dir (MMDD). #
#              The we can use $today in MOVE below.                 #
#                                                                   #
# MOVE       = Ahh, the heart of it all.                            #
#              Format is:                                           #
#              Where_To_Look:What_To_Look_For:Where_To_Put_It       #
#                                                                   #
#              Where_To_Look is the source section, relative to     #
#              $GLROOT$SITEROOT, which it will look for stuff in.   #
#              If you must use a space here, use [space] instead.   #
#                                                                  -#
#              If you are working with dated dirs (for example) it  #
#              might be a bit tedious to add:                       #
#              /0DAY/0203                                           #
#              /0DAY/0204 etc.                                      #
#              Instead, you can specify /0DAY~DEEP here.            #
#              It will then go into every subdir, part from those   #
#              in EXCLUDE= (below) and process each dir as if you   #
#              had set them up the slow way.                        #
#                                                                   #
#              What_To_Look_For is a standard egrep query. That     #
#              means you should know something about basic egrep to #
#              use it at best. For instance GROUPS means it will    #
#              match the word GROUPS anywhere in the release.       #
#                                                                   #
#              ^GROUPS means the dir must START with GROUPS.        #
#              GROUPS$ means the dir must END with GROUPS.          #
#              ^GROUPS$ means the dir must be named exactly GROUPS. #
#                                                                   #
#              Any odd chars must be escaped. For instance a .      #
#              would mean "anything" whereas \. means a real dot.   #
#                                                                   #
#              Do NOT use spaces in this one. If you must, use "\ " #
#              (ie, escape the space).                              #
#                                                                   #
#              If you want to search for - . OR _  do [\_-\.]       #
#              For instance [\_-\.]internal[\_-\.]                  #
#                                                                   #
#              Seperate different querys with a | sign.             #
#                                                                   #
#              Where_To_Put_It is where to put the resulting dir.   #
#              If you must use a space here, use [space] instead.   #
#                                                                   #
#              EXAMPLE: /0DAY~DEEP:^The\.|\-BP$:/Links              #
#              Go into every subdir of /0DAY, looking for stuff     #
#              that STARTS with "The." and stuff that ENDS with -BP #
#              and put the results in /Links (/glftpd/site/Links).  #
#                                                                   #
# CASE_SENSITIVE= TRUE/FALSE. Do you want the What_To_Look_For to   #
#                 be case sensitive or not? (egrep -i)              #
#                                                                   #
# WHAT_TO_DO = What would you like to do in the destination dir?    #
#              S = Make a symlink.                                  #
#              C = Copy the release here.                           #
#              M = Move the release here.                           #
#                                                                   #
# EXCLUDE    = This too is a default egrep line, case sensitive.    #
#              Anything matched here will be totally ignored        #
#              even if it matches a hit.                            #
#                                                                   #
# MINUTES_OLD= How old, in minutes, must the release be before we   #
#              do anything to it?   Set to "" to move instantly.    #
#              (setting it to 0 will also, but script will run      #
#              faster if you set it to "" since it wont even check) #
#                                                                   #
# CHECK_FOR  = Anything that must be in the dir before we move it.  #
#                                                                   #
#              By default, its "\ COMPLETE\ \)\ \-"                 #
#              which translates to " COMPLETE ) -"                  #
#              That happens to be the default line for a complete   #
#              release with zipscript-c.                            #
#                                                                   #
#              If the release has multiple CD's, each CDx dir must  #
#              contain this (We'll only check CD1 -> CD9)           #
#                                                                   #
#              This is also an egrep search, case sensitive, so if  #
#              you want to add other stuff that should also make    #
#              the release ok to move just add it here, | seperated #
#                                                                   #
#              Set to "" to disable or put a # infront of it.       #
#                                                                   #
# TULS       = This is only valid if WHAT_TO_DO is set to M for     #
#              move. It will grab the date on the release before    #
#              moving it and after the move, touch the dir to that  #
#              date so it keeps the same time on it.                #
#              Not everyone needs this as some mv binaries saves    #
#              the time automatically.                              #
#                                                                   #
#              To use this function, you'll need a binary called    #
#              tuls. Its available at www.grandis.nu/glftpd as well.#
#              Read the info in for compile instructions, etc.      #
#                                                                   #
#              Your touch binary also needs to support -d for       #
#              specifying which date to touch it with.              #
#                                                                   #
#              Leave this empty to disable that function.           #
#                                                                   #
# NO_SFV_OK  = TRUE/FALSE. With FALSE, it will just check CHECK_FOR #
#              and if it exists, its ok to move it (if its old      #
#              enough), but some releases would never get moved.    #
#              Specifically, DIRFIX etc, which has no .sfv and does #
#              not have a complete dir.                             #
#                                                                   #
#              With TRUE, it will check that there really is a sfv  #
#              in the dir. If there is a sfv and CHECK_FOR is not   #
#              found, its NOT ok to move yet (not completed).       #
#                                                                   #
#              In short, if no sfv exists, its ok to move it anyway #
#              as long as its old enough in MINUTES_OLD.            #
#                                                                   #
# HOW_TO_SYMLINK = This is how it will run if WHAT_TO_DO is S.      #
# HOW_TO_MOVE    = This is how it will run if WHAT_TO_DO is M.      #
# HOW_TO_COPY    = This is how it will run if WHAT_TO_DO is C.      #
#                                                                   #
# SYMLINK_CLEAR  = TRUE/FALSE. This is only valid if WHAT_TO_DO is  #
#                  set to S.                                        #
#                  If this is TRUE, it will delete every            #
#                  Where_To_Put_It dir before it starts and then    #
#                  recreate them with 755 permissions.              #
#                  Its to make sure there are no "dead" symlinks.   #
#                  Be careful with this, as it will rm -f any dir   #
#                  you set as destination for the symlinks.         #
#                                                                   #
#                  If you dont want 755 perms, search for -m755     #
#                  below and change it to whatever you want.        #
#                                                                   #
# REVERSED_SYMLINK= TRUE/FALSE.                                     #
#                   This is ONLY if you want to move releases. In   #
#                   other words, if WHAT_TO_DO is M.                #
#                   Setting this to TRUE will move the release as   #
#                   usual but then make a symlink in its original   #
#                   location.                                       #
#                                                                   #
#                   The symlink will be created using               #
#                   HOW_TO_SYMLINK, set above.                      #
#                                                                   #
#                   These symlinks will not be cleared and          #
#                   SYMLINK_CLEAR has no function here.             #
#                                                                   #
# FILE_DATE  = Incase MINUTES_OLD is set, we use the included       #
#              file_date binary to check its age. Here you specify  #
#              it location.                                         #
#              We could use tuls for this as well, but I'm too lazy #
#                                                                   #
# DATE_BIN   = Incase MINUTES_OLD is set, we need a GNU compliant   #
#              date binary that supports the -d option.             #
#              Most users can leave it at just "date".              #
#              FBSD users will want to download sh-utils. It will   #
#              install a binary called gdate which you must specify #
#              here.                                                #
#                                                                   #
# DEBUG      = TRUE/FALSE. Just a precation. You must set this to   #
#              FALSE for it to actually do anything. With it on     #
#              TRUE, its the same as if you used the 'debug' arg.   #
#                                                                   #
#--[ Running it ]---------------------------------------------------#
#                                                                   #
# Running it with the argument 'debug' (without the '') will not do #
# anything except show you what it WOULD have done. I recomend you  #
# use this everytime you make a change in any part.                 #
#                                                                   #
# Running it without args will make a live run. Shouldnt output     #
# anything then. If DEBUG=TRUE, it will still not do anything !     #
#                                                                   #
#--[ Changelog ]----------------------------------------------------#
#                                                                   #
# 2.5   : When checking how old a release is, it simply did not     
#         work. Now, since nobody has complained about this and its 
#         been a long time since 2.4, I'm not sure if this applies  
#         to everyone.                                              
#         In either case;                                           
#         REL_DATE="`$DATE_BIN -d "$($FILE_DATE $releasename)" +%s`"
#         was changed to:                                           
#         REL_DATE="`$DATE_BIN -d "$($FILE_DATE $FROM_DIR/$releasename)" +%s`"
#         so if the new version does not work for you when checking 
#         the age of releases, change it back to what it was =)     
#                                                                   
# 2.4   : The path in MOVE now support ~DEEP to enter each subdir   #
#         of the defined dir.                                       #
#                                                                   #
# 2.3   : Added TULS=. Read up on it above.                         #
#                                                                   #
#         Fixed a cosmetic "integer expression expected" if the     #
#         release is 0 seconds old.                                 #
#                                                                   #
# 2.2   : Added REVERSED_SYMLINK function. This will make a symlink #
#         in the original location of the release if WHAT_TO_DO is  #
#         set to move stuff.                                        #
#         Idea by LPC.                                              #
#                                                                   #
#         Changed ROOT=/glftpd/site to GLROOT=/glftpd               #
#         Changed SYM_ROOT=/site to SITEROOT=/site                  #
#         Above changes was made to more easely create symlinks.    #
#                                                                   #
# 2.1   : Added NO_SFV_OK. Check explanation above.                 #
#                                                                   #
#         Fixed a problem if the release was less then 60 seconds   #
#         old. It would get moved even if MINUTES_OLD was set.      #
#                                                                   #
#         Big thanks to DaShizNit for ideas and testing the 2.+     #
#         versions.                                                 #
#                                                                   #
# 2.0   : Total rewrite of the 1.x series. Can do a lot more now.   #
#                                                                   #
#--[ Contact ]------------------------------------------------------#
#                                                                   #
# http://www.grandis.nu/glftpd <-> http://grandis.mine.nu/glftpd    #
#                                                                   #
#--[ Configuration ]------------------------------------------------#

GLROOT=/glftpd
SITEROOT=/site

today="`date +%m%d`"

MOVE="
/0DAYS~DEEP:^The\.|\-BP$:/Links/TheAndBP
/DIVX:GERMAN|FRENCH:/Links/Foreign_Rels
"

CASE_SENSITIVE=FALSE

WHAT_TO_DO=c

EXCLUDE="^lost\+found$|^GROUPS$|^\_PRE$"

MINUTES_OLD=200

CHECK_FOR="\ COMPLETE\ \)\ \-"

NO_SFV_OK=TRUE

## Advanced options.

TULS=/glftpd/bin/tuls

HOW_TO_SYMLINK="ln -f -s"
HOW_TO_MOVE="rsync -rtuog --remove-source-files"
HOW_TO_COPY="cp -f"

SYMLINK_CLEAR=FALSE

REVERSED_SYMLINK=FALSE

FILE_DATE=/glftpd/bin/file_date
DATE_BIN=date

DEBUG=TRUE


#--[ Script Start ]-------------------------------------------------#

## Set DEBUG=TRUE if first argument is debug or DEBUG
if [ "$1" = "debug" -o "$1" = "DEBUG" ]; then
  DEBUG="TRUE"
fi

## Set how we want to egrep.
if [ "$CASE_SENSITIVE" = "TRUE" ]; then
  EGREP="egrep"
else
  EGREP="egrep -i"
fi

proc_debug() {
  if [ "$DEBUG" = "TRUE" ]; then
    echo "$*"
  fi
}

## Move, copy or make symlinks. Heres where its done.
proc_copy() {

  if [ "$DATED" = "TRUE" ]; then
    SOURCE_DIR="$FROM_DIR_DEEP"
    SOURCE_DIRSYM="$FROM_DIRSYM_DEEP"
  else
    SOURCE_DIR="$FROM_DIR"
    SOURCE_DIRSYM="$FROM_DIRSYM"
  fi

  if [ "$DEBUG" = "TRUE" ]; then
    echo "$HOW_TO_COPY \"$SOURCE_DIR/$releasename\" \"$TO_DIR\""
    echo ""
  else
    $HOW_TO_COPY "$SOURCE_DIR/$releasename" "$TO_DIR"
  fi
}

proc_move() {
  unset reldate

  if [ "$TULS" ]; then
    if [ ! -x "$TULS" ]; then
      echo "Warning. Cant execute $TULS. Check perms."
      echo "Leave the TULS= option empty to disable or fix so tuls is executable."
      exit 1
    else    
      reldate="`$TULS | grep "\:\:\:\:$releasename\:\:\:\:" | head -n1 | cut -d ':' -f17- | cut -d '^' -f3,2,5,4 | tr '^' ' '`" 
    fi
  fi

  if [ "$DATED" = "TRUE" ]; then
    SOURCE_DIR="$FROM_DIR_DEEP"
    SOURCE_DIRSYM="$FROM_DIRSYM_DEEP"
  else
    SOURCE_DIR="$FROM_DIR"
    SOURCE_DIRSYM="$FROM_DIRSYM"
  fi

  if [ "$DEBUG" = "TRUE" ]; then
    echo "$HOW_TO_MOVE \"$SOURCE_DIR/$releasename\" \"$TO_DIR\""
    if [ "$REVERSED_SYMLINK" != "TRUE" -a -z "$reldate" ]; then
      echo ""
    fi
  else
    $HOW_TO_MOVE "$SOURCE_DIR/$releasename" "$TO_DIR"
    rm -rf "$SOURCE_DIR/$releasename"
    chmod 777 "$TO_DIR/$releasename"
  fi

  ## Make a symlink it the original location, if enabled.
  if [ "$REVERSED_SYMLINK" = "TRUE" ]; then
    if [ "$DEBUG" = "TRUE" ]; then
      echo "$HOW_TO_SYMLINK \"$TO_DIRSYM/$releasename\" \"$SOURCE_DIR/$releasename\""
      if [ -z "$reldate" ]; then
        echo ""
      fi
    else
      $HOW_TO_SYMLINK "$TO_DIRSYM/$releasename" "$SOURCE_DIR/$releasename"
    fi
  fi
 
  if [ "$reldate" ]; then
    if [ "$DEBUG" = "TRUE" ]; then
      echo "touch -d \"$reldate\" \"$TO_DIR/$releasename\""
      echo ""
    else
      touch -d "$reldate" "$TO_DIR/$releasename"
    fi
  fi
}

proc_symlink() {

  if [ "$DATED" = "TRUE" ]; then
    SOURCE_DIR="$FROM_DIR_DEEP"
    SOURCE_DIRSYM="$FROM_DIRSYM_DEEP"
  else
    SOURCE_DIR="$FROM_DIR"
    SOURCE_DIRSYM="$FROM_DIRSYM"
  fi

  if [ "$DEBUG" = "TRUE" ]; then
    echo "$HOW_TO_SYMLINK \"$SOURCE_DIRSYM/$releasename\" \"$TO_DIR/$releasename\""
    echo ""
  else
    $HOW_TO_SYMLINK "$SOURCE_DIRSYM/$releasename" "$TO_DIR/$releasename"
  fi
}

## Procedure for checking if the release is old enough.
proc_checkold() {
  if [ "$MINUTES_OLD" ] && [ "$SKIP" != "YES" ]; then
    REL_DATE="`$DATE_BIN -d "$($FILE_DATE $FROM_DIR/$releasename)" +%s`"
    if [ -z "$REL_DATE" ]; then
      SKIP=YES
      proc_debug "Skipping move of $releasename - Seems to be from right now or in the future... or $FILE_DATE dosnt work."
    else
      REL_SEC_OLD="`echo "$NOW_DATE - $REL_DATE" | bc -l | cut -d '.' -f1`"
      if [ -z "$REL_SEC_OLD" ]; then
        REL_SEC_OLD="0"
      fi
      REL_MIN_OLD="`echo "$REL_SEC_OLD / 60" | bc -l | cut -d '.' -f1`"
      if [ -z "$REL_MIN_OLD" ]; then
        REL_MIN_OLD="0"
      fi
      proc_debug "$releasename seems to be $REL_MIN_OLD minutes old."
      if [ "$REL_MIN_OLD" -lt "$MINUTES_OLD" ]; then
        SKIP=YES
        proc_debug "Skipping move of $releasename - Only $REL_MIN_OLD minutes old."
      fi
    fi
  fi
}

## Procedure for checking for other stuff in the release to OK it.
proc_checkfor() {
  if [ "$CHECK_FOR" ] && [ "$SKIP" != "YES" ]; then

    ## Multiple CD's ?
    if [ "`ls -1 $releasename | grep "^[cC][dD][1-9]$"`" ]; then

      for each_cd in `ls -1 $releasename | grep "^[cC][dD][1-9]$"`; do
        if [ -z "`ls -1 $releasename/$each_cd | egrep "$CHECK_FOR"`" ]; then
          if [ "$NO_SFV_OK" = "TRUE" ]; then
            if [ "`ls -1 $releasename/$each_cd | grep "\.[sS][fF][vV]$"`" ]; then
              proc_debug "Skipping $releasename - $each_cd does not seem complete and a sfv exists."
              SKIP=YES
              break
            else
              proc_debug "OK on $releasename/$each_cd - $each_cd does not seem complete and no sfv exists."
            fi
          else
            proc_debug "Skipping $releasename - $each_cd does not seem completed."
            SKIP=YES
            break
          fi
        fi
      done

    ## Single CD release.
    else
      if [ -z "`ls -1 $releasename | egrep "$CHECK_FOR"`" ]; then
        if [ "$NO_SFV_OK" = "TRUE" ]; then
          if [ "`ls -1 $releasename | grep "\.[sS][fF][vV]$"`" ]; then
            proc_debug "Skipping $releasename - Does not seem complete and a sfv exists."
            SKIP=YES
          else
            proc_debug "OK on $releasename - does not seem complete and no sfv exists."
          fi
        else
          proc_debug "Skipping $releasename - Does not seem complete."
          SKIP=YES
        fi
      fi
    fi
  fi
}

if [ "$MINUTES_OLD" ]; then
  NOW_DATE="`$DATE_BIN +%s`"
  if [ ! -x "$FILE_DATE" ]; then
    echo "Error. MINUTES_OLD is defined but cant find/execute file_date from $FILE_DATE"
    exit 1
  fi
fi

## If we use symlinks and SYMLINK_CLEAR is TRUE, delete all TO_DIRs and recreate
if [ "$WHAT_TO_DO" = "S" ] && [ "$SYMLINK_CLEAR" = "TRUE" ]; then
  for rawdata in $MOVE; do
    TO_DIR="$ROOT`echo "$rawdata" | cut -d ':' -f3 | sed -e 's/\[space\]/ /g'`"
    if [ "$TO_DIR" != "$LAST_TO_DIR" ]; then
      if [ -d "$TO_DIR" ]; then
        if [ "$DEBUG" = "TRUE" ]; then
          echo "Deleting and recreating $TO_DIR"
        else
          rm -rf "$TO_DIR"
          mkdir -m755 "$TO_DIR"
        fi
      fi
    fi
    LAST_TO_DIR="$TO_DIR"
  done
fi  

## Go. Main loop.
for rawdata in $MOVE; do
  unset SKIP; unset DATED
  FROM_DIR="$GLROOT$SITEROOT`echo "$rawdata" | cut -d ':' -f1 | sed -e 's/\[space\]/ /g'`"
  FROM_DIRSYM="$SITEROOT`echo "$rawdata" | cut -d ':' -f1 | sed -e 's/\[space\]/ /g'`"

  GRAB_WHAT="`echo "$rawdata" | cut -d ':' -f2`"

  if [ "`echo "$FROM_DIR" | grep "~"`" ]; then
    DATED="TRUE"
    FROM_DIR="`echo "$FROM_DIR" | cut -d '~' -f1`"
    FROM_DIRSYM="`echo "$FROM_DIRSYM" | cut -d '~' -f1`"
  fi

  TO_DIR="$GLROOT$SITEROOT`echo "$rawdata" | cut -d ':' -f3 | sed -e 's/\[space\]/ /g'`"
  TO_DIRSYM="$SITEROOT`echo "$rawdata" | cut -d ':' -f3 | sed -e 's/\[space\]/ /g'`"

  if [ ! -d "$FROM_DIR" ]; then
    echo "Error. \"$FROM_DIR\" does not exist."
    SKIP=YES
  fi
  if [ ! -d "$TO_DIR" ]; then
    echo "Error. \"$TO_DIR\" does not exist."
    SKIP=YES
  fi

  if [ "$SKIP" != "YES" ]; then
    proc_debug ""
    if [ "$DATED" != "TRUE" ]; then
      proc_debug "Entering $FROM_DIR - Looking for \"$GRAB_WHAT\""
    fi

    cd "$FROM_DIR"

    if [ "$DATED" = "TRUE" ]; then
      for subsection in `ls -1 | egrep -v "$EXCLUDE" | tr ' ' '^'`; do
        cd "$FROM_DIR"
        cd "$subsection"

        FROM_DIR_DEEP="$FROM_DIR/$subsection"
        FROM_DIRSYM_DEEP="$FROM_DIRSYM/$subsection"

        proc_debug "Entering (DEEP) $FROM_DIR/$subsection - Looking for \"$GRAB_WHAT\""
        for releasename in `ls -1 | $EGREP "$GRAB_WHAT" | egrep -v "$EXCLUDE" | tr ' ' '^'`; do
          unset SKIP
          releasename="`echo "$releasename" | tr '^' ' '`"

          proc_checkold
          proc_checkfor

          if [ "$SKIP" != "YES" ]; then
            case $WHAT_TO_DO in
              [mM]) proc_move;;
              [cC]) proc_copy;;
              [sS]) proc_symlink;;
            esac
          fi
        done
      done
    else
      for releasename in `ls -1 | $EGREP "$GRAB_WHAT" | egrep -v "$EXCLUDE" | tr ' ' '^'`; do
        unset SKIP
        releasename="`echo "$releasename" | tr '^' ' '`"

        proc_checkold
        proc_checkfor

        if [ "$SKIP" != "YES" ]; then
          case $WHAT_TO_DO in
            [mM]) proc_move;;
            [cC]) proc_copy;;
            [sS]) proc_symlink;;
          esac
        fi
      done
    fi
  fi

done

proc_debug""
proc_debug "All done."

exit 0