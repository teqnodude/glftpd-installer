#!/bin/bash
VER=1.8.2
###########################################################################################
# Change the settings in tur-autonuke.conf.                                               #
###########################################################################################

config=/glftpd/bin/tur-autonuke.conf


###########################################################################################
# Yadda Yadda, no changes below here, rip off balls etc etc.                              #
###########################################################################################


if [ -e "$config" ]; then
  . $config
else
  echo "Can not find config file $config, defined in tur-autonuke.sh"
  exit 0
fi

## Check date for the logfile.
DATENOW="$(date +%D" - "%T)"

if [ -e "$TEMPDIR/tur-autonuke.lock" ]; then
  if [ "`find \"$TEMPDIR/tur-autonuke.lock\" -type f -mmin -60`" ]; then
    if [ "$1" = "test" ]; then
      echo "Tur-Autonuke already running? Remove $TEMPDIR/tur-autonuke.lock if its not."
      echo "Lockfile will be automatically removed once it is 60 minutes old (it is not, yet)."
    fi
    exit 0
  else
    if [ "$1" = "test" ]; then
      echo "$TEMPDIR/tur-autonuke.lock exists but its older then 60 minutes. Continuing."
    fi
    rm -f $TEMPDIR/tur-autonuke.lock
  fi    
fi

if [ "$FORCENUKESYNTAX" = "" ]; then
  ## Nuked dir syntax. Dont want to nuke those again.
  # Old one: NUKES="$( grep nukedir_style $GLCONF | egrep -iv '#' | cut -f2-2 | awk -F"%" -F"-" '{print $1}' )"
  NUKES="$( grep nukedir_style $GLCONF | egrep -iv '#' | awk -F" " '{print $2}'  | awk -F"%" -F"-" '{print $1}' )"
else
  NUKES="$FORCENUKESYNTAX"
fi

if [ -z "$NUKES" ]; then
  if [ "$1" = "test" ]; then
    echo "WARNING: I could not decide what your nukedir_syntax is.. set FORCENUKESYNTAX to"
    echo "NUKED or something else I can use to decide if a folder is nuked."
    exit 1
  else
    if [ "$LOG" != "" ]; then
      echo "$DATENOW WARNING: I could not decide what your nukedir_syntax is.. set FORCENUKESYNTAX to NUKED or something else I can use to decide if a folder is nuked." >> $LOG
    fi
  fi
fi

if [ ! -e $LOG ]; then
  touch $LOG
  chmod 666 $LOG
fi

if [ "$SHWING" = "TRUE" ]; then
  echo "Read the instructions before running this!"
  exit 1
fi

if [ "$PRENUKEEMPTY" = "TRUE" -o "$PRENUKEINCOM" = "TRUE" -o "$PRENUKEHALFEMPTY" = "TRUE" -o "$BANNEDWORDS" = "TRUE" ]; then
  if [ -e "$GLLOG" ]; then
    foundit=yes
  else
    echo "You have early pre-nuke warnings enabled, but $GLLOG was not found."
    echo "Either fix GLLOG or set all pre-nuke warnings to FALSE."
    exit 1
  fi
fi

## How long is $GLROOT so we can cut it out when we need to nuke?
CUT="$( echo $GLROOT | wc -c )"

if [ "$CUT" -lt "2" ]; then
  echo "You havent set a GLROOT? Dooo sooo."
  exit 1
fi

if [ "$MATCHUSER" = "TRUE" ]; then
  if [ ! -e $GLLOG ]; then
    echo "You have MATCHUSER on TRUE, but I cant find the $GLLOG (GLLOG) file. Fix it."
    exit 1
  fi
fi

## Verify that nuked line dosnt contain [](){}. If it does, set it to NUKED. No biggie anyway.
if [ "`echo "$NUKES" | egrep '\[|\]|\(|\)|\{|\}'`" ]; then
  if [ "$1" = "test" ]; then
    echo "Warning. NUKES contains bad char ( $NUKES ). Setting it to NUKED (dont worry)"
  fi
  NUKES="NUKED"
fi

for dirs in $DIRS; do
  if [ -e $GLROOT$dirs ]; then
    ok=yes  
  else
    if [ "$1" = "test" ]; then
      echo ""
      echo "WARNING:"
      echo "I can not find $GLROOT$dirs - I'll just skip that one."
      echo "Check the DIRS= settings."
    fi
    if [ "$LOG" != "" ]; then
      echo "$DATENOW Error: Can not find $dirs specified in DIRS. Skipping it." >> $LOG
    fi       
  fi
done

if [ "$CLEANHOURS" != "" ]; then
  CLEANMINUTES="$( expr "$CLEANHOURS" \* "60" )"
fi
if [ "$CLEANBANHOURS" != "" ]; then
  CLEANBANMINUTES="$( expr "$CLEANBANHOURS" \* "60" )"
fi

if [ "$TIMETODELEM" != "" ]; then
  TIMETODELEM="$( expr "$TIMETODELEM" \* "60" )"
else
  if [ "$DELETENUKES" = "TRUE" ]; then
    if [ "$1" = "test" ]; then
      echo "Error: You have DELETENUKES on TRUE, but no time specified in TIMETODELEM."
      echo "Setting DELETENUKES to FALSE."
      DELETENUKES="FALSE"
    else
      echo "$DATENOW Error: You have DELETENUKES on TRUE, but no time specified in TIMETODELEM." >> $LOG
    fi
  fi
fi

if [ "$LOCKFILE" = "TRUE" ]; then
  touch $TEMPDIR/tur-autonuke.lock
fi

if [ "$1" = "test" ]; then
  echo "Welcome to Tur-AutoNuke version $VER"
fi

if [ "$1" = "test" ]; then
  if [ "$FORCENUKESYNTAX" ]; then
    echo "NUKES is set to: $NUKES by FORCENUKESYNTAX"
  else
    echo "NUKES is set to: $NUKES"
  fi
  echo "EXCLUDES are: >$EXCLUDES<"
  if [ "$INCOMPLETE" = "TRUE" ]; then
    echo "Symlinks are set to >$SYMLINKNAMES<"
  fi
fi

if [ "$AFFILSDIRS" ]; then
  for folder in `echo $AFFILSDIRS`; do
    if [ ! -d "$folder" ]; then
      echo "Error. $folder defined in AFFILSDIRS does not exist. Skipping."
    else
      cd $folder
      for affils in `ls`; do
        GAFFILS="\-$affils$ $GAFFILS"
      done
      ## Clean up GAFFILS from any frelled spaces.
      if [ "$GAFFILS" ]; then
        GAFFILS=`echo $GAFFILS | tr -s ' '`
      fi
    fi
  done
  if [ "$GAFFILS" ]; then
    if [ "$EXCLUDES" ]; then
      EXCLUDES="$EXCLUDES|$GAFFILS"
    else
      EXCLUDES="$GAFFILS"
    fi
    if [ "$1" = "test" ]; then
      echo "The following words added to EXCLUDES: $GAFFILS"
    fi
  fi
fi


####################################################################################
## Totally empty folders check                                                     #
####################################################################################

if [ "$TOTALLYEMPTY" = "TRUE" ]; then
  
  ETIME=""
  NTIME=""
  if [ "$EMPTYHOURS" = "TRUE" ]; then
    EARLYEMPTYD="$( expr $EARLYEMPTY \/ 60 )"
    if [ "$EARLYEMPTYD" -gt "1" ]; then
      ETIME="hours"
    else
      ETIME="hour"
    fi
    TIMEEMPTYD="$( expr $TIMEEMPTY \/ 60 )" 
    if [ "$TIMEEMPTYD" -gt "1" ]; then
      NTIME="hours"
    else
      NTIME="hour"
    fi
    ETIME="$EARLYEMPTYD $ETIME"
    NTIME="$TIMEEMPTYD $NTIME"
  else
    EARLYEMPTYD="$EARLYEMPTY"
    if [ "$EARLYEMPTYD" -gt "1" ]; then
      ETIME="minutes"
    else
      ETIME="minute"
    fi
    TIMEEMPTYD="$TIMEEMPTY" 
    if [ "$TIMEEMPTYD" -gt "1" ]; then
      NTIME="minutes"
    else
      NTIME="minute"
    fi
    ETIME="$EARLYEMPTYD $ETIME"
    NTIME="$TIMEEMPTYD $NTIME"
  fi

  ## Make a | between excluded folders.
  EXCLUDESPECIAL="$( echo $EXCLUDES | tr -s ' ' '|' )"
  ## Add the nuked syntax to it too.
  EXCLUDESPECIAL="$EXCLUDESPECIAL|$NUKES"

  if [ "$1" = "test" ]; then
    echo ""
    echo "-[ Checking empty folders. Warn: $ETIME - Nuke: $NTIME ]-"
    echo "Excludes here are: >$EXCLUDESPECIAL<"
    echo " "
  fi

  for folders in $DIRS; do
    if [ -e "$GLROOT$folders" ]; then
      cd $GLROOT$folders
    
      if [ "$1" = "test" ]; then
        echo "--Entering $folders"
      fi

      for found in `find $GLROOT$folders -maxdepth 1 -mindepth 1 -empty -type d -mmin +$TIMEEMPTY -print | egrep -vi "$EXCLUDESPECIAL" | cut -b$CUT- | grep -v 'lost+found'`; do
        ALLOW="$( find $GLROOT$found -type d -maxdepth 1 -print | grep -i $ALLOWED )"
        if [ "$ALLOW" = "" ]; then
          if [ "$1" = "test" ]; then
            echo "Folder: $folders  Other: $found  Empty more then $NTIME. Nuking it (test)."
          fi
          FOUNDEMPTYNUKE="$folders"
          if [ "$USESPACES" = "TRUE" ]; then
            found="{$found}"
          fi
          if [ "$1" != "test" ]; then
            CORE="$($NUKEPROG -r $GLCONF -N $NUKEUSER -n $found $EMPTYMULTIPLIER -Auto- Empty for more than $NTIME.)"
            echo "$DATENOW Nuke: $found - Empty after $NTIME. $EMPTYMULTIPLIER Nuke." >> $LOG
            ## Nuke Detail
            if [ "$EMBARRESEMPTY" = "TRUE" ]; then
              CORECHECK="$( echo $CORE | cut -b-5 )"
              if [ "$CORECHECK" = "Empty" ]; then
                CORE="$( echo $CORE | cut -b90- )"
              else 
                CORE="$( echo $CORE | cut -b205- )"
              fi
              CORE="$( echo $CORE | tr -s '-' ' ' )"
              unset gotuser
              for each in $CORE; do
                if [ "$next" = "yes" ]; then
                  if [ "$USEREXCLUDE" != "$each" ]; then
                    users="$users \002(\002$each"
                    uexcluded="no"
                    gotuser="true"
                  else
                    uexcluded="yes"
                  fi
                fi
                if [ "$each" = "Nukee:" ]; then
                  next="yes" 
                else 
                  next="no"
                fi
                if [ "$next2" = "yes" ]; then
                  if [ "$uexcluded" = "no" ]; then
                    users="$users lost \037$each\037\002)\002"
                  fi
                fi
                if [ "$each" = "Lost:" ]; then
                  next2="yes" 
                else 
                  next2="no"
                fi
              done
              if [ "$gotuser" = "true" ]; then
                sleep 1
                echo `date "+%a %b %e %T %Y"` ANUKEL: \"$users\" >> $GLLOG
                sleep 2
              fi
              unset users
            fi
          else       
            echo "String: $NUKEPROG -r $GLCONF -N $NUKEUSER -n $found $EMPTYMULTIPLIER -Auto- Empty for more than $NTIME."
          fi
        else
          if [ "$1" = "test" ]; then
            echo "$found is empty after $NTIME, but it has been allowed."
          fi
        fi
      done
      ## Early Pre-Nuke warning
      if [ "$PRENUKEEMPTY" = "TRUE" ]; then
        for found in `find $GLROOT$folders -maxdepth 1 -mindepth 1 -empty -type d -mmin +$EARLYEMPTY -print | egrep -vi "$EXCLUDESPECIAL" | cut -b$CUT- | grep -v 'lost+found'`; do


          ALLOW="$( find $GLROOT$found -maxdepth 1 -print -type d | grep -i $ALLOWED )"
          if [ -z "$ALLOW" ]; then
            if [ "$FOUNDEMPTYNUKE" != "$folders" ]; then
              REALEMPTYTMP="$( echo $found | tr -s '/' ' ' )"
              for o in $REALEMPTYTMP; do
                REALEMPTY="$o"
              done
              BANPROCESS="TRUE"
              if [ "$MATCHUSER" = "TRUE" ]; then
                ## Find owner of dir
                unset uname
                unset unames
                for unames in `cat $GLLOG | grep -w $folders/$REALEMPTY'"' | grep -w NEWDIR: | awk -F" " '{print $8}' | tr -d '"'`; do
                  uname="$unames"
                done
                if [ "$uname" = "" ]; then
                  uname="$NOUSERFOUND"
                else
                  uname="$uname"
                fi
              fi
              ## Find out parent folder of the nuke.
              lastfolder="$( echo $folders | tr -s '/' ' ' )" 
              for lastfolders in $lastfolder; do
                lastfolder="$lastfolders"
              done
              if [ "$1" = "test" ]; then
                if [ -e "$TEMPDIR/prewarned.$REALEMPTY" ]; then
                  echo "$lastfolder/$REALEMPTY$uname empty more then $ETIME. Already sent Pre-warning though (test)."
                  echo "  -Remove $TEMPDIR/prewarned.$REALEMPTY to send again."
                else
                  echo "$lastfolder/$REALEMPTY$uname empty more then $ETIME. Sending pre-nuke warning (test)."
                  echo "Prewarning" > $TEMPDIR/prewarned.$REALEMPTY
                fi
              fi
              if [ "$1" != "test" ]; then
                if [ -e "$TEMPDIR/prewarned.$REALEMPTY" ]; then
                  BANPROCESS="TRUE"
                else
                  echo `date "+%a %b %e %T %Y"` ANUKEEMPTY: \"$lastfolder/$REALEMPTY\" \"$uname\" \"$ETIME\" \"$NTIME\" >> $GLLOG
                  echo "$DATENOW Warn: $found$uname, Pre-nuke warning (empty) sent. More then $ETIME old." >> $LOG
                  echo "Prewarning" > $TEMPDIR/prewarned.$REALEMPTY
                fi
              fi
            fi
            unset FOUNDEMPTYNUKE
            unset lastfolder
          else
            if [ "$1" = "test" ]; then
              echo "$found is empty after $ETIME, but it has been allowed."
            fi
          fi
        done
      fi
    fi
  done
fi


####################################################################################
## Half empty module                                                               #
####################################################################################

if [ "$HALFEMPTY" = "TRUE" ]; then

  ETIME=""
  NTIME=""
  if [ "$HALFHOURS" = "TRUE" ]; then
    EARLYHALFEMPTYD="$( expr $EARLYHALFEMPTY \/ 60 )"
    if [ "$EARLYHALFEMPTYD" -gt "1" ]; then
      ETIME="hours"
    else
      ETIME="hour"
    fi
    TIMEHALFEMPTYD="$( expr $TIMEHALFEMPTY \/ 60 )" 
    if [ "$TIMEHALFEMPTYD" -gt "1" ]; then
      NTIME="hours"
    else
      NTIME="hour"
    fi
    ETIME="$EARLYHALFEMPTYD $ETIME"
    NTIME="$TIMEHALFEMPTYD $NTIME"
  else
    EARLYHALFEMPTYD="$EARLYHALFEMPTY"
    if [ "$EARLYHALFEMPTYD" -gt "1" ]; then
      ETIME="minutes"
    else
      ETIME="minute"
    fi
    TIMEHALFEMPTYD="$TIMEHALFEMPTY" 
    if [ "$TIMEHALFEMPTYD" -gt "1" ]; then
      NTIME="minutes"
    else
      NTIME="minute"
    fi
    ETIME="$EARLYHALFEMPTYD $ETIME"
    NTIME="$TIMEHALFEMPTYD $NTIME"
  fi

  ## Make a | between excluded folders.
  EXCLUDESPECIAL="$( echo $EXCLUDES | tr -s ' ' '|' )"
  ## Add the nuked syntax to it too.
  EXCLUDESPECIAL="$EXCLUDESPECIAL|$NUKES"

  if [ "$1" = "test" ]; then
    echo ""
    echo "-[ Checking half-empty folders. Warn: $ETIME - Nuke: $NTIME ]-"
    echo "Excludes here are: >$EXCLUDESPECIAL<"
    echo " "
  fi

  ## Clean out index file if enough time has passed, unless disabled.
  if [ "$CLEANMINUTES" != "" ]; then
    if [ -e $TEMPDIR/tur-autonuke.time ]; then
      if [ -e $TEMPDIR/tur-autonuke.index ]; then
        for found in `find $TEMPDIR/tur-autonuke.time -maxdepth 0 -mmin +$CLEANMINUTES -print`; do
          if [ "$1" = "test" ]; then
            echo "Index file more then $CLEANHOURS hours old. Making a new one."
          fi
          echo "$DATENOW CLEAN: $TEMPDIR/tur-autonuke.index more then $CLEANHOURS hours old. Cleaning it." >> $LOG
          mv -f $TEMPDIR/tur-autonuke.index $TEMPDIR/tur-autonuke.oldindex
          echo "This file shouldnt contain anything" > $TEMPDIR/tur-autonuke.time
          touch $TEMPDIR/tur-autonuke.time
        done
      fi
    else
      touch $TEMPDIR/tur-autonuke.time
      echo "This file shouldnt contain anything" > $TEMPDIR/tur-autonuke.time
    fi
  fi

  ## Lets rock the folders. See what we can find...
  for folders in $DIRS; do
    if [ -e $GLROOT$folders ]; then
      cd $GLROOT$folders

      if [ "$1" = "test" ]; then
        echo "--Entering $folders"
      fi
 
      for them in `ls | egrep -v '\[' | egrep -v '\(' | egrep -iv $EXCLUDESPECIAL | grep -v 'lost+found'`; do
        #echo "Checking $them"
         
        if [ -e $TEMPDIR/tur-autonuke.index ]; then
          INDEX="$( cat $TEMPDIR/tur-autonuke.index | grep -w $folders/$them )"
        else
          echo "$DATENOW INDEX: No index file found. Building a new one..." >> $LOG
          if [ "$1" = "test" ]; then
            echo "Since this seems to be the first time you run the half-empty module"
            echo "or the index file has just been cleaned, I will now build the" 
            echo "index file to speed it up next time its run."
            echo "I will also check for half-empty folders while I'm at it."
            echo "This can take a while..."
            echo ""
          fi
        fi
        if [ -z "$INDEX" ]; then
          GOTTHROUGH="TRUE"
          for content in `ls -LR $them`; do
            if [ "$GOTFILE" != "TRUE" ]; then
              for excludes in $EMPTYEXCLUDE; do
                if [ "$GOTFILE" != "TRUE" ]; then
                  if [ "$ALREADYFOUND" != "TRUE" ]; then
                    VERIFY="$( echo $content | grep -i $excludes )"
                    #echo "$them - echoing $content and grepping $excludes"
                    if [ "$VERIFY" ]; then
                      #echo "VERIFY: $VERIFY found from $them"
                      ALREADYFOUND="TRUE"
                      echo "$folders/$them" >> $TEMPDIR/tur-autonuke.index
                      GOTFILE="TRUE"
                    fi
                  fi
                fi
              done
            fi
          done
        fi
        if [ "$GOTFILE" != "TRUE" ]; then
          if [ "$GOTTHROUGH" = "TRUE" ]; then
            for found in `find $GLROOT$folders/$them -maxdepth 0 -type d -mmin +$TIMEHALFEMPTY  -print | grep -vi "$NUKES" | cut -b$CUT- | grep -v 'lost+found'`; do
              ALLOW="$( find $GLROOT$folders/$them -maxdepth 1 -type d -print | grep -i $ALLOWED )"
              if [ -z "$ALLOW" ]; then
                if [ "$USESPACES" = "TRUE" ]; then
                  release="{$folders/$them}"
                else
                  release="$folders/$them"
                fi

                if [ "$1" = "test" ]; then
                  echo "$folders/$them seems empty and is older then $NTIME. Nuking! (test)"
                  echo "String: $NUKEPROG -r $GLCONF -N $NUKEUSER -n $release $HALFEMPTYMULTIPLIER -Auto- Empty for more then $NTIME"
                else
                  CORE="$( $NUKEPROG -r $GLCONF -N $NUKEUSER -n $release $HALFEMPTYMULTIPLIER -Auto- Empty for more then $NTIME )"
                  echo "$DATENOW Nuke: $folders/$them - Half-empty after $NTIME. $HALFEMPTYMULTIPLIER Nuke." >> $LOG
                  ## Nuke Detail
                  if [ "$EMBARRESHALF" = "TRUE" ]; then
                    CORECHECK="$( echo $CORE | cut -b-5 )"
                    if [ "$CORECHECK" = "Empty" ]; then
                      CORE="$( echo $CORE | cut -b90- )"
                    else 
                      CORE="$( echo $CORE | cut -b205- )"
                    fi
                    CORE="$( echo $CORE | tr -s '-' ' ' )"
                    unset gotuser
                    for each in $CORE; do
                      if [ "$next" = "yes" ]; then
                        if [ "$USEREXCLUDE" != "$each" ]; then
                          users="$users \002(\002$each"
                          uexcluded="no"
                          gotuser="true"
                        else
                          uexcluded="yes"
                        fi
                      fi
                      if [ "$each" = "Nukee:" ]; then
                        next="yes" 
                      else 
                        next="no"
                      fi
                      if [ "$next2" = "yes" ]; then
                        if [ "$uexcluded" = "no" ]; then
                          users="$users lost \037$each\037\002)\002"
                        fi
                      fi
                      if [ "$each" = "Lost:" ]; then
                        next2="yes" 
                      else 
                        next2="no"
                      fi
                    done
                    if [ "$gotuser" = "true" ]; then
                      sleep 1
                      echo `date "+%a %b %e %T %Y"` ANUKEL: \"$users\" >> $GLLOG
                      sleep 2
                    fi
                    unset users
                  fi
                fi
                HALFEMPTY="TRUE"
              else
                if [ "$1" = "test" ]; then
                  echo "$found is empty after $NTIME, but it has been allowed."
                fi
              fi
            done
            if [ "$HALFEMPTY" != "TRUE" ]; then
              for found in `find $GLROOT$folders/$them -maxdepth 0 -type d -mmin +$EARLYHALFEMPTY -print | grep -vi "$NUKES" | cut -b$CUT- | grep -v 'lost+found'`; do
                ALLOW="$( find $GLROOT$folders/$them -maxdepth 1 -type d -print | grep -i $ALLOWED )"
                if [ -z "$ALLOW" ]; then
                  if [ "$MATCHUSER" = "TRUE" ]; then
                    ## Find owner of dir
                    uname=""
                    unames=""
                    for unames in `cat $GLLOG | grep -w $folders/$them'"' | grep -w NEWDIR: | awk -F" " '{print $8}' | tr -d '"'`; do
                      uname="$unames"
                    done
                    if [ -z "$uname" ]; then
                      uname="$NOUSERFOUND"
                    else
                      uname="$uname"
                    fi
                  fi
                  ## Find out parent folder of the nuke.
                  lastfolder="$( echo $folders | tr -s '/' ' ' )" 
                  for lastfolders in $lastfolder; do
                    lastfolder="$lastfolders"
                  done
                  if [ -e "$TEMPDIR/prewarned.$them" ]; then
                    if [ "$1" = "test" ]; then
                      if [ "$REALEMPTY" != "$them" ]; then
                        echo "$folders/$them$uname seems empty after $ETIME. Pre nuke warning already sent (test)"
                      fi
                    fi
                  else
                    if [ "$1" = "test" ]; then
                      if [ "$PRENUKEHALFEMPTY" = "TRUE" ]; then
                        if [ "$REALEMPTY" != "$them" ]; then
                          echo "$folders/$them$uname seems empty after $ETIME. Sending pre-nuke warning (test)"
                        fi
                      fi
                      echo "Tur-autonuke prewarning file" > $TEMPDIR/prewarned.$them
                    else
                      if [ "$PRENUKEHALFEMPTY" = "TRUE" ]; then
                        echo `date "+%a %b %e %T %Y"` ANUKEHEMPTY: \"$lastfolder/$them\" \"$uname\" \"$ETIME\" \"$NTIME\" >> $GLLOG
                        echo "$DATENOW Warn: $folders/$them$uname, Half-empty after $ETIME. Pre-nuke warning sent." >> $LOG
                        echo "Tur-autonuke prewarning file" > $TEMPDIR/prewarned.$them
                      fi
                    fi
                  fi
                  unset lastfolder
                else
                  if [ "$1" = "test" ]; then
                    echo "$found is empty after $ETIME, but it has been allowed."
                    echo "$folders/$them" >> $TEMPDIR/tur-autonuke.index
                  fi
                fi
              done
            fi
            unset HALFEMPTY
            BANPROCESS="TRUE"
          else
            CORE="YES"
            #echo "$them already checked"
          fi
        fi
        unset GOTTHROUGH
        unset them
        unset HALFEMPTY
        GOTFILE="FALSE"
        ALREADYFOUND="FALSE"

      done
    fi
    unset them
  done
fi


############################################################################
# Checking incompleted releases by symlink.                                #
############################################################################

if [ "$INCOMPLETE" = "TRUE" ]; then
  unset REALNAME
  unset ETIME
  unset NTIME

  if [ "$INCOMHOURS" = "TRUE" ]; then
    EARLYINCOMD="$( expr $EARLYINCOM \/ 60 )"
    if [ "$EARLYINCOMD" -gt "1" ]; then
      ETIME="hours"
    else
      ETIME="hour"
    fi
    TIMEINCOMD="$( expr $TIMEINCOM \/ 60 )" 
    if [ "$TIMEINCOMD" -gt "1" ]; then
      NTIME="hours"
    else
      NTIME="hour"
    fi
    ETIME="$EARLYINCOMD $ETIME"
    NTIME="$TIMEINCOMD $NTIME"
  else
    EARLYINCOMD="$EARLYINCOM"
    if [ "$EARLYINCOMD" -gt "1" ]; then
      ETIME="minutes"
    else
      ETIME="minute"
    fi
    TIMEINCOMD="$TIMEINCOM" 
    if [ "$TIMEINCOMD" -gt "1" ]; then
      NTIME="minutes"
    else
      NTIME="minute"
    fi
    ETIME="$EARLYINCOMD $ETIME"
    NTIME="$TIMEINCOMD $NTIME"
  fi

  if [ "$1" = "test" ]; then
    echo ""
    echo "-[ Checking incompletes. Warn: $ETIME - Nuke: $NTIME ]-"
  fi

  for folders in $DIRS; do
    if [ -e $GLROOT$folders ]; then
      cd $GLROOT$folders

      if [ "$1" = "test" ]; then
        echo "--Entering $folders"
      fi
      LIST="$( $LSM )"

      for dirs in $LIST; do
        for SYMLINKNAME in $SYMLINKNAMES; do
          VERIFY="$( echo $dirs | grep -F -- "$SYMLINKNAME" )"
          if [ "$VERIFY" ]; then
            VERIFY="$( echo $VERIFY | tr -d ',' )"
            if [ "$1" = "test" ]; then
              echo "Found incomplete link: $VERIFY"
            fi
            CHECK="$( ls -l $GLROOT$folders | grep -F $VERIFY )"

            CHECK="$( echo $CHECK | awk -F ">" '{print $2}' | tr -s '/' ' ' )"
            for crap in $CHECK; do
              LASTCRAP="$REALNAME"
              REALNAME="$crap"
            done
            for jump in $JUMPON; do
              if [ "$( echo "$jump" | grep -wi "$REALNAME" )" ]; then
                REALNAME="$LASTCRAP"
              fi
            done

            if [ -e "$REALNAME" ]; then
              for folder in `find $GLROOT$folders/$REALNAME -maxdepth 1 -type d -mmin +$TIMEINCOM -print | grep -vi "$NUKES" | cut -b$CUT-`; do

                if [ "$REALNAME" != "$LAST" ]; then
                  ALLOW="$( find $GLROOT$folders/$REALNAME -maxdepth 1 -type d -print | grep -i $ALLOWED )"
                  if [ "$ALLOW" = "" ]; then
                    EXCLUDE="NO"
                    for excludes in $EXCLUDES; do
                      VERIFY2="$( echo $REALNAME | grep -i $excludes )"
                      if [ "$VERIFY2" ]; then
                        EXCLUDE="YES"
                      fi
                    done

                    if [ "$EXCLUDE" != "YES" ]; then
                      if [ "$1" = "test" ]; then
                        echo "$REALNAME is older then $NTIME. Nuking it (test)."
                      fi

                      if [ "$CLEANMESSAGE" = "TRUE" ]; then
                        if [ -e $GLROOT/$folders/.message ]; then
                          if [ "$1" = "test" ]; then
                            CHECKMESSAGE="$( cat $GLROOT/$folders/.message | grep -w $REALNAME )"
                            echo "Removing release from .message (test, line follows below:)"
                            echo "$CHECKMESSAGE"
                          else
                            cat $GLROOT/$folders/.message | grep -v "$REALNAME" > $TEMPDIR/message.tmp
                            mv -f $TEMPDIR/message.tmp $GLROOT/$folders/.message
                            #echo "Actually removed it from .message"
                          fi
                        else
                          if [ "$1" = "test" ]; then
                            echo "CLEANMESSAGE is TRUE, but no .message found in $GLROOT/$folders."
                          fi
                        fi
                      fi
                
                      if [ "$1" != "test" ]; then
                        if [ "$USESPACES" = "TRUE" ]; then
                          release="{$folders/$REALNAME}"
                        else
                          release="$folders/$REALNAME"
                        fi
                        CORE="$( $NUKEPROG -r $GLCONF -N $NUKEUSER -n $release $INCOMMULTIPLIER -Auto- Not completed for $NTIME. )"
                        echo "$DATENOW Nuke: $folders/$REALNAME - Incomplete after $NTIME. $INCOMMULTIPLIER Nuke." >> $LOG
                        JUSTNUKED="$REALNAME"
                        ## Nuke Detail
                        if [ "$EMBARRESINCOM" = "TRUE" ]; then
                          CORECHECK="$( echo $CORE | cut -b-5 )"
                          if [ "$CORECHECK" = "Empty" ]; then
                            CORE="$( echo $CORE | cut -b90- )"
                          else 
                            CORE="$( echo $CORE | cut -b205- )"
                          fi
                          CORE="$( echo $CORE | tr -s '-' ' ' )"
                          unset gotuser
                          for each in $CORE; do
                            if [ "$next" = "yes" ]; then
                              if [ "$USEREXCLUDE" != "$each" ]; then
                                users="$users \002(\002$each"
                                uexcluded="no"
                                gotuser="true"
                              else
                                uexcluded="yes"
                              fi
                            fi
                            if [ "$each" = "Nukee:" ]; then
                              next="yes" 
                            else 
                              next="no"
                            fi
                            if [ "$next2" = "yes" ]; then
                              if [ "$uexcluded" = "no" ]; then
                                users="$users lost \037$each\037\002)\002"
                              fi
                            fi
                            if [ "$each" = "Lost:" ]; then
                              next2="yes" 
                            else 
                              next2="no"
                            fi
                          done
                          if [ "$gotuser" = "true" ]; then
                            sleep 1
                            echo `date "+%a %b %e %T %Y"` ANUKEL: \"$users\" >> $GLLOG
                            sleep 2
                          fi
                          users=""
                        fi
                      else
                        if [ "$USESPACES" = "TRUE" ]; then
                          release="{$folders/$REALNAME}"
                        else
                          release="$folders/$REALNAME"
                        fi
                        echo "String: $NUKEPROG -r $GLCONF -N $NUKEUSER -n $release $INCOMMULTIPLIER -Auto- Not completed for $NTIME."
                      fi
                      LAST="$REALNAME"
                    else
                      if [ "$1" = "test" ]; then
                        if [ "$SAIDIT" != "$REALNAME" ]; then
                          #echo "$REALNAME is excluded"
                          SAIDIT="$REALNAME"
                        fi
                      fi
                    fi
                    if [ "$CLEANSYMLINKS" = "TRUE" ]; then
                      if [ "$CLEANMESSAGE" = "TRUE" ]; then
                        if [ -e $GLROOT/$folders/.message ]; then
                          if [ "$1" = "test" ]; then
                            CHECKMESSAGE="$( cat $GLROOT/$folders/.message | grep -w $REALNAME )"
                            echo "Removing release from .message (test, line follows below:)"
                            echo "$CHECKMESSAGE"
                          else
                            cat $GLROOT/$folders/.message | grep -v "$REALNAME" > $TEMPDIR/message.tmp
                            mv -f $TEMPDIR/message.tmp $GLROOT/$folders/.message
                          fi
                        else
                          if [ "$1" = "test" ]; then
                            echo "CLEANMESSAGE is TRUE, but no .message found in $GLROOT/$folders."
                          fi
                        fi
                      fi
                      if [ "$1" != "test" ]; then
                        rm -rf $VERIFY
                        echo "$DATENOW Dele: Removing symlink $VERIFY" >> $LOG
                      else
                        if [ "$SAIDIT2" != "$REALNAME" ]; then
                          echo "Removing symlink: $VERIFY (test)"
                          echo ""
                          SAIDIT2="$REALNAME"
                        fi
                      fi
                    fi
                  else
                    if [ "$1" = "test" ]; then
                      echo "$folders/$REALNAME is still incomplete after $NTIME, but it has been allowed."
                      LAST="$REALNAME"
                    fi
                  fi
                fi
              done
              if [ "$PRENUKEINCOM" = "TRUE" ]; then
                if [ "$JUSTNUKED" != "$REALNAME" ]; then
                  unset LAST
                  for folder in `find $GLROOT$folders/$REALNAME -maxdepth 1 -type d -mmin +$EARLYINCOM -print | grep -vi "$NUKES" | cut -b$CUT-`; do

                    if [ "$REALNAME" != "$LAST" ]; then
                      ALLOW="$( find $GLROOT$folders/$REALNAME -maxdepth 1 -type d -print | grep -i $ALLOWED )"
                      if [ "$ALLOW" = "" ]; then
                        if [ "$MATCHUSER" = "TRUE" ]; then
                          ## Find owner of dir
                          unset uname
                          unset unames
                          for unames in `cat $GLLOG | grep -w $folders/$REALNAME'"' | grep -w NEWDIR: | awk -F" " '{print $8}' | tr -d '"'`; do
                            uname="$unames"
                          done
                          if [ -z "$uname" ]; then
                            uname="$NOUSERFOUND"
                          else
                            uname="$uname"
                          fi
                        fi
                        ## Find out parent folder of the nuke.
                        lastfolder="$( echo $folders | tr -s '/' ' ' )" 
                        for lastfolders in $lastfolder; do
                          lastfolder="$lastfolders"
                        done
                        EXCLUDE="NO"
                        for excludes in $EXCLUDES; do
                          VERIFY2="$( echo $REALNAME | grep -i $excludes )"
                          if [ "$VERIFY2" ]; then
                            EXCLUDE="YES"
                          fi
                        done
  
                        if [ "$EXCLUDE" != "YES" ]; then
                          if [ "$1" = "test" ]; then
                            if [ -e "$TEMPDIR/prewarned.$REALNAME" ]; then
                              BANPROCESS="TRUE"
                              if [ "$SAIDIT4" != "$REALNAME" ]; then
                                echo "$REALNAME$uname is older then $ETIME. Pre warning already sent though. (test)"
                                echo "  -Remove $TEMPDIR/prewarned.$REALNAME to send again."
                                SAIDIT4="$REALNAME"
                              fi
                            else
                              PREWARNING="TRUE"
                              if [ "$SAIDIT3" != "$REALNAME" ]; then
                                echo "$REALNAME$uname is older then $ETIME. Pre-Nuke warning. (test)."
                                echo "$REALNAME" > $TEMPDIR/prewarned.$REALNAME
                                SAIDIT3="$REALNAME"
                                SAIDIT4="$REALNAME"
                              fi
                            fi
                          else
                            if [ "$GLLOG" != "" ]; then
                              if [ -e "$TEMPDIR/prewarned.$REALNAME" ]; then
                                BANPROCESS="TRUE"
                              else
                                BANPROCESS="TRUE"
                                if [ "$SAIDIT3" != "$REALNAME" ]; then
                                  echo `date "+%a %b %e %T %Y"` ANUKEINC: \"$lastfolder/$REALNAME\" \"$uname\" \"$ETIME\" \"$NTIME\" >> $GLLOG
                                  echo "$REALNAME" > $TEMPDIR/prewarned.$REALNAME
                                  if [ "$SAIDIT4" != "$REALNAME" ]; then
                                    echo "$DATENOW Warn: $lastfolder/$REALNAME$uname is older then $ETIME. Sending pre-nuke warning" >> $LOG
                                    SAIDIT3="$REALNAME"
                                    SAIDIT4="$REALNAME"
                                  fi
                                fi
                              fi
                            fi
                          fi
                        fi
                      else
                        if [ "$1" = "test" ]; then
                          echo "$folders/$REALNAME is incomplete after $ETIME, but it has been allowed."
                          LAST="$REALNAME"
                        fi
                      fi
                      unset lastfolder
                    fi
                  done
                fi
              fi
            else
              if [ "$1" = "test" ]; then
                echo "$REALNAME does NOT exist anymore"
              fi
              if [ "$CLEANSYMLINKS" = "TRUE" ]; then
                if [ "$1" = "test" ]; then
                  echo "Removing symlink to $VERIFY (test)"
                else
                  rm -rf $VERIFY
                  echo "$DATENOW Dele: Removing symlink $VERIFY" >> $LOG
                fi
              fi
            fi
          fi
          unset SAIDIT3
          unset SAIDIT4
          unset JUSTNUKED
          unset REALNAME
        done
      done
    fi
  done
fi


####################################################################################
## Banned words module                                                             #
####################################################################################

if [ "$BANNEDWORDS" = "TRUE" ]; then
  ## Make a | between excluded folders.
  EXCLUDESPECIAL="$( echo $EXCLUDES | tr -s ' ' '|' )"
  if [ "$BANEXCLUDE" != "" ]; then
    BANEXCLUDE="$( echo $BANEXCLUDE | tr -s ' ' '|' )"
    EXCLUDESPECIAL="$EXCLUDESPECIAL|$NUKES|$BANEXCLUDE"
  else
    EXCLUDESPECIAL="$EXCLUDESPECIAL|$NUKES"
  fi

  ETIME=""
  NTIME=""
  if [ "$BANHOURS" = "TRUE" ]; then
    EARLYBANPRENUKED="$( expr $EARLYBANPRENUKE \/ 60 )"
    if [ "$EARLYBANPRENUKED" -gt "1" ]; then
      ETIME="hours"
    else
      ETIME="hour"
    fi
    TIMEBANNUKED="$( expr $TIMEBANNUKE \/ 60 )" 
    if [ "$TIMEBANNUKED" -gt "1" ]; then
      NTIME="hours"
    else
      NTIME="hour"
    fi
    ETIME="$EARLYBANPRENUKED $ETIME"
    NTIME="$TIMEBANNUKED $NTIME"
  else
    EARLYBANPRENUKED="$EARLYBANPRENUKE"
    if [ "$EARLYBANPRENUKE" -gt "1" ]; then
      ETIME="minutes"
    else
      ETIME="minute"
    fi
    TIMEBANNUKED="$TIMEBANNUKE" 
    if [ "$TIMEBANNUKE" -gt "1" ]; then
      NTIME="minutes"
    else
      NTIME="minute"
    fi
    ETIME="$EARLYBANPRENUKE $ETIME"
    NTIME="$TIMEBANNUKE $NTIME"
  fi

  if [ "$1" = "test" ]; then
    echo ""
    echo "-[ Checking banned-words folders. Warn: $ETIME - Nuke: $NTIME ]-"
    echo "Excludes here are: >$EXCLUDESPECIAL<"
    echo " "
  fi

  if [ "$CLEANBANMINUTES" != "" ]; then
    if [ -e $TEMPDIR/tur-autonuke.ban.time ]; then
      if [ -e $TEMPDIR/tur-autonuke.ban.index ]; then
        for found in `find $TEMPDIR/tur-autonuke.ban.time -maxdepth 0 -mmin +$CLEANBANMINUTES -print`; do
          if [ "$1" = "test" ]; then
            echo "Index file more then $CLEANBANHOURS hours old. Making a new one."
          fi
          echo "$DATENOW CLEAN: tur-autonuke.ban.index more then $CLEANBANHOURS hours old. Cleaning it." >> $LOG
          mv -f $TEMPDIR/tur-autonuke.ban.index $TEMPDIR/tur-autonuke.ban.oldindex
          echo "This file shouldnt contain anything" > $TEMPDIR/tur-autonuke.ban.time
          touch $TEMPDIR/tur-autonuke.ban.time
        done
      fi
    else
      touch $TEMPDIR/tur-autonuke.ban.time
      echo "This file shouldnt contain anything" > $TEMPDIR/tur-autonuke.ban.time
    fi
  fi

  for stuff in $BANDIRS; do

    if [ ! -e $TEMPDIR/tur-autonuke.ban.index ]; then
      if [ "$1" = "test" ]; then
        echo "Creating new index file for Banned words to speed it up the next time."
        echo "This will take some time, but not as much as for the half-empty index."
        echo "Checking banned words on all releases while I am at it."
        echo "Please wait..."
      fi
      touch $TEMPDIR/tur-autonuke.ban.index
    fi

    folders="$( echo $stuff | awk -F"~" '{print $1}' )"
    BANWORD="$( echo $stuff | awk -F"~" '{print $2}' )"
    BANWORD="$( echo $BANWORD | tr -s ':' ' ' )"

    if [ "$1" = "test" ]; then
      echo "--Entering $folders. Banned words are $BANWORD"
    fi

    if [ -e $GLROOT$folders ]; then
      cd $GLROOT$folders

      for them in `ls | egrep -v '\[' | egrep -iv $EXCLUDESPECIAL`; do
        ## Check if release is already accepted in indexfile for banned words.
        INIT=""
        INIT="$( cat $TEMPDIR/tur-autonuke.ban.index | grep -w $GLROOT$folders/$them )"

        if [ -z "$INIT" ]; then
          BANFOUND="NO"
          for banword in $BANWORD; do
            unset MULTIPL
            MULTIPL="$( echo $banword | awk -F"*" '{print $2}' )"
            banword="$( echo $banword | awk -F"*" '{print $1}' )"

            if [ -z "$MULTIPL" ]; then
              MULTIPLIER="$BANMULTIPLIER"
            else
              MULTIPLIER="$MULTIPL"
            fi

            VERIFY="$( echo $them | grep -F -i -- "$banword" )"
            #echo "Checking if $banword is in $them"
            if [ "$VERIFY" ]; then
              BANFOUND="YES"
              #echo "$them contains a banned word!"
              for found in `find $GLROOT$folders/$them -maxdepth 0 -type d -mmin +$TIMEBANNUKE -print | grep -vi "$NUKES" | cut -b$CUT-`; do
                ALLOW="$( find $GLROOT$folders/$them -maxdepth 1 -type d -print | grep -i $ALLOWED )"
                if [ -z "$ALLOW" ]; then
                  BANPROCESS="TRUE"
                  if [ "$USESPACES" = "TRUE" ]; then
                    release="{$folders/$them}"
                  else
                    release="$folders/$them"
                  fi
                  if [ "$1" = "test" ]; then
                    echo "$them ($banword) is older then $NTIME. NUKE! (test)"
                    echo "String: $NUKEPROG -r $GLCONF -N $NUKEUSER -n $release $MULTIPLIER -Auto- $banword not allowed"
                    BANLAST="$them"
                  else
                    CORE="$( $NUKEPROG -r $GLCONF -N $NUKEUSER -n $release $MULTIPLIER -Auto- $banword not allowed )"
                    BANLAST="$them"
                    echo "$DATENOW Nuke: $folders/$them - Contains $banword after $NTIME. $MULTIPLIER Nuke." >> $LOG
                    ## Nuke Detail
                    if [ "$EMBARRESBAN" = "TRUE" ]; then
                      CORECHECK="$( echo $CORE | cut -b-5 )"
                      if [ "$CORECHECK" = "Empty" ]; then
                        CORE="$( echo $CORE | cut -b90- )"
                      else 
                        CORE="$( echo $CORE | cut -b205- )"
                      fi
                      CORE="$( echo $CORE | tr -s '-' ' ' )"
                      gotuser=""
                      for each in $CORE; do
                        if [ "$next" = "yes" ]; then
                          if [ "$USEREXCLUDE" != "$each" ]; then
                            users="$users \002(\002$each"
                            uexcluded="no"
                            gotuser="true"
                          else
                            uexcluded="yes"
                          fi
                        fi
                        if [ "$each" = "Nukee:" ]; then
                          next="yes" 
                        else 
                          next="no"
                        fi
                        if [ "$next2" = "yes" ]; then
                          if [ "$uexcluded" = "no" ]; then
                            users="$users lost \037$each\037\002)\002"
                          fi
                        fi
                        if [ "$each" = "Lost:" ]; then
                          next2="yes" 
                        else 
                          next2="no"
                        fi
                      done
                      if [ "$gotuser" = "true" ]; then
                        sleep 1
                        echo `date "+%a %b %e %T %Y"` ANUKEL: \"$users\" >> $GLLOG
                        sleep 2
                      fi
                      users=""
                    fi
                  fi
                else
                  if [ "$1" = "test" ]; then
                    echo "$them ($banword) is older then $NTIME, but it has been allowed."
                    echo "$GLROOT$folders/$them" >> $TEMPDIR/tur-autonuke.ban.index
                  fi
                  BANLAST="$them"
                fi
              done
              if [ "$BANLAST" != "$them" ]; then
                for found in `find $GLROOT$folders/$them -maxdepth 0 -type d -mmin +$EARLYBANPRENUKE -print | grep -vi "$NUKES" | cut -b$CUT-`; do
                  if [ "$MATCHUSER" = "TRUE" ]; then
                    ## Find owner of dir
                    uname=""
                    unames=""
                    for unames in `cat $GLLOG | grep -w $folders/$them'"' | grep -w NEWDIR: | awk -F" " '{print $8}' | tr -d '"'`; do
                      uname="$unames"
                    done
                    if [ "$uname" = "" ]; then
                      uname="$NOUSERFOUND"
                    else
                      uname="$uname"
                    fi
                  fi
                  ## Find out parent folder of the nuke.
                  lastfolder="$( echo $folders | tr -s '/' ' ' )" 
                  for lastfolders in $lastfolder; do
                    lastfolder="$lastfolders"
                  done
                  ALLOW="$( find $GLROOT$folders/$them -maxdepth 1 -type d -print | grep -i $ALLOWED )"
                  if [ -z "$ALLOW" ]; then
                    BANPROCESS="TRUE"
                    if [ "$1" = "test" ]; then
                      if [ -e $TEMPDIR/prewarned.$them ]; then
                        echo "$lastfolder/$them$uname ($banword) is older then $ETIME. Warning already sent. (test)"
                      else
                        echo "$them$uname ($banword) is older then $ETIME. Prenuke-warning (test)"
                        echo "Tur-autonuke prewarning file" > $TEMPDIR/prewarned.$them 
                        WROTE="TRUE"
                      fi
                    else
                      if [ ! -e $TEMPDIR/prewarned.$them ]; then
                        if [ "$BANPRENUKE" = "TRUE" ]; then
                          echo `date "+%a %b %e %T %Y"` ANUKEBAN: \"$lastfolder/$them\" \"$uname\" \"$banword\" \"$ETIME\" \"$NTIME\" >> $GLLOG
                          echo "Tur-autonuke prewarning file" > $TEMPDIR/prewarned.$them 
                          echo "$DATENOW Warn: $folders/$them$uname, Contains $banword after its $ETIME old. Pre-nuke warning sent." >> $LOG
                        fi
                      fi
                    fi
                  else
                    if [ "$1" = "test" ]; then
                      echo "Would be pre warning time for $GLROOT$folders/$them, but its been allowed."
                      echo "$GLROOT$folders/$them" >> $TEMPDIR/tur-autonuke.ban.index
                      WROTE="TRUE"
                    fi
                  fi
                done
              fi
              unset VERIFY
            fi
          done
          if [ "$BANFOUND" = "NO" ]; then
            if [ "$WROTE" != "TRUE" ]; then
              if [ "$them" != "$LAST" ]; then
                echo "$GLROOT$folders/$them" >> $TEMPDIR/tur-autonuke.ban.index
                LAST="$them"
              fi
            fi 
           WROTE="TRUE"
          fi
          WROTE="FALSE"
        fi
        BANFOUND="NO"
      done
    else
      if [ "$1" = "test" ]; then
        echo "I can not find $GLROOT$folders from the BANDIRS setting $stuff. Skipping it."
      fi
      if [ "$LOG" != "" ]; then
        echo "$folders from the bandir setting $stuff can not be found. Skipping it." >> $LOG
      fi
    fi
  done
fi


####################################################################################
## Allowed words module                                                            #
####################################################################################

unset stuff
ALLOW="NO"

MULTIPLIER="$ALLOWMULTIPLIER"

if [ "$ALLOWEDWORDS" = "TRUE" ]; then
  ## Make a | between excluded folders.
  EXCLUDESPECIAL="$( echo $EXCLUDES | tr -s ' ' '|' )"

  ETIME=""
  NTIME=""
  if [ "$ALLOWHOURS" = "TRUE" ]; then
    EARLYALLOWPRENUKED="$( expr $EARLYALLOWNUKE \/ 60 )"
    if [ "$EARLYALLOWPRENUKED" -gt "1" ]; then
      ETIME="hours"
    else
      ETIME="hour"
    fi
    TIMEALLOWNUKED="$( expr $TIMEALLOWNUKE \/ 60 )" 
    if [ "$TIMEALLOWNUKED" -gt "1" ]; then
      NTIME="hours"
    else
      NTIME="hour"
    fi
    ETIME="$EARLYALLOWPRENUKED $ETIME"
    NTIME="$TIMEALLOWNUKED $NTIME"
  else
    EARLYALLOWPRENUKED="$EARLYALLOWPRENUKE"
    if [ "$EARLYALLOWPRENUKE" -gt "1" ]; then
      ETIME="minutes"
    else
      ETIME="minute"
    fi
    TIMEALLOWNUKED="$TIMEALLOWNUKE" 
    if [ "$TIMEALLOWNUKE" -gt "1" ]; then
      NTIME="minutes"
    else
      NTIME="minute"
    fi
    ETIME="$EARLYALLOWPRENUKE $ETIME"
    NTIME="$TIMEALLOWNUKE $NTIME"
  fi

  if [ "$1" = "test" ]; then
    echo ""
    echo "-[ Checking allowed-words folders. Warn: $ETIME - Nuke: $NTIME ]-"
    echo "Excludes here are: >$EXCLUDESPECIAL<"
    echo " "
  fi

  for stuff in $ALLOWDIRS; do
    folders="$( echo $stuff | awk -F"~" '{print $1}' )"
    ALLOWWORDS="$( echo $stuff | awk -F"~" '{print $2}' )"
    ALLOWWORDSNICE="$( echo $ALLOWWORDS | tr -s ':' ' ' )"
    ALLOWWORDS="$( echo $ALLOWWORDS | tr -s ':' '|' )"

    if [ "$1" = "test" ]; then
      echo "--Entering $folders. Allowed words are $ALLOWWORDSNICE"
    fi

    if [ -e $GLROOT$folders ]; then
      cd $GLROOT$folders
      for them in `ls | egrep -v '\[' | egrep -iv $EXCLUDESPECIAL | egrep -iv -- $ALLOWWORDS`; do
        BANPROCESS="TRUE"
        for found in `find $GLROOT$folders/$them  -maxdepth 0 -type d -mmin +$TIMEALLOWNUKE -print | grep -vi "$NUKES" | cut -b$CUT-`; do
          ALLOW="$( find $GLROOT$folders/$them -maxdepth 1 -type d -print | grep -i $ALLOWED )"
          if [ "$ALLOW" = "" ]; then
            BANPROCESS="TRUE"
            if [ "$USESPACES" = "TRUE" ]; then
              release="{$folders/$them}"
            else
              release="$folders/$them"
            fi
            if [ "$1" = "test" ]; then
              echo "$them is older then $NTIME. NUKE! (test)"
              echo "String: $NUKEPROG -r $GLCONF -N $NUKEUSER -n $release $MULTIPLIER -Auto- Not allowed!"
              BANLAST="$them"
            else
              CORE="$( $NUKEPROG -r $GLCONF -N $NUKEUSER -n $release $MULTIPLIER -Auto- Not allowed! )"
              ALLOWLAST="$them"
              echo "$DATENOW Nuke: $folders/$them - Does not Contain any allowed work after $NTIME. $MULTIPLIER Nuke." >> $LOG
              ## Nuke Detail
              if [ "$EMBARRESALLOW" = "TRUE" ]; then
                CORECHECK="$( echo $CORE | cut -b-5 )"
                if [ "$CORECHECK" = "Empty" ]; then
                  CORE="$( echo $CORE | cut -b90- )"
                else 
                  CORE="$( echo $CORE | cut -b205- )"
                fi
                CORE="$( echo $CORE | tr -s '-' ' ' )"
                gotuser=""
                for each in $CORE; do
                  if [ "$next" = "yes" ]; then
                    if [ "$USEREXCLUDE" != "$each" ]; then
                      users="$users \002(\002$each"
                      uexcluded="no"
                      gotuser="true"
                    else
                      uexcluded="yes"
                    fi
                  fi
                  if [ "$each" = "Nukee:" ]; then
                    next="yes" 
                  else 
                    next="no"
                  fi
                  if [ "$next2" = "yes" ]; then
                    if [ "$uexcluded" = "no" ]; then
                      users="$users lost \037$each\037\002)\002"
                    fi
                  fi
                  if [ "$each" = "Lost:" ]; then
                    next2="yes" 
                  else 
                    next2="no"
                  fi
                done
                if [ "$gotuser" = "true" ]; then
                  sleep 1
                  echo `date "+%a %b %e %T %Y"` ANUKEL: \"$users\" >> $GLLOG
                  sleep 2
                fi
                users=""
              fi
            fi
          else
            if [ "$1" = "test" ]; then
              echo "$them does not contain any allowed word and is older then $NTIME, but it has been allowed."
            fi
            ALLOWLAST="$them"
          fi
        done
        if [ "$ALLOWLAST" != "$them" ]; then
          for them in `find $GLROOT$folders/$them -maxdepth 0 -type d -mmin +$EARLYALLOWPRENUKE -print | grep -vi "$NUKES" | cut -b$CUT-`; do
            them="`basename $them`"
            if [ "$MATCHUSER" = "TRUE" ]; then
              ## Find owner of dir
              uname=""
              unames=""
              for unames in `cat $GLLOG | grep -w $folders/$them'"' | grep -w NEWDIR: | awk -F" " '{print $8}' | tr -d '"'`; do
                uname="$unames"
              done
              if [ -z "$uname" ]; then
                uname="$NOUSERFOUND"
              else
                uname="$uname"
              fi
            fi
            ## Find out parent folder of the nuke.
            lastfolder="$( echo $folders | tr -s '/' ' ' )" 
            for lastfolders in $lastfolder; do
              lastfolder="$lastfolders"
            done
            ALLOW="$( find $GLROOT$folders/$them -maxdepth 1 -type d -print | grep -i $ALLOWED )"
            if [ -z "$ALLOW" ]; then
              BANPROCESS="TRUE"
              if [ "$1" = "test" ]; then
                if [ -e $TEMPDIR/prewarned.$them ]; then
                  echo "$lastfolder/$them$uname is older then $ETIME. Warning already sent. (test)"
                else
                  echo "$them$uname - No allowed word. Older then $ETIME. Prenuke-warning (test)"
                  echo "Tur-autonuke prewarning file" > $TEMPDIR/prewarned.$them 
                  WROTE="TRUE"
                fi
              else
                if [ ! -e $TEMPDIR/prewarned.$them ]; then
                  if [ "$BANALLOWNUKE" = "TRUE" ]; then
                    echo `date "+%a %b %e %T %Y"` ANUKEALLOW: \"$lastfolder/$them\" \"$uname\" \"$ETIME\" \"$NTIME\" >> $GLLOG
                    echo "Tur-autonuke prewarning file" > $TEMPDIR/prewarned.$them 
                    echo "$DATENOW Warn: $folders/$them$uname, no allowed word after its $ETIME old. Pre-nuke warning sent." >> $LOG
                  fi
                fi
              fi
            else
              if [ "$1" = "test" ]; then
                echo "Would be pre warning time for $GLROOT$folders/$them, but its been allowed."
                echo "$GLROOT$folders/$them" >> $TEMPDIR/tur-autonuke.ban.index
                WROTE="TRUE"
              fi
            fi
          done
        unset VERIFY
        fi
      done
    else
      if [ "$1" = "test" ]; then
        echo "I can not find $GLROOT$folders from the BANDIRS setting $stuff. Skipping it."
      fi
      if [ "$LOG" ]; then
        echo "$folders from the bandir setting $stuff can not be found. Skipping it." >> $LOG
      fi
    fi
  done
fi


###############################################################################################
# Delete nuked folders                                                                        #
###############################################################################################

if [ "$DELETENUKES" = "TRUE" ]; then
  unset LIST
  unset EXCLUDESPECIAL
  unset dirs
  unset folders
  unset VERIFY
  if [ "$1" = "test" ]; then
    echo ""
    echo "-[ Checking for nuked dirs to clean ]-"
  fi

  for folders in $DIRS; do
    if [ -e $GLROOT$folders ]; then
      cd $GLROOT$folders

      if [ "$1" = "test" ]; then
        echo "--Entering $folders"
      fi

      LIST="$( $LSM )"
      for dirs in $LIST; do
        VERIFY="$( echo $dirs | grep -F -- $NUKES )"
        if [ "$VERIFY" ]; then
          VERIFY="$( echo $VERIFY | tr -d ',' )"
          if [ "$1" = "test" ]; then
            echo " Found nuked folder: $VERIFY"
          fi
          for found in `find $GLROOT$folders/$VERIFY -maxdepth 0 -type d -mmin +$TIMETODELEM -print | grep -F -- "$NUKES" | grep -F -vx -- $VERIFY | cut -b$CUT-`; do
            MB="$( du -s -m $GLROOT$folders/$VERIFY | awk -F" " '{print $1}' )"
            if [ "$1" = "test" ]; then
              echo " $VERIFY ($MB mb) is older then $TIMETODELEM minutes. Deleting it."
            else
              echo "$DATENOW Dele: Deleting nuked folder: $folders/$VERIFY ($MB mb) because its $TIMETODELEM minutes old." >> $LOG
              rm -rf $GLROOT$folders/$VERIFY
            fi
          done
        fi
      done
    fi
  done
fi

###########################################################################################
# End. Clean up prewarned files if theres been no warnings this time.                     #
###########################################################################################

if [ "$BANPROCESS" != "TRUE" ]; then
  rm -f $TEMPDIR/prewarned.*
fi

rm -f $TEMPDIR/tur-autonuke.lock

exit 0
