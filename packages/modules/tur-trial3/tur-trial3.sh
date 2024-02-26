#!/bin/bash
VER=3.5.2

## Change these to match your setup ONLY if needed.
## Shouldnt be needed unless you get "config file not found"
## or "theme file not found."

# glroot=/glftpd
# config=/bin/tur-trial3.conf
# theme=/bin/tur-trial3.theme


###############################################################################
# No changes should be needed in this file at all.                            #
###############################################################################

if [ "$FLAGS" ] && [ "$glroot" ] ; then
  unset $glroot
fi

## Load config file
if [ -z "$config" ]; then
  if [ "`dirname $0`" = "." ]; then
    echo "DEBUG: Config loaded from ./ - not good. Using $PWD instead."
    config="${PWD}/tur-trial3.conf"
  else
    config="$( dirname $0 )/tur-trial3.conf"
  fi
else
  config="$glroot$config"
fi

if [ -z "$theme" ]; then
  if [ "`dirname $0`" = "." ]; then
    echo "DEBUG: Config theme from ./ - not good. Using $PWD instead."
    theme="${PWD}/tur-trial3.theme"
  else
    theme="$( dirname $0 )/tur-trial3.theme"
  fi
else
  theme="$glroot$theme"
fi

if [ ! -e "$theme" ]; then
  echo "theme file $theme not found."
  echo "Check theme= setting in tur-trial3.sh"
  exit 1
fi
if [ -e "$config" ]; then
  . $config
else
  echo "config file $config not found."
  echo "check config= setting in tur-trial3.sh"
  exit 1
fi

if [ -z "$SQLBIN" ]; then
  SQLBIN="mysql"
fi

if [ -z "$FLAGS" ]; then
  RUN_MODE="irc"

  ## Set SQL command..
  SQL="$SQLBIN -u $SQLUSER -p"$SQLPASS" -h $SQLHOST -D $SQLDB -N -s -e"

  ## Set all dirs below to include $GLROOT since were not inside glftpd.
  USERSDIR="$GLROOT$USERSDIR"
  if [ "$LOG" ]; then
    LOG="$GLROOT$LOG"
  fi
  if [ "$GLLOG" ]; then
    GLLOG="$GLROOT$GLLOG"
  fi
  PASSWD="$GLROOT$PASSWD"
  if [ "$BYEFILES" ]; then
    BYEFILES=$GLROOT$BYEFILES
  fi
  if [ "$MSGS" ]; then
    MSGS=$GLROOT$MSGS
  fi
  if [ "$MSS_CONFIG" ]; then
    MSS_CONFIG=$GLROOT$MSS_CONFIG
  fi
  if [ "$DEBUG_LOG" ]; then
    DEBUG_LOG=$GLROOT$DEBUG_LOG
  fi
  if [ -z "$1" ]; then
    echo "Specify 'help' for instructions."
    exit 0
  fi
else

  ## Set SQL command..
  SQL="/bin/mysql -u $SQLUSER -p"$SQLPASS" -h $SQLHOST -D $SQLDB -N -s -e"
  RUN_MODE="gl"
  NODEBUG=TRUE
fi

if [ "$RUN_MODE" = "irc" ] && [ "$USER" = "root" ]; then
  if [ "`crontab -l | grep -v "^#" | grep "/bin/reset" | grep "glftpd"`" ]; then
    echo "WARNING! Seems you have the glftpd reset binary in crontab."
    echo "This is BAD. Use a midnight script instead (see README) and"
    echo "remove reset from the crontab. Otherwise, kiss you users goodbye."
    exit 1
  fi
fi

## Function for writing to log with full date (for trial).
proc_log() {
  if [ "$LOG" ]; then
    echo `date "+%a %b %e %T %Y"` TT3: \"$*\" >> $LOG
  fi
}

## Log to same file without any date (for quota).
proc_logclean() {
  if [ "$LOG" ]; then
    echo "$*" >> $LOG
  fi
}

## Function for writing to glftpd.log
proc_gllog() {
  if [ "$GLLOG" ]; then
    echo `date "+%a %b %e %T %Y"` TURGEN: \"$*\" >> $GLLOG
  fi
}

## Used for outputting debug text to screen and to the logfile.
proc_debug() {
  if [ "$DEBUG" = "TRUE" ] && [ "$NODEBUG" != "TRUE" ]; then
    echo "DEBUG: $*" 
  fi

  if [ "$DEBUG_LOG" ]; then
    echo `date "+%a %b %e %T %Y"` $* >> $DEBUG_LOG
  fi
}

## Verify some variables.
if [ -z "$DATEBIN" ]; then
  DATEBIN="date"
fi
if [ "$PASS_BOTH_EXCLUDE_MONTHS" ]; then
  if [ "`echo "$PASS_BOTH_EXCLUDE_MONTHS" | tr -d '[:digit:]'`" ]; then
    echo "Error. PASS_BOTH_EXCLUDE_MONTHS should be the number of months to exclude. Not: $PASS_BOTH_EXCLUDE_MONTHS"
    exit 0
  fi
else
  PASS_BOTH_EXCLUDE_MONTHS="0"
fi
if [ "$USER" = "root" ] && [ "$LOG" ]; then
  touch $LOG
  if [ "`ls -al "$LOG" | cut -d ' ' -f1`" != "-rw-rw-rw-" ]; then
    proc_debug "Chmodding $LOG to 666"
    chmod 666 $LOG
  fi
fi
if [ "$USER" = "root" ] && [ "$DEBUG_LOG" ]; then
  touch $DEBUG_LOG
  if [ "`ls -al "$DEBUG_LOG" | cut -d ' ' -f1`" != "-rw-rw-rw-" ]; then
    proc_debug "Chmodding $DEBUG_LOG to 666"
    chmod 666 $DEBUG_LOG
  fi
fi
if [ "$TOP_UPLOADERS" = "TRUE" ] && [ "$SHOW_MONTHUP" = "FALSE" ]; then
  SHOW_MONTHUP="TRUE"
fi
if [ -z "$GL_VERSION" ]; then
  GL_VERSION="1"
fi
if [ "$QUOTA_SECTIONS_MERGE" ] && [ "`echo "$QUOTA_SECTIONS" | grep "\ "`" ]; then
  echo "Error. You can not specify more then one section in QUOTA_SECTIONS if you have"
  echo "QUOTA_SECTIONS_MERGE=\"TRUE\" in config."
  exit 0
fi
if [ "$TRIAL_SECTIONS_MERGE" ]; then
  if [ "`$SQL "select username from $SQLTB where active = '1' and startstats like '% %' limit 1"`" ]; then
    echo "Error. You have TRIAL_SECTIONS_MERGE=\"TRUE\" but some users have more then one statstats in"
    echo "database. You need to make sure you have no triallers before enabling TRIAL_SECTIONS_MERGE."
    exit 0
  fi
fi
if [ "$TRIAL_SECTIONS_MERGE" ] && [ "`echo "$TRIAL_SECTIONS" | grep "\ "`" ]; then
  echo "Error. You can not specify more then one section in TRIAL_SECTIONS if you have"
  echo "TRIAL_SECTIONS_MERGE=\"TRUE\" in config."
  exit 0
fi
if [ ! -d "/tmp" ]; then
  echo "Error. No /tmp directory exists. Create and set 777."
  exit 0
fi

## Check that the MYSQL server is running and all tables exists.
check_tables="^${SQLTB}$ ^${SQLTB_EXCLUDED}$ ^${SQLTB_RANK}$ ^${SQLTB_PASSED}$"

sqldata="`$SQL "show table status" | tr -s '\t' '^' | cut -d '^' -f1`"
if [ -z "$sqldata" ]; then
  unset ERRORLEVEL
  echo "Mysql error. Check server"
  exit 0
fi
for table in $sqldata; do
  if [ "`echo "$table" | grep "^ERROR$"`" ]; then
    echo "TT3 mysql error: $sqldata"
    exit 0
  fi
  unset table_ok
  for check_table in $check_tables; do
    if [ "`echo "$table" | grep "$check_table"`" ]; then
      table_ok="yepp"
    fi
  done
  if [ -z "$table_ok" ]; then
    echo "TT3 mysql error: Table $table not found. Make sure the mysql server is running."
    exit 0
  fi
done


## Help for adding someone on trial.
proc_addtrialhelp() {
  echo "#-"
  echo "# Function: Add a user for trial"
  echo "# Usage: site trial tadd <UserName>"
  echo "# Default number of days  : $TRIAL_DAYS_DEFAULT"
  echo "# Default Limit/Section is:"
  for rawdata in $TRIAL_SECTIONS; do
    sec_num="`echo "$rawdata" | cut -d ':' -f1`"
    sec_name="`echo "$rawdata" | cut -d ':' -f2`"
    sec_limit="`echo "$rawdata" | cut -d ':' -f3`"

    echo "# $sec_num Name:$sec_name Limit:$sec_limit Days"
  done
  echo "#-"
  echo "# Use 'tl' and 'tt' afterwards to change the default"
  echo "# trial limit and amount of time, if needed."
  echo "#-"
}


## Procedure for adding a user to database as a trialler.
proc_addtrial() {
  ## Check if a user was specified.
  if [ -z "$CURUSER" ]; then
    proc_addtrialhelp; exit 0
  fi

  ## Check if the user exists.
  if [ ! -e "$USERSDIR/$CURUSER" ]; then
    echo "User $CURUSER does not exist."
    exit 0
  fi

  ## Check if expr is installed.
  if [ "`expr 100 \+ 100`" != "200" ]; then
    if [ "$RUN_MODE" = "gl" ]; then
      echo ""
      echo "Seems you are missing the binary 'expr'. Find and copy that to your glftpd/bin dir."
      exit 1
    else
      echo "Seems you are missing the binary 'expr'..."
      exit 0
    fi
  fi

  ## Check that the user isnt already added to the database.
  if [ "`$SQL "select username from $SQLTB where username = '$CURUSER'"`" ]; then
    echo "No go there. $CURUSER is already added to the database."
    echo "If this user should get another trial (perhaps missed before) then"
    echo "use the 'treset' command to reset his trial stats."
    exit 0
  fi

  ## Grab the number of seconds since 1970-01-01 -> now.
  SECONDS_NOW="`$DATEBIN +%s`"
  ## Count how many seconds to add until end...
  END_TIME=$[$TRIAL_DAYS_DEFAULT*24*60*60+$SECONDS_NOW]

  ## Figure out how to make it an even hour rounded upwards ..:00
  rawdata="`$DATEBIN -d "1970-01-01 01:01:00 $END_TIME sec" +%M`"
  if [ "$rawdata" != "00" ]; then
    rawdataplus="`expr 60 \- $rawdata`"
    END_TIME=$[$rawdataplus*60+$END_TIME]
    unset rawdataplus; unset rawdata
  fi
  extra_seconds="`$DATEBIN +%S`"
  if [ "$extra_seconds" != "00" ]; then
    END_TIME="`expr $END_TIME \- $extra_seconds \- 2`"
  fi 

  ## Grab the userstats he currently has ( KB value from all sections ).
  if [ "$TRIAL_SECTIONS_MERGE" ]; then
    USER_STATS_NOW="`grep "^ALLUP" $USERSDIR/$CURUSER | cut -d ' ' -f$TRIAL_SECTIONS_MERGE`"
  else
    USER_STATS_NOW="`grep "^ALLUP" $USERSDIR/$CURUSER | cut -d ' ' -f3,6,9,12,15,18,21,24,27,30`"
  fi

  if [ "$TRIAL_SECTIONS_MERGE" ]; then
    statsmerge="0"
    for statstemp in $USER_STATS_NOW; do
      statsmerge=$[$statsmerge+$statstemp]
    done
    ## Left with anything?
    if [ -z "$statsmerge" ]; then
      echo "Internal error. Using TRIAL_SECTIONS_MERGE, tried to add together \"$USER_STATS_NOW\""
      echo "resulted in an empty respons ($statsmerge)."
      exit 0
    else
      proc_debug "Merged \"$USER_STATS_NOW\" stats into $statsmerge"
      USER_STATS_NOW="$statsmerge"
      unset statsmerge
      unset statstemp
    fi
  fi

  ## Make a start stats contining as many zeroes as detected zeroes.
  unset start_stats
  for each in $USER_STATS_NOW; do 
    start_stats="$start_stats 0"
  done
  ## Clean up $start_stats from extra spaces.
  start_stats="`echo $start_stats`"

  proc_debug "Seconds now: $SECONDS_NOW -- Stats for $CURUSER: $USER_STATS_NOW - $start_stats"

  unset USER_LIMITS
  for rawdata in $TRIAL_SECTIONS; do
    USER_LIMITS="$USER_LIMITS 0"
  done
  USER_LIMITS="`echo $USER_LIMITS`"
  if [ -z "$USER_LIMITS" ]; then
    echo "Error. proc_addtrial could not get a list of defined sections from TRIAL_SECTIONS."
    exit 0
  fi

  ## Insert this users information into the databse.
  $SQL "insert into $SQLTB (active, username, stats, added, endtime, extratime, startstats, tlimit) VALUES ('1', '$CURUSER', '$start_stats', '$SECONDS_NOW', '$END_TIME', '0', '$USER_STATS_NOW', '$USER_LIMITS')"

  ## Verify that the user was added successfully.
  if [ -z "`$SQL "select username from $SQLTB where username = '$CURUSER'"`" ]; then
    echo "Error. Tried to add but $CURUSER can not be found in the database now... Try again."
    exit 0
  fi

  ## Make a human readable "end time" display.
  END_TIME_NICE="`$DATEBIN -d "1970-01-01 01:01:00 $END_TIME sec" +%Y"-"%m"-"%d" : "%H":"%M`"
 
  ## Show the information.
  echo "$CURUSER added for trial until $END_TIME_NICE:00"
}


## Help for adding someone one quota/exclude/month exclude.
proc_addquotahelp() {
  echo "#-"
  echo "# Used to Add add user/Change status between"
  echo "# the different quota modes."

  case $SACTIVE in
    0) echo "# Usage: site qadd <UserName>"
       echo "# Adds a user for forced quota."
       ;;
    2) echo "# Usage: site eadd <UserName>"
       echo "# Excludes a user from quota"
       ;;
    3) echo "# Usage: site meadd <UserName> <Months>"
       echo "# Excludes a user from quota."
       echo "# If <Months> is not defined, hes excluded this month only."
       echo "# Note that <Months> is including the current month."
       echo "#"
       ;;
  esac

  echo "# Default Limit/Section is:"
  for rawdata in $QUOTA_SECTIONS; do
    sec_num="`echo "$rawdata" | cut -d ':' -f1`"
    sec_name="`echo "$rawdata" | cut -d ':' -f2`"
    sec_limit="`echo "$rawdata" | cut -d ':' -f3`"

    echo "# $sec_num Name: $sec_name Limit: $sec_limit"
  done
  echo "#-"
}



## Procedure for adding or changing a mode on a user.
## Not used for trial as that needs some special values (like endtime etc).
proc_addquota() {
  unset IN_DB_BEFORE
  
  ## Check if a user was specified.
  if [ -z "$CURUSER" ]; then
    proc_addquotahelp; exit 0
  fi

  ## Check if the user exists.
  if [ ! -e "$USERSDIR/$CURUSER" ]; then
    echo "User $CURUSER does not exist."
    exit 0
  fi

  ## Verify that we got an active mode to set.
  if [ -z "$SACTIVE" ]; then
    echo "Error. Didnt get a SACTIVE to set in the DB."
  fi

  ## Verify that MONTHS, if set, is correct.
  if [ "$MONTHS" ]; then
    if [ "`echo "$MONTHS" | tr -d '[:digit:]'`" ]; then
      echo "Error. Months specified should be a number."
      exit 0
    fi
    if [ "`echo "$MONTHS" | grep "..."`" ]; then
      echo "Error. Can not exclude someone for that long this way. Use eadd instead"
      echo "       or set the correct amount of months to exclude."
      exit 0
    fi
  fi

  ## Get the current active status, if any.
  rawdata="`$SQL "select active, stats, added, extratime, tlimit from $SQLTB where username = '$CURUSER'" | tr ' ' '~' | awk '{print $1"^"$2"^"$3"^"$4"^"$5}'`"

  ## If we DID get an active status from the database.
  ## Check his current active status and see that its not 1 (trial) and not the same
  ## as were trying to set.
  if [ "$rawdata" ]; then
    cur_active="`echo "$rawdata" | cut -d '^' -f1`"
    cur_stats="`echo "$rawdata" | cut -d '^' -f2 | tr '~' ' '`"
    cur_added="`echo "$rawdata" | cut -d '^' -f3`"
    cur_extratime="`echo "$rawdata" | cut -d '^' -f4`"
    cur_tlimit="`echo "$rawdata" | cut -d '^' -f5 | tr '~' ' '`"
    IN_DB_BEFORE="TRUE"

    if [ "$SACTIVE" = "0" ] && [ "$cur_active" = "0" ]; then
      if [ "$ANNOUNCE" = "TRUE" ]; then
        echo "$CURUSER is already on quota."
      fi
      exit 0
    elif [ "$SACTIVE" = "2" ] && [ "$cur_active" = "2" ]; then
      if [ "$ANNOUNCE" = "TRUE" ]; then
        echo "$CURUSER is already excluded from quota."
      fi
      exit 0
    elif [ "$cur_active" = "1" ]; then
      echo "No go there. $CURUSER is on trial. Use 'wipe' first to remove from trial first."
      exit 0
    fi

  else
    ## Set this if he wasnt in the database already.
    IN_DB_BEFORE="FALSE"
  fi

  startstats=0
  END_TIME="0"

  ## If he was in the db before, we have some saved values we want to use instead of the default ones.
  ## (incase he got specific tlimit or somthing).

  ## Note: If stats is 1 and SACTIVE (active flag) is 3, the user will be deleted from DB after this month.

  if [ "$IN_DB_BEFORE" = "TRUE" ]; then
    ## Save ANNOUNCE setting, wipe the user and restore the ANNOUNCE setting.
    OLD_ANNOUNCE="$ANNOUNCE"
    ANNOUNCE="FALSE"
    proc_wipe
    ANNOUNCE="$OLD_ANNOUNCE"

    stats="$cur_stats"

    ## Insert this users information into the database.
    $SQL "insert into $SQLTB (active, username, stats, added, endtime, extratime, startstats, tlimit) VALUES ('$SACTIVE', '$CURUSER', '$stats', '$cur_added', '$END_TIME', '0', '$startstats', '$cur_tlimit')"

    ## Verify that the user was added successfully.
    if [ -z "`$SQL "select username from $SQLTB where username = '$CURUSER'"`" ]; then
      echo "Error. Tried to add but $CURUSER can not be found in the database now..."
      proc_log "Error. Tried to add but $CURUSER can not be found in the database now... Aborting."
      exit 0
    fi

  else
    SECONDS_NOW="`$DATEBIN +%s`"

    ## Make a few 0's depending on the number of sections defined.
    ## Its for specific limits / section. 0 = default from config.
    if [ -z "$USER_LIMITS" ]; then
      for rawdata in $QUOTA_SECTIONS; do
        USER_LIMITS="$USER_LIMITS 0"
      done
      USER_LIMITS="`echo $USER_LIMITS`"
    fi

    if [ -z "$USER_LIMITS" ]; then
      echo "Error. Could not get a list of defined sections from QUOTA_SECTIONS."
      exit 0
    fi

    if [ "$SACTIVE" = "3" ]; then
      stats="1"
    else
      stats="0"
    fi

    ## Insert this users information into the database.
    $SQL "insert into $SQLTB (active, username, stats, added, endtime, extratime, startstats, tlimit) VALUES ('$SACTIVE', '$CURUSER', '$stats', '$SECONDS_NOW', '$END_TIME', '0', '$startstats', '$USER_LIMITS')"

    ## Verify that the user was added successfully.
    if [ -z "`$SQL "select username from $SQLTB where username = '$CURUSER'"`" ]; then
      echo "Error. Tried to add but $CURUSER can not be found in the database now..."
      proc_log "Error. Tried to add but $CURUSER can not be found in the database now... Aborting."
      exit 0
    fi
  fi

  ## if this is month exclude like above, check if MONTHS is set and if so, exclude those too."
  if [ "$SACTIVE" = "3" ] && [ "$MONTHS" ]; then
    NEW_MONTHS=$[$MONTHS-1]
    if [ "$NEW_MONTHS" -le "0" ]; then
      if [ "$ANNOUNCE" = "TRUE" ]; then
        echo "Warning. Months selected: $MONTHS. This means current month only. Making it so:"
      fi
    else
      $SQL "update $SQLTB set extratime = '$NEW_MONTHS' where username = '$CURUSER'"
    fi
  fi

  ## Show the information.
  if [ "$ANNOUNCE" = "TRUE" ]; then
    if [ "$SACTIVE" = "2" ]; then
      echo "$CURUSER is now excluded from quota."
    elif [ "$SACTIVE" = "3" ]; then
      if [ -z "$MONTHS" ] || [ "$MONTHS" -le "0" ]; then
        echo "$CURUSER is now excluded for the rest of the month."
      else
        echo "$CURUSER is now excluded for this month and $NEW_MONTHS months after that."
      fi
    elif [ "$SACTIVE" = "0" ]; then
      echo "$CURUSER is now on forced quota."
    fi
  fi

} ## END proc_addquota



proc_deltrialhelp() {
  echo "#-"
  echo "# Inactivate a user from trial"
  echo "#-"
  echo "# Usage: 'site del <username>'"
  echo "# This will deactivate a user from trial and add"
  echo "# him/her as a quota user instead."
  echo "#-"
}


proc_deltrial() {
  ## Check if a user was specified.
  if [ -z "$CURUSER" ]; then
    proc_deltrialhelp; exit 0
  fi

  ## Check that the user is in the database..
  if [ -z "`$SQL "select username from $SQLTB where username = '$CURUSER'"`" ]; then
    echo "No go there. $CURUSER is not added to the database. Use 'site trial add $CURUSER' first."
    exit 0
  fi

  ## Check if the user exists.
  if [ ! -e "$USERSDIR/$CURUSER" ]; then
    echo "Warning: User $CURUSER does not exist on site."
    exit 0
  fi

  ## Check that hes not already an inactive trialler.
  
  ## Check that hes on trial
  if [ "`$SQL "select active from $SQLTB where username = '$CURUSER'"`" = "0" ]; then
    echo "$CURUSER is not active on trial. If you want to wipe him from the database"
    echo "then use the 'wipe' command instead."
    exit 0
  fi

  $SQL "update $SQLTB set active = "0" where username = '$CURUSER'"
  if [ "`$SQL "select active from $SQLTB where username = '$CURUSER'"`" != "0" ]; then
    echo "Error. Tried to set 0 in the active field on $CURUSER, but its not 0 now..."
    exit 0
  fi

  echo "# $CURUSER is no longer an active trial user."
  exit 0
}




## Used to remove any information about the selected user from the trial table.
proc_wipe() {
  ## Check if a user was specified.
  if [ -z "$CURUSER" ]; then
    echo "Enter a username too please."

    if [ "$RUNMODE" = "WIPE" ] && [ "$ANNOUNCE" = "TRUE" ]; then 
      echo "This will remove the information in the database for the specified user"
      echo "but it will NOT do anything to the userfile. The user will be on normal"
      echo "quota once hes wiped."
    fi

    exit 0
  fi

  ## Check that the user is in the database..
  if [ -z "`$SQL "select username from $SQLTB where username = '$CURUSER'"`" ]; then
    echo "$CURUSER is not in the database. No need to wipe."
    exit 0
  fi

  ## Check if the user exists.
  if [ ! -e "$USERSDIR/$CURUSER" ]; then
    echo "NOTICE: User $CURUSER does not exist on site."
    echo "The 'update' cronjob will automatically delete his database info."
    exit 0
  fi

  $SQL "delete from $SQLTB where username = '$CURUSER'"
  if [ "`$SQL "select username from $SQLTB where username = '$CURUSER'"`" ]; then
    echo "Error. Could not wipe out $CURUSER from the database for some reason.."
    exit 0
  fi
  
  if [ "$ANNOUNCE" = "TRUE" ]; then
    echo "All traces of $CURUSER are gone forever."
  fi
}  


## Used for treset.
proc_treset() {
  proc_wipe
  proc_addtrial
}


## Used for qreset & ereset
proc_qreset() {
  proc_wipe
  proc_addquota
}


proc_changetimehelp() {
  echo "Usage: site trial tt <UserName> <time to change>"
  echo "       <Time to change>: +/- Interval Amount"
  echo "Specify interval with either D or H"
  echo "which represent Days or Hours."
  echo "The time can be increased or decresed, using +/-"
  echo "Example:"
  echo "site trial tt user +H1  -- Give user 1 more hour to pass."
  echo ""
}


## Procedure for adding or removing time from users.
proc_changetime() {
  ## Check if a user was specified.
  if [ -z "$CURUSER" ]; then
    proc_changetimehelp; exit 0
  fi

  ## Check if the user exists.
  if [ ! -e "$USERSDIR/$CURUSER" ]; then
    echo "User $CURUSER does not exist on site."
    exit 0
  fi

  ## Check that the user is in the database..
  if [ -z "`$SQL "select username from $SQLTB where username = '$CURUSER'"`" ]; then
    echo "No go there. $CURUSER is not added to the database. Use 'site trial add $CURUSER' first."
    exit 0
  fi

  ## Check that hes on trial
  if [ "`$SQL "select active from $SQLTB where username = '$CURUSER'"`" != "1" ]; then
    echo "#--"
    echo "# NOTICE: $CURUSER is currently not active in trial. You must activate him if these"
    echo "# changes will have any effect."
    echo "#--"
    exit 0
  fi

  ## Check that we really got a time supplied.
  if [ -z "$CHANGE_TIME" ]; then
    proc_changetimehelp
    echo "No changetime supplied.."
    exit 0
  fi

  ## Check if the first char in the time is either + or -
  if [ "`echo "$CHANGE_TIME" | cut -c1`" = "+" ]; then
    SIGN="+"
    WORD="Gave"
  elif [ "`echo "$CHANGE_TIME" | cut -c1`" = "-" ]; then
    SIGN="-"
    WORD="Took"
  else
    proc_changetimehelp
    echo "Error. Time should start with either + or -"
    exit 0
  fi

  ## Get the interval and check that its either D, H or M
  INTERVAL="`echo "$CHANGE_TIME" | cut -c2 | tr '[:lower:]' '[:upper:]'`"
  if [ -z "`echo "$INTERVAL" | egrep "^D$|^H$|^M$"`" ]; then
    proc_changetimehelp
    echo "Error. Must defined either D, H or M as interval.."
    exit 0
  fi

  ## Get the number behind SIGN INTERVAL and make sure its really a number.
  NUMBER="`echo "$CHANGE_TIME" | cut -c3-`"
  if [ -z "$NUMBER" ]; then
    proc_changetimehelp
    echo "Error. Didnt get a number for $CHANGE_TIME"
    exit 0
  elif [ "`echo "$NUMBER" | tr -d '[:digit:]'`" ]; then
    proc_changetimehelp
    echo "Error. Didnt seem to get amount of time there..."
    exit 0
  fi
  ## Make sure the number dosnt start with 0
  if [ "`echo "$NUMBER" | cut -c1`" = "0" ]; then
    echo "Error. Please dont start the time with a '0'"
    exit 0
  fi

  ## Get current time when its going to end from database.

  OLD_END_TIME="`$SQL "select endtime from $SQLTB where username = '$CURUSER'" | awk '{print $1}'`"
  if [ -z "$OLD_END_TIME" ]; then
    echo "Major error. While $CURUSER is in the database, there is no defined endtime."
    echo "You have to manually add one or remove that user and add him again."
    echo "Of course, we could also have lost connection to the mysql server.. Try again."
    exit 0
  fi

  proc_debug "Old time from database is $OLD_END_TIME"

  ## Calculate how many seconds we should add to the time in DB
  case $INTERVAL in
    D) SECS_TO_ADD=$[$NUMBER*24*60*60]; intname="day(s)" ;;
    H) SECS_TO_ADD=$[$NUMBER*60*60]; intname="hour(s)" ;;
    M) SECS_TO_ADD=$[$NUMBER*60]; intname="minute(s)" ;;
    *) echo "Error with INTERVAL. Should be D, H or M. Already checked that so not sure how we got here..."; exit0 ;;
  esac

  ## Make sure we got something
  if [ -z "$SECS_TO_ADD" ]; then
    echo "Error. We could not calculate how many seconds to add to the time in the database. Bug."
    exit 0
  fi

  ## Calculate new value for database.
  NEW_END_TIME=$[$OLD_END_TIME$SIGN$SECS_TO_ADD]

  ## Verify it (lots of verifying here.. Dont want to screw up the database.
  if [ -z "$NEW_END_TIME" ]; then
    echo "Error. After adding the new seconds ( $SECS_TO_ADD ) to the database value ( $OLD_END_TIME ) we got an empty result"
    exit 0
  fi

  ## Update the extratime value to reflect how many extra seconds the user got.
  CUR_EXTRA_TIME="`$SQL "select extratime from $SQLTB where username = '$CURUSER'" | awk '{print $1}'`"
  ## Verify that we got something. If not, set the value to 0 and quit (shouldnt happen)
  if [ -z "$CUR_EXTRA_TIME" ]; then
    echo "Error. Database failure. User $CURUSER exists but his extratime value is NULL."
    echo "This isnt a critical value. Setting it to 0 and quitting. Try the same command again afterwards."
    $SQL "update $SQLTB set extratime = '0' where username = '$CURUSER'"
    echo "Done."
    exit 0
  fi
  ## Calculate the NEW_EXTRA_TIME

  NEW_EXTRA_TIME=$[$CUR_EXTRA_TIME$SIGN$SECS_TO_ADD]  
  ## Verify it...
  if [ -z "$NEW_EXTRA_TIME" ]; then
    echo "Error on calculating new extratime. Added togher ( $SECS_TO_ADD ) and ( $CUR_EXTRA_TIME ) and came up empty."
    exit 0
  fi

  ## Update the database with the new endtime and extratime values
  $SQL "update $SQLTB set endtime='$NEW_END_TIME',extratime='$NEW_EXTRA_TIME' where username = '$CURUSER'"

  ## Verify that the endtime value was added successfully.
  if [ "`$SQL "select endtime from $SQLTB where username = '$CURUSER'" | awk '{print $1}'`" != "$NEW_END_TIME" ]; then
    echo "Error. Verification failed. Value for endtime in database is not $NEW_END_TIME as it should be..."
    $SQL "update $SQLTB set extratime = '$CUR_EXTRA_TIME' where username = '$CURUSER'"
    exit 0
  fi

  OLD_END_TIME_NICE="`$DATEBIN -d "1970-01-01 01:01:00 $OLD_END_TIME sec" +%Y"-"%m"-"%d" : "%H":"%M`"
  NEW_END_TIME_NICE="`$DATEBIN -d "1970-01-01 01:01:00 $NEW_END_TIME sec" +%Y"-"%m"-"%d" : "%H":"%M`"

  ## All is well. Announce it.
  echo "Moved $CURUSER's endtime by $SIGN $NUMBER $intname"
  echo "From: $OLD_END_TIME_NICE"
  echo "To  : $NEW_END_TIME_NICE"
} 
## END Changetime



## Procedure for calculating how much the $CURUSER uploaded since hes trial started.
## This is done by reading startstats from the database and the current ALLUP value
## from the userfile. Then deducting the startstats per section with ALLUP per section.
## Requires CURUSER to be set. Returns statskb and statsmb.
proc_trialuploaded() {
  unset stats
  unset statsmb
  unset statskb
  unset startstats
  unset curstats
  unset newstatskb
  unset foundit

  if [ -z "$CURUSER" ]; then
    echo "Internal error in proc_trialuploaded. No CURUSER supplied."
    exit 0
  fi

  ## Grab the starting stats from database for when the user went on trial.
  startstats="`$SQL "select startstats from $SQLTB where username = '$CURUSER'"`"

  ## Verify that we got some data.
  if [ -z "$startstats" ]; then
    echo "Error. Got no startstats information on $CURUSER from the database in proc_trialuploaded."
    echo "This user was probably never added to trial or data is corrupt."
    exit 0
  fi

  ## Grab current ALUP stats from user (all sections) and put in statskb.
  if [ "$TRIAL_SECTIONS_MERGE" ]; then
    curstats="`grep "^ALLUP\ " $USERSDIR/$CURUSER | cut -d ' ' -f$TRIAL_SECTIONS_MERGE`"
  else
    curstats="`grep "^ALLUP\ " $USERSDIR/$CURUSER | cut -d ' ' -f3,6,9,12,15,18,21,24,27,30`"
  fi
  ## Did we get anything ?
  if [ -z "$curstats" ]; then
    echo "Error. Could not get current ALLUP stats from $CURUSER - Check userfile."
    exit 0
  fi

  if [ "$TRIAL_SECTIONS_MERGE" ]; then
    statsmerge="0"
    for statstemp in $curstats; do
      statsmerge=$[$statsmerge+$statstemp]
    done
    ## Left with anything?
    if [ -z "$statsmerge" ]; then
      echo "Internal error. Using TRIAL_SECTIONS_MERGE, tried to add together \"$curstats\""
      echo "resulted in an empty respons ($statsmerge)."
      exit 0
    else
      proc_debug "Merged \"$curstats\" stats into $statsmerge"
      curstats="$statsmerge"
      unset statsmerge
      unset statstemp
    fi
  fi

  ## Deduct the value we had when trial started. Start loop on stats from userfile
  ## rather then from data in database since a section might have been added after the 
  ## user was put on trial.
  curnum=0
  for curstat in $curstats; do
    startnum=0; unset foundit
    for startstat in $startstats; do
      if [ "$startnum" = "$curnum" ]; then
        newstatskb="$newstatskb "$[$curstat-$startstat]
        foundit=yeah
      fi
      startnum=$[$startnum+1]
    done
    curnum=$[$curnum+1]
    ## If this number wasnt found in the database, use the current values from userfile (assume 0 from db).
    if [ -z "$foundit" ]; then
      newstatskb="$newstatskb $curstat"
    fi
  done
  ## Clean it up and move newstatkb to statskb
  statskb="`echo $newstatskb`"; unset newstatskb

  ## Convert all values to MB and put in $stats
  for stat in $statskb; do
    stats="$stats "$[$stat/1024]
  done
  ## Clean up $stats and statskb from excess spaces. rename stats to statsmb
  statsmb="`echo $stats`"
  statskb="`echo $statskb`"
}


proc_quotauploaded() {
  unset stats
  unset statsmb
  unset statskb
  unset startstats
  unset curstats
  unset newstatskb
  unset foundit

  if [ -z "$CURUSER" ]; then
    echo "Internal error in proc_trialuploaded. No CURUSER supplied."
    exit 0
  fi

  ## Grab current MONTHUP stats from user (all sections) and put in statskb.
  ## If QUOTA_SECTIONS_MERGE is set, only use those values.
  if [ "$QUOTA_SECTIONS_MERGE" ]; then
    statskb="`grep "^MONTHUP\ " $USERSDIR/$CURUSER | cut -d ' ' -f$QUOTA_SECTIONS_MERGE`"
  else
    statskb="`grep "^MONTHUP\ " $USERSDIR/$CURUSER | cut -d ' ' -f3,6,9,12,15,18,21,24,27,30`"
  fi

  ## Did we get anything ?
  if [ -z "$statskb" ]; then
    echo "Error. Could not get current MONTHUP stats from $CURUSER - Check userfile."
    statskb="1"
  fi

  if [ "$QUOTA_SECTIONS_MERGE" ]; then
    statsmerge="0"
    for statstemp in $statskb; do
      statsmerge=$[$statsmerge+$statstemp]
    done
    ## Left with anything?
    if [ -z "$statsmerge" ]; then
      echo "Internal error. Using QUOTA_SECTIONS_MERGE, tried to add together \"$statskb\""
      echo "resulted in an empty respons ($statsmerge)."
      exit 0
    else
      proc_debug "Merged \"$statskb\" stats into $statsmerge"
      statskb="$statsmerge"
      unset statsmerge
      unset statstemp
    fi
  fi

  ## Convert all values to MB and put in $stats
  for stat in $statskb; do
    stats="$stats "$[$stat/1024]
  done
  ## Clean up $stats and statskb from excess spaces. rename stats to statsmb
  statsmb="`echo $stats`"
  statskb="`echo $statskb`"
}


## Procedure for getting the group(s) from users.
## Returns $CURPRIGROUP and $CURGROUPS.
proc_get_groups() {
  if [ -z "$CURUSER" ]; then
    echo "Internal error. No CURUSER passed to proc_get_groups."
    exit 0
  fi
  unset CURGROUPS; unset CURPRIGROUP
 
  ## Grab all the groups for this user in variable $CURGROUPS
  ## If this is glftpd 2.0 and the user is gadmin, add a * infront of the groupname.
  for usergroupraw in `egrep "^GROUP |^PRIVATE " $USERSDIR/$CURUSER | cut -d ' ' -f2- | tr ' ' '~'`; do
    groupname="`echo "$usergroupraw" | cut -d '~' -f1`"
    gadmin="`echo "$usergroupraw" | cut -d '~' -f2`"
    if [ -z "$CURPRIGROUP" ]; then
      CURPRIGROUP="$groupname"
    fi
    if [ "$gadmin" = "1" ]; then
      groupname="*$groupname"
    fi
    CURGROUPS="$CURGROUPS $groupname"
  done
  CURGROUPS="`echo $CURGROUPS`"

  ## Set NoGroup if no group was found.
  if [ -z "$CURGROUPS" ]; then
    CURGROUPS="NoGroup"
    CURPRIGROUP="NoGroup"
  fi
}


proc_infohelp() {
  echo "Usage: site trial i <username>"
  echo "Will display some information about the users trial."
}


proc_info() {
  ## Check if a user was specified.
  if [ -z "$CURUSER" ]; then
    echo "Specify a username to check too."
    exit 0
  fi

  ## Check that the user is in the database..
  if [ -z "`$SQL "select username from $SQLTB where username = '$CURUSER'"`" ]; then
    echo "No go there. $CURUSER is not added to the database. Use 'site trial tadd $CURUSER' first."
    exit 0
  fi

  ## Check if the user exists.
  if [ ! -e "$USERSDIR/$CURUSER" ]; then
    echo "User $CURUSER does not exist on site, but he exists in database."
    echo "You should probably remove him (if you want to. Dosnt hurt)."
    exit 0
  fi

  proc_get_groups

  proc_trialuploaded

  ## Grab all the trialdata from this user.
  rawdata="`$SQL "select active, username, stats, added, endtime, extratime, startstats, tlimit from $SQLTB where username = '$CURUSER'" | tr ' ' '~' | awk '{print $1"^"$2"^"$3"^"$4"^"$5"^"$6"^"$7}'`"

  ## Verify that we got some data.
  if [ -z "$rawdata" ]; then
    echo "Error. Got no information on $CURUSER from the database."
    exit 0
  fi

  ## Split the data up into variables.
  active="`echo "$rawdata" | cut -d '^' -f1`"
  added="`echo "$rawdata" | cut -d '^' -f4`"
  endtime="`echo "$rawdata" | cut -d '^' -f5`"
  extratime="`echo "$rawdata" | cut -d '^' -f6`"
  startstats="`echo "$rawdata" | cut -d '^' -f7 | tr '~' ' '`"
  tlimit="`echo "$rawdata" | cut -d '^' -f8 | tr '~' ' '`"

  proc_debug "Stats from userfile: $statskb"
  proc_debug "Converted to MB    : $statsmb"

  ## Start showing the info.
  echo "#---------------------------------------------------#"
  echo "# Trial info for user: $CURUSER / $CURGROUPS"
  echo "#-"

  if [ "$active" = "1" ]; then
    echo "# Currently on trial: YES"
  else
    echo "# Currently on trial: NO"
  fi

  if [ "$active" = "1" ]; then
    echo "# Uploaded since trial started:"
  else
    echo "# While trial lasted, the following was uploaded:"
  fi

  ## Remake TRIAL_SECTIONS to $TRIAL_LIMITS ( if limits changed ).
  ## Sending TRIAL so it uses TRIAL_SECTIONS instead of QUOTA_SECTIONS.
  MODE="TRIAL"
  proc_recalctlimit

  echo -n "# "

  for rawdata in $TRIAL_LIMITS; do
    unset statsmb
    sectionnum=0
    numsection="`echo "$rawdata" | cut -d ':' -f1`"
    namesection="`echo "$rawdata" | cut -d ':' -f2`"
    limitsection="`echo "$rawdata" | cut -d ':' -f3`"

    for rawdata2 in $stats; do
      if [ "$numsection" = "$sectionnum" ]; then
        statsmb="$rawdata2"
      fi
      sectionnum=$[$sectionnum+1]
    done
    if [ -z "$statsmb" ]; then
      statsmb="0"
    fi

    echo -n "[ #$numsection:$namesection $statsmb/$limitsection MB ] "
  done

  echo ""
  echo "#-"

  ADDED_NICE="`$DATEBIN -d "1970-01-01 01:01:00 $added sec" +%Y"-"%m"-"%d" : "%H":"%M`"  
  echo "# Added to trial on: $ADDED_NICE"

  END_NICE="`$DATEBIN -d "1970-01-01 01:01:00 $endtime sec" +%Y"-"%m"-"%d" : "%H":"%M`"  
  echo "# Trial ending on  : $END_NICE"

  if [ "$added" -gt "$endtime" ]; then
    echo "# WARNING: Endtime is before addedtime. Did someone modify a little too much?"
    echo "#"
  fi

  if [ "$active" = "1" ]; then
    if [ "`$DATEBIN +%s`" -gt "$endtime" ]; then
      echo "# WARNING: This date is in the past. Either hes just about to go off quota"
      echo "#          or there is a missing crontab..."
      echo "#"
    fi
  fi

  if [ "$extratime" -gt "0" ]; then
    extra_days=0
    while [ "$extratime" -ge "86400" ]; do
      extra_days=$[$extra_days+1]
      extratime=$[$extratime-86400]
    done
    extra_hours=0
    while [ "$extratime" -ge "3600" ]; do
      extra_hours=$[$extra_hours+1]
      extratime=$[$extratime-3600]
    done
    extra_minutes=0
    while [ "$extratime" -ge "60" ]; do
      extra_minutes=$[$extra_minutes+1]
      extratime=$[$extratime-60]
    done
    echo "# EXTRA time given to pass: $extra_days days, $extra_hours hours, $extra_minutes minutes."
  elif [ "$extratime" -lt "0" ]; then
    extra_days=0
    while [ "$extratime" -le "-86400" ]; do
      extratime=$[$extratime+86400]
      extra_days=$[$extra_days+1]
    done
    extra_hours=0
    while [ "$extratime" -le "-3600" ]; do
      extra_hours=$[$extra_hours+1]
      extratime=$[$extratime+3600]
    done
    extra_minutes=0
    while [ "$extratime" -le "-60" ]; do
      extra_minutes=$[$extra_minutes+1]
      extratime=$[$extratime+60]
    done
    
    echo "# Trial has been SHORTENED by: $extra_days days, $extra_hours hours, $extra_minutes minutes."
  else
    echo "# Trial time has not been modifed from the default of $TRIAL_DAYS_DEFAULT days."
  fi

  sectionnum=0
  echo "#-"
  echo "# When $CURUSER was added to trial, the following stats already existed:"
  echo -n "# "
  for rawdata in $startstats; do
    for rawdata2 in $TRIAL_SECTIONS; do
      numsection="`echo "$rawdata2" | cut -d ':' -f1`"
      if [ "$numsection" = "$sectionnum" ]; then
        namesection="`echo "$rawdata2" | cut -d ':' -f2`"
        break 1
      fi
    done
    statsmb=$[$rawdata/1024]
    sectionnum=$[$sectionnum+1]
    echo -n "[ #$sectionnum:$namesection $statsmb MB ] "
  done
  echo ""
  echo "# This info is not important for you and is mostly for debugging purposes."
  echo "#-"
  echo "#---------------------------------------------------#"
  exit 0
} ## END PROC_INFO


## Procedure for getting a list of sections and putting in $DEFINED_SECTIONS  
proc_getsections() {
  if [ "$MODE" = "TRIAL" ]; then
    VALUE_SECTIONS="$TRIAL_SECTIONS"
  else
    VALUE_SECTIONS="$QUOTA_SECTIONS"
  fi

  if [ -z "$DEFINED_SECTIONS" ]; then
    for rawdata in $VALUE_SECTIONS; do
      secnum="`echo "$rawdata" | cut -d ':' -f1`"
      secname="`echo "$rawdata" | cut -d ':' -f2`" 
      seclimit="`echo "$rawdata" | cut -d ':' -f3`"
      if [ -z "$DEFINED_SECTIONS" ]; then
        DEFINED_SECTIONS="[#$secnum $secname $seclimit MB]"
        DEFINED_SECTIONS_NAME="#$secnum:$secname"
      else
        DEFINED_SECTIONS="$DEFINED_SECTIONS - [#$secnum $secname $seclimit MB]"
        DEFINED_SECTIONS_NAME="$DEFINED_SECTIONS_NAME - #$secnum:$secname"
      fi
    done
  fi
}

## Procedure for getting a list of sections and putting in $DEFINED_SECTIONS_NAME
#proc_getsections_name() {
# if [ "$MODE" = "TRIAL" ]; then
#   VALUE_SECTIONS="$TRIAL_SECTIONS"
# else
#   VALUE_SECTIONS="$QUOTA_SECTIONS"
#  fi

#  if [ -z "$DEFINED_SECTIONS_NAME" ]; then
#    for rawdata in $VALUE_SECTIONS; do
#      secnum="`echo "$rawdata" | cut -d ':' -f1`" 
#      secname="`echo "$rawdata" | cut -d ':' -f2`" 
#      if [ -z "$DEFINED_SECTIONS_NAME" ]; then
#        DEFINED_SECTIONS_NAME="#$secnum:$secname"
#      else
#        DEFINED_SECTIONS_NAME="$DEFINED_SECTIONS_NAME - #$secnum:$secname"
#      fi
#    done
#  fi
#}


## Procedure for calculating new trial/quota limits per section.
proc_recalctlimit() {
  unset TRIAL_LIMITS; unset QUOTA_LIMITS; unset TOPUP

  if [ -z "$CURUSER" ]; then
    echo "Internal error. Didnt get a CURUSER in proc_recalctlimit"
    exit 0
  fi

  ## Get current values
  tdata="`$SQL "select tlimit from $SQLTB where username = '$CURUSER'"`"
  ## Match it to section

  if [ "$MODE" = "QUOTA" ]; then
    ACTIVE_MODE="$QUOTA_SECTIONS"
  else
    ACTIVE_MODE="$TRIAL_SECTIONS"
  fi

  for sectionraw in $ACTIVE_MODE; do
    tnum=0
    secnum="`echo "$sectionraw" | cut -d ':' -f1`"
    secname="`echo "$sectionraw" | cut -d ':' -f2`"
    defseclimit="`echo "$sectionraw" | cut -d ':' -f3`"
    topupquota="`echo "$sectionraw" | cut -d ':' -f4`"

    for dbdata in $tdata; do
      if [ "$tnum" = "$secnum" ]; then
        if [ "$dbdata" != "0" ]; then
          NEW="$dbdata"
          if [ "$dbdata" = "-1" ]; then
            NEW="DISABLED"
            proc_debug "Limit Disabled for $CURUSER in $secname"
            
          fi
        fi
      fi
      tnum=$[$tnum+1]
    done

    ## If the 4rth bla:bla:bla:bla is specified and mode is QUOTA, add this one.
    if [ "$topupquota" ] && [ "$MODE" = "QUOTA" ]; then
      TOPUP=":$topupquota"
    fi

    if [ "$NEW" ]; then
      if [ -z "$TRIAL_LIMITS" ]; then
        TRIAL_LIMITS="$secnum:$secname:$NEW$TOPUP"
      else
        TRIAL_LIMITS="$TRIAL_LIMITS $secnum:$secname:$NEW$TOPUP"
      fi
      unset NEW
    else
      if [ -z "$TRIAL_LIMITS" ]; then
        TRIAL_LIMITS="$secnum:$secname:$defseclimit$TOPUP"
      else
        TRIAL_LIMITS="$TRIAL_LIMITS $secnum:$secname:$defseclimit$TOPUP"
      fi 
    fi

  done

  if [ "$MODE" = "QUOTA" ]; then
    QUOTA_LIMITS="$TRIAL_LIMITS"
  fi
}


proc_changesectionhelp() {
  if [ "$MODE" = "QUOTA" ]; then
    WORD="ql"
  else
    WORD="tl"
  fi
  echo "#--"
  echo "# Help for $WORD [ $MODE Limits ] - change Limit per section."
  echo "#--"
  echo "# Usage: site $WORD <username> <section:limit_to_pass>"
  echo "# Example: site $WORD $USER 0:1000"
  echo "# would change $USER's trial limit in section 0 to 1000 MB"
  echo "#-"
  echo "# To totally disable the trial/quota for a user, specify -1"
  echo "# Example: site $WORD $USER 0:-1"
  echo "#-"
  echo "# You can also specify DEFAULT as section to reset all limits to"
  echo "# the default"
  echo "# Example: site $WORD $USER DEFAULT"
  echo "#-"
  proc_getsections
  echo "# Default sections are:"
  echo "# $DEFINED_SECTIONS"
  if [ "$CURUSER" ]; then
    MODE="TRIAL"
    proc_recalctlimit
    unset OUTPUT
    for rawdata in $TRIAL_LIMITS; do
      secnum="`echo "$rawdata" | cut -d ':' -f1`"
      secname="`echo "$rawdata" | cut -d ':' -f2`"
      seclimit="`echo "$rawdata" | cut -d ':' -f3`"
      if [ "$seclimit" = "DISABLED" ]; then
        WORD="DISABLED"
      else
        WORD="$seclimit MB"
      fi
      if [ -z "$OUTPUT" ]; then
        OUTPUT="[#$secnum $secname $WORD]"
      else
        OUTPUT="$OUTPUT - [#$secnum $secname $WORD]"
      fi
    done
    echo "# Limits for $CURUSER:"
    if [ "$OUTPUT" = "$DEFINED_SECTIONS" ]; then
      echo "# Same as default above."
    else
      echo "# $OUTPUT"
    fi
  fi
  echo "#--"
}


## This is used to change the limits for a user in the database.
## Its called by tadd, qadd or eadd and gets MODE= to know which
## one its currently called from.
## TRIAL, QUOTA or EXCLUDE
proc_changesection() {
  ## Check if a user was specified.
  if [ -z "$CURUSER" ]; then
    proc_changesectionhelp; exit 0
  fi

  ## Check that the user is in the database..
  if [ -z "`$SQL "select username from $SQLTB where username = '$CURUSER'"`" ]; then
    echo "No go there. $CURUSER is not added to the database. Use 'tadd', 'qadd' or 'eadd' first."
    echo "tadd = Add user to trial"
    echo "qadd = Add user to quota"
    echo "eadd = Add user as excluded"
    exit 0
  fi

  ## Active on the specified mode?
  active="`$SQL "select active from $SQLTB where username = '$CURUSER'"`"
  if [ "$MODE" = "TRIAL" ]; then
    if [ "$active" != "1" ]; then
      echo "#-"
      echo "# NOTICE: $CURUSER is currently not active on trial."
      case $active in
        0) echo "# Currently activated for quota. Use 'ql' to change limits instead." ;;
        2) echo "# Currently excluded from quota. use 'el' to change limits instead." ;;
      esac
      echo "#-"
      exit 0
    fi
  elif [ "$MODE" = "QUOTA" ]; then
    if [ "$active" != "0" ]; then
      echo "#-"
      echo "# NOTICE: $CURUSER is currently not active on quota."
      case $active in
        1) echo "# Currently activated for trial. Use 'tl' to change limits instead." ;;
        2) echo "# Currently excluded from quota. use 'el' to change limits instead." ;;
      esac
      echo "#-"
      exit 0
    fi
  elif [ "$MODE" = "EXCLUDE" ]; then
    if [ "$active" != "2" ]; then
      echo "#-"
      echo "# NOTICE: $CURUSER is currently not excluded."
      case $active in
        1) echo "# Currently activated for trial. Use 'tl' to change limits instead." ;;
        0) echo "# Currently excluded from quota. use 'el' to change limits instead." ;;
      esac
      echo "#-"
      exit 0
    fi
    echo "#-"
    echo "# NOTICE: While you can change limits for an excluded user, it will be purely cosmetic."
  else
    echo "Internal error. proc_changesection called without a defined MODE."
    exit 0
  fi

  ## Check if the user exists.
  if [ ! -e "$USERSDIR/$CURUSER" ]; then
    echo "#-"
    echo "# User $CURUSER does not exist on site, but he exists in database."
    echo "# You should probably remove him (if you want to. Dosnt hurt)."
    echo "# Use 'wipe' to remove from database."
    echo "#-"
    exit 0
  fi

  ## Set values to use.
  if [ "$MODE" = "TRIAL" ]; then
    VALUE_SECTIONS="$TRIAL_SECTIONS"
  else
    VALUE_SECTIONS="$QUOTA_SECTIONS"
  fi

  ## Reset values?
  if [ "`echo "$CHANGE_SECTION" | tr '[:lower:]' '[:upper:]'`" = "DEFAULT" ]; then
    for rawdata in $VALUE_SECTIONS; do
      NEW_VALUES="$NEW_VALUES 0"
    done
    NEW_VALUES="`echo $NEW_VALUES`"

    proc_getsections

    $SQL "update $SQLTB set tlimit = '$NEW_VALUES' where username = '$CURUSER'"
    echo "#--"
    echo "# $CURUSER's limits for all sections have been reset to the default of:"
    echo "# $DEFINED_SECTIONS"
    echo "#--"
    exit 0
  fi

  ## Verify that change_section is set and has a : in it.
  if [ -z "$CHANGE_SECTION" ]; then
    proc_changesectionhelp
    echo "# Error message:"
    echo "# Missing <section:limit_to_pass>"
    echo "#--"
    exit 0
  elif [ -z "`echo "$CHANGE_SECTION" | grep ":"`" ]; then
    proc_changesectionhelp
    echo "# Error message:"
    echo "Section:Limit in wrong format. Missing :"
    echo "#--"
    exit 0
  fi

  SELECTED_SECTION="`echo "$CHANGE_SECTION" | cut -d ':' -f1`"
  if [ "`echo "$SELECTED_SECTION" | tr -d '[:digit:]'`" ]; then
    proc_changesectionhelp
    echo "# Error message:"
    echo "# Section $SELECTED_SECTION is not valid as a section number."
    echo "# Valid sections are:"
    proc_getsections
    echo "# $DEFINED_SECTIONS"
    echo "#--"
    exit 0
  elif [ -z "`echo "$SELECTED_SECTION" | grep "^[0-9]$"`" ]; then
    echo "#--"
    echo "# Error message:"
    echo "# Selected section should only contain one digit: 0-9"
    echo "# Valid sections are:"
    proc_getsections
    echo "# $DEFINED_SECTIONS"
    echo "#--"
    exit 0
  fi

  NEW_LIMIT="`echo "$CHANGE_SECTION" | cut -d ':' -f2`"

  if [ "`echo "$NEW_LIMIT" | tr -d '[:digit:]'`" ] && [ "$NEW_LIMIT" != "-1" ]; then
    proc_changesectionhelp
    echo "# Error message:"
    echo "# $NEW_LIMIT isnt a number.. Should contain the number of MB's to change section $SELECTED_SECTION to."
    echo "# Valid sections are:"
    proc_getsections
    echo "# $DEFINED_SECTIONS"
    echo "#--"
    exit 0
  elif [ "`echo "$NEW_LIMIT" | grep "......."`" ]; then
    echo "#--"
    echo "# Cant use limit $NEW_LIMIT - Number is much too large to be MB"
    echo "#--"
    exit 0
  fi

  for rawdata in $VALUE_SECTIONS; do
    secnum="`echo "$rawdata" | cut -d ':' -f1`"
    if [ "$secnum" = "$SELECTED_SECTION" ]; then
      secname="`echo "$rawdata" | cut -d ':' -f2`" 
      default_limit="`echo "$rawdata" | cut -d ':' -f3`"
    fi
  done

  if [ -z "$secname" ]; then
    echo "#--"
    echo "# No defined section found for number $SELECTED_SECTION"
    echo "# Valid sections are:"
    proc_getsections
    echo "# $DEFINED_SECTIONS"
    echo "#--"
    exit 0
  fi

  ## Grab info from DB
  rawdata="`$SQL "select active, stats, added, endtime, extratime, startstats, tlimit from $SQLTB where username = '$CURUSER'" | tr ' ' '~' | awk '{print $1"^"$2"^"$3"^"$4"^"$5"^"$6"^"$7}'`"

  ## Verify that we got some data.
  if [ -z "$rawdata" ]; then
    echo "#--"
    echo "# Got no information on $CURUSER from the database."
    echo "#--"
    exit 0
  fi

  ## Split the data up into variables.
  active="`echo "$rawdata" | cut -d '^' -f1`"
  stats="`echo "$rawdata" | cut -d '^' -f2 | tr '~' ' '`"
  added="`echo "$rawdata" | cut -d '^' -f3`"
  endtime="`echo "$rawdata" | cut -d '^' -f4`"
  extratime="`echo "$rawdata" | cut -d '^' -f5`"
  startstats="`echo "$rawdata" | cut -d '^' -f6 | tr '~' ' '`"
  tlimit="`echo "$rawdata" | cut -d '^' -f7 | tr '~' ' '`"

  ## Rebuild the data which we'll put in the database instead...
  tnum=0
  for rawdata in $tlimit; do
    if [ "$tnum" = "$SELECTED_SECTION" ]; then
      if [ "$rawdata" = "$NEW_LIMIT" ]; then
        if [ "$rawdata" = "0" ]; then
          echo "# $CURUSER's limit in [ $secname ] is already at default ($default_limit MB)."
        else
          echo "# $CURUSER's limit in [ $secname ] is already $rawdata MB"
        fi
        exit 0
      fi
      NEW_LIMITS="$NEW_LIMITS $NEW_LIMIT"
    else
      NEW_LIMITS="$NEW_LIMITS $rawdata"
    fi
    tnum=$[$tnum+1]
  done
  NEW_LIMITS="`echo $NEW_LIMITS`"

  if [ -z "$secname" ]; then
    echo "Error. Could not get the defined name for section $secnum from TRIAL_LIMITS"
    exit 0
  elif [ -z "$NEW_LIMITS" ]; then
    echo "Error. Tried to create new values for database but apparently failed."
    exit 0
  fi

  proc_debug "Current values: $tlimit"
  proc_debug "New values    : $NEW_LIMITS"
  proc_debug "Sectionname   : $secname"

  if [ "$NEW_LIMIT" != "0" ]; then
    if [ "$NEW_LIMIT" = "-1" ]; then
      WORD="DISABLED"
    else
      WORD="$NEW_LIMIT MB"
    fi
    echo "Updating trial limit on $CURUSER. Limit to pass [ $secname ] is now $WORD (default $default_limit MB)."
  else
    echo "Updating trial limit on $CURUSER. Will now use the default limit ($default_limit MB)."
  fi
  $SQL "update $SQLTB set tlimit = '$NEW_LIMITS' where username = '$CURUSER'"

  exit 0

}   

## Used when DAYS_LEFT is 0 to announce hours/minutes instead.
proc_get_hours_left() {
  hour_now="`$DATEBIN +%H`"
  ## Remove first char from hour_now if its a 0.
  if [ "`echo "$hour_now" | cut -c1`" = "0" ]; then
    hour_now="`echo "$hour_now" | cut -c2-`"
  fi

  hour_left=$[23-$hour_now]
  proc_debug "Checking hours/minutes left. Hours left: $hour_left (now: $hour_now)"

  minute_now="`$DATEBIN +%M`"
  ## Remove first char of minute_now if its a 0.
  if [ "`echo "$minute_now" | cut -c1`" = "0" ]; then
    minute_now="`echo "$minute_now" | cut -c2-`"
  fi

  minute_left=$[60-$minute_now]
  proc_debug "Minutes left $minute_left (now: $minute_now)"

  if [ "$hour_left" != "0" ]; then
    if [ "$hour_left" = "1" ] && [ "$minute_left" = "1" ]; then
      DAYS_LEFT="$hour_left hour, $minute_left minute"
    elif [ "$hour_left" = "1" ]; then
      DAYS_LEFT="$hour_left hour, $minute_left minutes"
    elif [ "$minute_left" = "1" ]; then
      DAYS_LEFT="$hour_left hours, $minute_left minute"
    else
      DAYS_LEFT="$hour_left hours, $minute_left minutes"
    fi
  else
    if [ "$minute_left" = "1" ]; then
      DAYS_LEFT="$minute_left minute"
    else
      DAYS_LEFT="$minute_left minutes"
    fi
  fi
  proc_debug "Final for DAYS_LEFT: $DAYS_LEFT"
}



## Procedure for checking a user. Will check if hes on trial, quota or not on anything
## and call the corresponding procedure for it.
proc_check() {
  unset given_time

  ## If this is executed from inside glftpd, only allow checking yourself.
  if [ "$RUN_MODE" = "gl" ]; then
    CURUSER="$USER"
  fi

  ## Check if a user was specified.
  if [ -z "$CURUSER" ]; then
    . $theme
    echo "$NO_USER_SELECTED"
    exit 0
  fi
  ## Check if the user exists.
  if [ ! -e "$USERSDIR/$CURUSER" ] || [ "`echo "$CURUSER" | grep "^default\."`" ]; then
    . $theme
    echo "$USER_NON_EXIST"
    exit 0
  fi

  proc_is_user_excluded

  if [ "$USER_EXCLUDED" = "TRUE" ] && [ "$EXCLUDED_REASON" = "User_is_deleted" ]; then
    . $theme
    echo "$USER_IS_DELETED"
    exit 0
  fi

  if [ "$USER_EXCLUDED" = "FALSE" ]; then
    active="0"
  else
    if [ "$THIS_MONTH" = "TRUE" ]; then
      ## Use is excluded and added this month. Set active 3.
      active="3"
      ## Need to set extratime to 0 so it counts days left this month.
      extratime=0
    fi
  fi

  ## Exists in trial db?
  rawdata="`$SQL "select active, endtime, extratime from $SQLTB where username = '$CURUSER'" | awk '{print $1"^"$2"^"$3}'`"
  if [ -z "$rawdata" ]; then
    active="0"
  else
    active="`echo "$rawdata" | cut -d '^' -f1`"
    proc_debug "$CURUSER is in the database. Got active value: $active"

    endtime="`echo "$rawdata" | cut -d '^' -f2`"
    extratime="`echo "$rawdata" | cut -d '^' -f3`"
    unset rawdata

    ## If the user has active 3 but is in excluded group, set active 0 instead to get the correct
    ## output.
    if [ "$active" = "3" ]; then
      proc_check_excluded
      if [ "$EXCLUDED_USER" = "TRUE" ]; then
        active="0"
      fi
    fi
  fi

  ## if active isnt 1 (trial), check if QUOTA_ENABLED is false. If so, assume active 3 (excluded did month).
  if [ "$active" != "1" ] && [ "$USER_EXCLUDED" != "TRUE" ]; then
    if [ "$QUOTA_ENABLED" = "FALSE" ]; then
      if [ "$QUOTA_DISABLED_MODE" ]; then
        active="$QUOTA_DISABLED_MODE"
        proc_debug "QUOTA_ENABLED is FALSE. Assume active $QUOTA_DISABLED_MODE (from QUOTA_DISABLED_MODE) for disabled this month."
      else
        active="3"
        proc_debug "QUOTA_ENABLED is FALSE. Assume active 3 for disabled this month."
      fi
    fi
  fi

  ## Get the groups for this user.
  proc_get_groups

  ## If active isnt 1 and quota is disabled, just say this.
  if [ "$active" != "1" ] && [ -z "$QUOTA_SECTIONS" ]; then
    . $theme
    echo "$USER_NOT_ON_TRIAL"
    exit 0
  fi

  ## If the user is on trial in database but trial is disabled, set active 0 (quota).
  if [ "$active" = "1" ] && [ -z "$TRIAL_SECTIONS" ]; then
    proc_debug "$CURUSER got active 1 in, but trial is disabled. Assume active 0"
    active=0
  fi

  ## User is on trial
  if [ "$active" = "1" ]; then

    proc_check_trial

    if [ -z "$trial_line" ]; then
      echo "Internal error: got no trial_line from proc_check_trial in proc_check"
      exit 0
    fi

    ## Get time in seconds now.
    SECS_NOW="`$DATEBIN +%s`"
#    proc_calctime1


    if [ -z "$TIME_COUNTH" ]; then
      ## What to say if the user is on trial and the time expired.
      . $theme
      echo "$TRIAL_TIME_OVERDUE"

    else
      if [ "$given_time" ]; then

        ## What to say if the user is still on trial and has been given extra time to pass.
        . $theme
        echo "$TRIAL_EXTRA_TIME"

      else
        ## What to say if the user is still on trial (normal. No extra time given).
        . $theme
        echo "$TRIAL_NORMAL"
      fi
    fi

    ## Checking passed on passed user removes the user from trial.
    if [ "$PASSED" = "TRUE" ] && [ "$RUN_MODE" = "irc" ]; then
      proc_trial_passed
    fi

    exit 0

  ## User is on quota.
  elif [ "$active" = "0" ]; then

    proc_check_quota

    ## Get a nice list of where the user is on the topup
    if [ "$SHOW_MONTHUP" = "TRUE" ]; then
      proc_get_user_pos_nice
    fi

    ## Check how many days are left.
    proc_get_days_in_month
    DAYS_LEFT="$( expr "$MONTHTOTAL" \- "`$DATEBIN +%d`" )"
    proc_debug "Days left: $DAYS_LEFT"

    if [ "$DAYS_LEFT" = "0" ]; then
      proc_get_hours_left
    else
      if [ "$DAYS_LEFT" = "1" ]; then
        DAYS_LEFT="$DAYS_LEFT day"
      else
        DAYS_LEFT="$DAYS_LEFT days"
      fi
    fi

    ## Only announce how many more days the user is excluded if hes actually NOT excluded by group as well.
    if [ "$THIS_MONTH" = "TRUE" ] && [ "$EXCLUDED_USER" != "TRUE" ]; then
      . $theme
      echo "$QUOTA_MONTH_EXCLUDED"
    else

      ## What to say if the user passed quota.
      if [ "$PASSED" = "TRUE" ]; then 
        if [ "$EXCLUDED_USER" = "TRUE" ]; then
          ## What to say if the user passed but is excluded by group!
          . $theme
          echo "$QUOTA_GROUP_EXCLUDED_PASSED"

          if [ "$SHOW_MONTHUP" = "TRUE" ]; then
            if [ "$TOP_UPLOADERS" = "TRUE" ] && [ "$POSITION_NICE" != "NONE" ]; then
              . $theme
              #if [ "$TOP_UPLOADERS_EXCLUDED_SHOW_AS_QUOTA" = "TRUE" ]; then
                if [ "$TOP_UP_PASSED" = "TRUE" ]; then
                  echo "$TOP_GROUP_EXCLUDED_PASSED"
                else
                  echo "$TOP_GROUP_EXCLUDED_FAILED"
                fi
              #else
              #  echo "$POSITION_EXCLUDED"
              #fi
            fi
          fi

        else
          ## What to say if the user passed quota and isnt excluded.
          . $theme
          echo "$QUOTA_NORMAL_PASSED"

          if [ "$SHOW_MONTHUP" = "TRUE" ]; then
            if [ "$TOP_UPLOADERS" = "TRUE" ] && [ "$POSITION_NICE" != "NONE" ]; then
              . $theme
              #if [ "$TOP_UPLOADERS_EXCLUDED_SHOW_AS_QUOTA" = "TRUE" ]; then
                if [ "$TOP_UP_PASSED" = "TRUE" ]; then
                  echo "$TOP_NORMAL_PASSED"
                else
                  echo "$TOP_NORMAL_FAILED"
                fi
              #else
              #  echo "$POSITION_NORMAL"
              #fi
            fi
          fi

        fi

      ## What to say if the user has not yet passed quota.
      else
        if [ "$EXCLUDED_USER" = "TRUE" ]; then

          ## What to say if the user hasnt passed quota yet, but is excluded by group!
          . $theme
          echo "$QUOTA_GROUP_EXCLUDED_FAILED"

          if [ "$SHOW_MONTHUP" = "TRUE" ]; then
            if [ "$TOP_UPLOADERS" = "TRUE" ] && [ "$POSITION_NICE" != "NONE" ]; then
              if [ "$TOP_UP_PASSED" = "TRUE" ]; then
                echo "$TOP_GROUP_EXCLUDEDF_PASSED"
              else
                echo "$TOP_GROUP_EXCLUDEDF_FAILED"
              fi
            fi
          fi

        else

          ## What to say if the user hasnt passed yet and isnt excluded or anything.
          . $theme
          echo "$QUOTA_NORMAL_FAILED"

          if [ "$SHOW_MONTHUP" = "TRUE" ]; then
            if [ "$TOP_UPLOADERS" = "TRUE" ] && [ "$POSITION_NICE" != "NONE" ]; then
              if [ "$TOP_UP_PASSED" = "TRUE" ]; then
                echo "$TOP_QUOTA_NORMAL_PASSED"
              else
                echo "$TOP_QUOTA_NORMAL_FAILED"
              fi
            fi
          fi


        fi
      fi
    fi

    if [ "$SHOW_MONTHUP" = "TRUE" ]; then
      if [ "$TOP_UPLOADERS" = "FALSE" ] && [ "$POSITION_NICE" != "NONE" ]; then
        . $theme
        if [ "$EXCLUDED_USER" = "TRUE" ]; then
          echo "$POSITION_EXCLUDED"
        else
          echo "$POSITION_NORMAL"
        fi
      fi
    fi

  ## User is excluded by database.
  elif [ "$active" = "2" ]; then
    ## Get user positions
    proc_check_quota

    ## Get a nice list of where the user is on the topup
    if [ "$SHOW_MONTHUP" = "TRUE" ]; then
      proc_get_user_pos_nice
    fi

    ## What to say if the user is excluded in the database (active 2).
    . $theme
    if [ "$PASSED" = "TRUE" ]; then

      ## What to say if the user is excluded in database but passed anyway.
      echo "$QUOTA_MANUAL_EXCLUDED_PASSED"

    else

      ## What to say if the user is excluded in the database but hasnt passed yet.
      echo "$QUOTA_MANUAL_EXCLUDED_FAILED"

    fi   

    ## Position info for users with flag 2 (thats the if we're in).
    if [ "$SHOW_MONTHUP" = "TRUE" ]; then
      if [ "$TOP_UPLOADERS" = "TRUE" ] && [ "$POSITION_NICE" != "NONE" ]; then
        if [ "$TOP_UP_PASSED" = "TRUE" ]; then
          echo "$TOP_QUOTA_EXCLUDED_PASSED"
        else
          echo "$TOP_QUOTA_EXCLUDED_FAILED"
        fi
      fi
    fi

    if [ "$SHOW_MONTHUP" = "TRUE" ]; then
      if [ "$TOP_UPLOADERS" = "FALSE" ] && [ "$POSITION_NICE" != "NONE" ]; then
        if [ "$EXCLUDED_USER" = "TRUE" ]; then
          ## User is not also excluded by group.
          echo "$POSITION_EXCLUDED_NONGROUP"
        else
          ## User IS also excluded by group (why is he manually excluded then?)
          echo "$POSITION_EXCLUDED_GROUP"
        fi
      fi
    fi


  ## User is excluded for the rest of the month (either cause of vacation or manually set active 3).
  elif [ "$active" = "3" ]; then

    ## Get user positions
    proc_check_quota

    ## Get a nice list of where the user is on the topup
    if [ "$SHOW_MONTHUP" = "TRUE" ]; then
      proc_get_user_pos_nice
    fi
 
    ## Since the user has active 3, check if extratime is set. If so, that defines how many more
    ## months after the current on that he is excluded for.
    if [ "$extratime" = "0" ]; then
      ## Check how many days are left.
      proc_get_days_in_month
      DAYS_LEFT="$( expr "$MONTHTOTAL" \- "`$DATEBIN +%d`" )"
      proc_debug "Days left: $DAYS_LEFT"

      if [ "$DAYS_LEFT" = "0" ]; then
        proc_get_hours_left
      else
        if [ "$DAYS_LEFT" = "1" ]; then
          DAYS_LEFT="$DAYS_LEFT day"
        else
          DAYS_LEFT="$DAYS_LEFT days"
        fi
      fi

    else
      ## Add 1 (to include the current month) to extratime and use the to display months excluded instead.
      extratime=$[$extratime+1]
      DAYS_LEFT="$extratime months"
    fi

    ## What to say if the user is excluded in the database for the rest of the month (active 3).
    . $theme
    if [ "$PASSED" = "TRUE" ]; then
      ## What to say if the user is excluded in database but passed anyway.
      echo "$QUOTA_MEXCLUDED_PASSED"
    else
      ## What to say if the user is excluded in the database but hasnt passed yet.
      echo "$QUOTA_MEXCLUDED_FAILED"
    fi   

    ## Position info for users with active 3 (thats the if we're in).
    if [ "$SHOW_MONTHUP" = "TRUE" ]; then
      if [ "$TOP_UPLOADERS" = "TRUE" ] && [ "$POSITION_NICE" != "NONE" ]; then
        if [ "$TOP_UP_PASSED" = "TRUE" ]; then
          echo "$TOP_QUOTA_MEXCLUDED_PASSED"
        else
          echo "$TOP_QUOTA_MEXCLUDED_FAILED"
        fi
      fi
    fi
    if [ "$SHOW_MONTHUP" = "TRUE" ]; then
      if [ "$TOP_UPLOADERS" = "FALSE" ] && [ "$POSITION_NICE" != "NONE" ]; then
        # (changed for 3.1beta4) # if [ "$EXCLUDED_USER" = "TRUE" ]; then
        if [ "$USER_EXCLUDED" = "TRUE" ]; then
          echo "$POSITION_MEXCLUDED_NONGROUP"
        else
          echo "$POSITION_MEXCLUDED_GROUP"
        fi
      fi
    fi

  else
    echo "Database error on $CURUSER. Flag found: $active - not accepted."
    proc_log "Database error on $CURUSER. Flag found: $active - not accepted."
    exit 0
  fi
 
}


## Calculates how many days,hours,minutes there are in a defined 
## number of credits ($secs_check needs to be set first).
## Returns TIME_COUNTD, TIME_COUNTH & TIME_COUNTM depending
## on what you want to use.
proc_calctime1() {
  unset TIME_COUNTD; unset TIME_COUNTH; unset TIME_COUNTM
  days=0
  hours=0
  minutes=0
  if [ -z "$secs_check" ]; then
    echo "Internal error. secs_check not defined for proc_calctime."
    exit 0
  fi

  while [ "$secs_check" -ge "86400" ]; do
    days=$[$days+1]
    secs_check=$[$secs_check-86400]
  done
  while [ "$secs_check" -ge "3600" ]; do
    hours=$[$hours+1]
    secs_check=$[$secs_check-3600]
  done
  while [ "$secs_check" -ge "60" ]; do
    minutes=$[$minutes+1]
    secs_check=$[$secs_check-60]
  done

  if [ "$days" != "0" ]; then
    if [ "$days" = "1" ]; then
      TIME_COUNTD="$days day"
    else
      TIME_COUNTD="$days days"
    fi
  else
    TIME_COUNTD="0 days"
  fi

  if [ "$hours" != "0" ]; then
    if [ "$hours" = "1" ]; then
      TIME_COUNTH="$hours hour"
    else
      TIME_COUNTH="$hours hours"
    fi
  else
    TIME_COUNTH="0 hours"
  fi

  if [ "$minutes" != "0" ]; then
    if [ "$minutes" = "1" ]; then
      TIME_COUNTM="$minutes minute"
    else
      TIME_COUNTM="$minutes minutes"
    fi
  else
    if [ "$hours" = "0" ]; then
      TIME_COUNTM="0 minutes"
    else
      TIME_COUNTM="$TIME_COUNTH"
    fi
  fi

# echo "TIME_COUNTD: $TIME_COUNTD"
# echo "TIME_COUNTH: $TIME_COUNTH"
# echo "TIME_COUNTM: $TIME_COUNTM"

  ## Remake TIME_CALCM
  if [ "$minutes" = "0" ]; then
    if [ "$hours" = "0" ]; then
      TIME_COUNTM="$TIME_COUNTD"
    else
      if [ "$days" = "0" ]; then
        TIME_COUNTM="$TIME_COUNTH"
      else
        TIME_COUNTM="$TIME_COUNTD, $TIME_COUNTH"
      fi
    fi
  else
    if [ "$hours" = "0" ]; then
      if [ "$days" = "0" ]; then
        TIME_COUNTM="$TIME_COUNTM"
      else
        TIME_COUNTM="$TIME_COUNTD, 0 hours, $TIME_COUNTM"
      fi
    else
      if [ "$days" = "0" ]; then
        TIME_COUNTM="$TIME_COUNTH, $TIME_COUNTM"
      else
        TIME_COUNTM="$TIME_COUNTD, 0 hours, $TIME_COUNTM"
      fi
    fi
  fi 


  ## Remake TIME_COUNTH
  if [ "$hours" = "0" ]; then
    if [ "$days" = "0" ]; then
      TIME_COUNTH="0 hours"
    else
      TIME_COUNTH="$TIME_COUNTD"
    fi
  else
    if [ "$days" = "0" ]; then
      TIME_COUNTH="$TIME_COUNTH"
    else
      TIME_COUNTH="$TIME_COUNTD, $TIME_COUNTH"
    fi
  fi

#  echo "New TIME_COUNTD: $TIME_COUNTD"
#  echo "New TIME_COUNTH: $TIME_COUNTH"
#  echo "New TIME_COUNTM: $TIME_COUNTM"

#  echo "days: $days"
#  echo "hour: $hours"
#  echo "mins: $minutes"

  unset secs_check
}


## Check if the user was added this month. Returns THIS_MONTH=TRUE/FALSE
## Only used if PASSWD is defined.
proc_check_this_month() {
  THIS_MONTH="FALSE"
  LAST_MONTH="FALSE"
  if [ "$PASSWD" ]; then
    proc_debug "Checking if $CURUSER was added this month."
    ## Have this user been on the site long enough?
    passwd_date="`grep "^$CURUSER:" $PASSWD | cut -d ':' -f5`"
    if [ -z "$passwd_date" ]; then
      proc_log "WARNING. $CURUSER dosnt seem to have any entry in $PASSWD"
    else
      passwd_month="`echo "$passwd_date" | cut -d '-' -f1`"
      passwd_year="`echo "$passwd_date" | cut -d '-' -f3`"

      if [ "$passwd_year" -lt "50" ]; then
        passwd_year="20${passwd_year}"
      else
        passwd_year="19${passwd_year}"
      fi

      if [ "$passwd_year" = "`$DATEBIN +%Y`" ]; then
        if [ "$passwd_month" = "`$DATEBIN +%m`" ]; then
          THIS_MONTH="TRUE"
          proc_debug "$CURUSER added this month !"
        fi
      fi

      if [ "$passwd_year" = "`$DATEBIN -d "-1 month" +%Y`" ]; then
        if [ "$passwd_month" = "`$DATEBIN -d "-1 month" +%m`" ]; then
          ## LAST_MONTH was added for the 'qcron' function since it runs
          ## at the start of a new month...
          LAST_MONTH="TRUE"
          proc_debug "$CURUSER added last month !"
        fi
      fi
    fi
  else
    proc_debug "Warning. PASSWD not set in config. Not checking if user is added this month."
  fi
}

## Used when checking how the users on quota is doing.
proc_check_quota() {
  unset quota_line; unset PASS_DATA; unset times_over_sec
  PASSED="FALSE"; times_over="0"

  if [ -z "$CURUSER" ]; then
    echo "Internal error. proc_checktrial did not get a supplied CURUSER."
    exit 0
  fi
  unset statsmb; unset statskb
  proc_quotauploaded
  proc_debug "Uploaded so far this month: $statsmb -- $statskb"
  if [ -z "$statsmb" ]; then
    echo "Internal error. proc_quotauploaded did not return 'statsmb' to proc_check_quota."
    exit 0
  fi

  ## Create the list of how much the user SHOULD upload for each section.
  ## This is in QUOTA_SECTIONS format ( #:name:value #:name:value )
  MODE="QUOTA"
  proc_recalctlimit
  if [ -z "$QUOTA_LIMITS" ]; then
    echo "Internal error. proc_recalclimit did not return 'QUOTA_LIMITS' to proc_check_quota."
    exit 0
  fi
  proc_debug "Quota limits for $CURUSER is $QUOTA_LIMITS"

  ## Go through each quota limit for user and see if hes currently over any limit."

  for rawdata in $QUOTA_LIMITS; do
    cur_limit_num=0
    unset cur_limit
    statnum="`echo "$rawdata" | cut -d ':' -f1`"
    sectionname="`echo "$rawdata" | cut -d ':' -f2`"
    pass_limit="`echo "$rawdata" | cut -d ':' -f3`"

    ## Match the statnum with the stats for this section (taken from the userfiles MONTHUP).
    for statsmb_value in $statsmb; do 
      if [ "$statnum" = "$cur_limit_num" ]; then
        cur_limit="$statsmb_value"
      fi
      cur_limit_num=$[$cur_limit_num+1]
    done

    if [ -z "$cur_limit" ]; then
      cur_limit="0"
    fi

    ## Calculate $per_day, but not if running from qcron (quota crontab. no use there).
    if [ "$RUNMODE" = "qcron" ]; then
      per_day="N/A "
    else
      if [ -z "$DAYS_LEFT" ]; then
        proc_get_days_in_month
        DAYS_LEFT="$( expr "$MONTHTOTAL" \- "`$DATEBIN +%d`" )"
      fi
      if [ $DAYS_LEFT != "0" ]; then
        per_day=$[$pass_limit-$cur_limit]
        proc_debug "${sectionname}: pass_limit:$pass_limit - cur_limit:$cur_limit = $per_day needed."
        per_day=$[per_day/$DAYS_LEFT]
        proc_debug "${sectionname}: Split it by DAYS_LEFT:$DAYS_LEFT = $per_day MB/day."
      else
        per_day=$[$pass_limit-$cur_limit]
      fi
    fi

    if [ "$pass_limit" = "0" ]; then
      pass_limit="DISABLED"
      PASSED=TRUE
    fi

    # proc_debug "Limit for $statnum:$sectionname is $pass_limit. $CURUSER is at $cur_limit so far."

    ## Set PASSED=TRUE if the user is over any of the limits.
    . $theme
    if [ "$pass_limit" != "DISABLED" ]; then
      if [ "$cur_limit" -ge "$pass_limit" ]; then
        PASSED="TRUE"

        if [ -z "$trial_line" ]; then
          trial_line="${TRIAL_LINE_ANNOUNCE_PASSED}"
        else
          trial_line="${trial_line}${TRIAL_LINE_ANNOUNCE_SEPERATOR}${TRIAL_LINE_ANNOUNCE_PASSED}"
        fi

        ## PASS_DATA is used when topup is disabled in a section. Need to know if he passed or not."
        PASS_DATA="$PASS_DATA $statnum:P"

        ## Calculate by how many times the user passed the quota.. Returns $times_over.
        times_over_temp="0"

        ## Dont want to ruin the $cur_limit.. Use $cur_limit_temp instead.
        cur_limit_temp="$cur_limit"
        while [ "$cur_limit_temp" -ge "$pass_limit" ]; do
          times_over_temp=$[$times_over_temp+1]
          cur_limit_temp=$[$cur_limit_temp-$pass_limit]
        done
        ## If we have more then one section, we might already have a $times_over. Dont replace it if what
        ## we got here is smaller.
        if [ "$times_over_temp" -gt "$times_over" ]; then
          times_over="$times_over_temp"
          times_over_sec="$sectionname"
        fi

      else

        if [ -z "$trial_line" ]; then
          trial_line="${TRIAL_LINE_ANNOUNCE_NOT_PASSED}"
        else
          trial_line="${trial_line}${TRIAL_LINE_ANNOUNCE_SEPERATOR}${TRIAL_LINE_ANNOUNCE_NOT_PASSED}"
        fi

        PASS_DATA="$PASS_DATA $statnum:F"
      fi
    fi
  done
  ## Clean it up from excess spaces.
  trial_line="`echo $trial_line`"
  PASS_DATA="`echo $PASS_DATA`"
}

## Procedure for displaying information about someone currently on trial (active:1)
proc_check_trial() {
  unset trial_line
  PASSED="FALSE"
  unset per_day

  if [ -z "$CURUSER" ]; then
    echo "Internal error. proc_checktrial did not get a supplied CURUSER."
    exit 0
  fi
  ## Create the list of how much the user uploaded for each section.
  ## This is pure numbers ( 0 0 0 )
  unset statsmb; unset statskb
  proc_trialuploaded
  if [ -z "$stats" ]; then
    echo "Internal error. proc_trialuploaded did not return 'stats' to proc_check_trial."
    exit 0
  fi
  proc_debug "Uploaded by $CURUSER: $statsmb MB - $statskb KB"
  ## Fixing $statsmb for easy editing.
  statsmb="$statsmb "

  ## Crate the list of how much the user SHOULD upload for each section.
  ## This is in TRIAL_SECTIONS format ( #:name:value #:name:value )
  MODE="TRIAL"
  proc_recalctlimit
  if [ -z "$TRIAL_LIMITS" ]; then
    echo "Internal error. proc_recalclimit did not return 'TRIAL_LIMITS' to proc_check_trial."
    exit 0
  fi
  proc_debug "Trial limits for $CURUSER is $TRIAL_LIMITS"

  unset trial_line

  SECS_NOW="`$DATEBIN +%s`"

  ## Did the user get extra time ?
  if [ "$extratime" != "0" ]; then
    proc_debug "Got extra time given/taken from this user $extratime.. processing."
    if [ "$extratime" -gt "0" ]; then
      secs_check=$extratime
      proc_calctime1
      given_time="$TIME_COUNTM"
      proc_debug "Extra time given: $given_time : $days $hours $minutes"
    fi        
  fi

  ## Are the user over this time or still on trial?
  if [ "$endtime" -ge "$SECS_NOW" ]; then
    secs_check=$[$endtime-$SECS_NOW]
    proc_debug "Seconds left on trial: $secs_check"
    proc_calctime1
    . $theme
    if [ "$TIME_COUNTH" = "0 hours" ] || [ "$TIME_COUNTH" = "1 hours" ]; then
      TIMELEFT="$TRIAL_TIME_LAST_HOUR"
    else
      TIMELEFT="$TRIAL_TIME_LEFT"
    fi
  fi


  ## Go through each trial limit for user and see if hes currently over any limit."
  for rawdata in $TRIAL_LIMITS; do
    statnum="`echo "$rawdata" | cut -d ':' -f1`"
    sectionname="`echo "$rawdata" | cut -d ':' -f2`"
    pass_limit="`echo "$rawdata" | cut -d ':' -f3`"

    ## Match the statnum with the stats for this section (taken from the userfiles MONTHUP).
    cur_limit_num=0
    unset cur_limit
    for statsmb_value in $statsmb; do 
      if [ "$statnum" = "$cur_limit_num" ]; then
        cur_limit="$statsmb_value"
      fi
      cur_limit_num=$[$cur_limit_num+1]
    done

    if [ -z "$cur_limit" ]; then
      cur_limit="0"
    fi

##
    if [ -z "$TRIAL_DAYS_LEFT" ]; then
      TRIAL_DAYS_LEFT="`echo "$TIME_COUNTD" | cut -d ' ' -f1`"
      if [ -z "$TRIAL_DAYS_LEFT" ]; then
        TRIAL_DAYS_LEFT="0"
      fi
      proc_debug "Number of days left: $TRIAL_DAYS_LEFT"
    fi

    if [ "$TRIAL_DAYS_LEFT" != "0" ]; then
      if [ "$cur_limit" != "0" ]; then
        per_day=$[$pass_limit-$cur_limit]
        proc_debug "$sectionname - still needs $per_day MB to pass."
        per_day=$[$per_day/$TRIAL_DAYS_LEFT]
        proc_debug "$sectionname - when splitting that by number of days: $per_day"
      else
        per_day=$[$pass_limit/$TRIAL_DAYS_LEFT]
        proc_debug "$sectionname - cur_limit is 0 so just split pass_limit with days left: $per_day"
      fi
    else
      per_day=$[$pass_limit-$cur_limit]
      proc_debug "$sectionname - No more days left on trial.. Just do pass_limit - cur_limit: $per_day"
    fi
##

    if [ "$pass_limit" = "0" ]; then
      pass_limit="DISABLED"
    fi

    proc_debug "Limit for $statnum:$sectionname is $pass_limit. $CURUSER is at $cur_limit so far."

    ## Set PASSED=TRUE if the user is over any of the limits.
    if [ "$pass_limit" != "DISABLED" ]; then
      . $theme

      if [ "$cur_limit" -ge "$pass_limit" ]; then
        PASSED="TRUE"

        if [ -z "$trial_line" ]; then
          trial_line="${TRIAL_LINE_ANNOUNCE_PASSED}"
        else
          trial_line="${trial_line}${TRIAL_LINE_ANNOUNCE_SEPERATOR}${TRIAL_LINE_ANNOUNCE_PASSED}"
        fi

      else

        if [ -z "$trial_line" ]; then
          trial_line="${TRIAL_LINE_ANNOUNCE_NOT_PASSED}"
        else
          trial_line="${trial_line}${TRIAL_LINE_ANNOUNCE_SEPERATOR}${TRIAL_LINE_ANNOUNCE_NOT_PASSED}"
        fi
      fi
    fi
  done
  ## Clean it up from excess spaces.
  trial_line="`echo $trial_line`"
}

## Procedure to show everyone on trial and how they are doing.
proc_triallist() {
  ## Get time in seconds now.
  SECS_NOW="`$DATEBIN +%s`"

  for rawdata in `$SQL "select username,endtime,extratime from $SQLTB where active = '1'" | awk '{print $1"^"$2"^"$3}'`; do
    CURUSER="`echo "$rawdata" | cut -d '^' -f1`"
    endtime="`echo "$rawdata" | cut -d '^' -f2`"
    extratime="`echo "$rawdata" | cut -d '^' -f3`"
    proc_debug "Checking status for $CURUSER"
    if [ ! -e "$USERSDIR/$CURUSER" ]; then
      echo "$CURUSER - Not on site but active in DB."
    else

      unset TIME_COUNTH
      secs_check=$[$endtime-$SECS_NOW]
      proc_debug "Seconds left on trial: $secs_check"
      if [ "$secs_check" -gt "0" ]; then
        proc_calctime1
      fi

      proc_check_trial
      proc_get_groups

      . $theme
      if [ "$TIME_COUNTH" ]; then
        echo "$TLIMIT_ANNOUNCE_TIME_LEFT"
      else
        echo "$TLIMIT_ANNOUNCE_NO_TIME"
      fi
    fi
  done
  if [ -z "$CURUSER" ]; then
    . $theme
    echo "$TLIMIT_ANNOUNCE_NO_USERS"
  fi
}

## Procedure for checking if a user is deleted (flag 6). Returns USER_DELETE=TRUE/FALSE
proc_check_delete() {
  unset USER_DELETED
  if [ -z "$CURUSER" ]; then
    echo "Internal error. No CURUSER passed to proc_check_delete."
    exit 0
  fi

  if [ "`grep "^FLAGS " $USERSDIR/$CURUSER | cut -d ' ' -f2 | grep "6"`" ]; then
    USER_DELETED="TRUE"
  else
    USER_DELETED="FALSE"
  fi
  proc_debug "Checking if $CURUSER is deleted: USER_DELETED=$USER_DELETED"
}

proc_crontrial() {
  unset rawdata

  ## Get time in seconds now, plus two seconds incase we run at the exact time.
  SECS_NOW=$[`$DATEBIN +%s`+2]

  ## Check trials. For each user with active 1 ...
  for rawdata in `$SQL "select username, endtime, extratime from $SQLTB where active = '1'" | awk '{print $1"^"$2"^"$3}'`; do
    CURUSER="`echo "$rawdata" | cut -d '^' -f1`"
    endtime="`echo "$rawdata" | cut -d '^' -f2`"
    extratime="`echo "$rawdata" | cut -d '^' -f3`"
    proc_debug "Checking $CURUSER with endtime: $endtime"

    ## Check if the user is delled. Sets USER_DELETED=TRUE if so.
    proc_check_delete

    if [ "$USER_DELETED" = "TRUE" ]; then
      proc_debug "Skipping check of $CURUSER as hes deleted"
    else
      ## Check how this user is doing. Returns PASSED=TRUE if the user passed.
      proc_check_trial

      ## Check if endtime is greater or equal to the time now. if so, the users timelimit if up.
      if [ "$endtime" -ge "$SECS_NOW" ]; then
        secs_check=$[$endtime-$SECS_NOW]
        proc_debug "Seconds left on trial: $secs_check"
        proc_calctime1
        if [ "$PASSED" = "TRUE" ]; then
          proc_debug "$CURUSER has not passed his endtime. - $TIME_COUNTH $trial_line"
          proc_trial_passed
        else
          proc_debug "$CURUSER has not passed his endtime. - $TIME_COUNTH $trial_line"
        fi
      else
        proc_get_groups
        if [ "$PASSED" = "TRUE" ]; then
          proc_debug "$CURUSER/$CURPRIGROUP is passed the entime. - PASSED $trial_line"
          proc_trial_passed
        else
          proc_debug "$CURUSER/$CURPRIGROUP is passed the entime. PASSED $trial_line"
          proc_trial_failed
        fi
      fi

      proc_debug ""
    fi
  done
  if [ -z "$rawdata" ]; then
    proc_debug "No users on trial."
  fi
}

## This one is ran in crontab.
proc_cronquota() {
  sleep 2 ## Security.

  if [ "`$DATEBIN +%d`" != "01" ]; then
    if [ "$TEST" = "TRUE" ] && [ "$DEBUG" = "TRUE" ]; then
      proc_debug "Not the first of the month. Continuing anyway since TEST is TRUE"
    else
      exit 0
    fi
  fi
  if [ "`$DATEBIN +%H`" != "00" ]; then
    if [ "$TEST" != "TRUE" ]; then
      echo "ERROR: tur-trial3.sh qcron should be crontabbed at 0 0 * * * using the midnight script."
      exit 0      
    else
      proc_debug "Test mode, so ignoring that the hour is not 00. Should be crontabbed at 0 0 * * * using a midnight.sh script."
    fi
  fi

  ## Remove any previous temp files.
  rm -f /tmp/tt3.*

  ## Update exclude and ratings tables
  if [ "$TEST" != "TRUE" ]; then
    proc_update_excludelist
  else
    proc_debug "Skipping update of exclude/ranking tables as this is a test."
  fi

  cd $USERSDIR
  for CURUSER in `grep "^FLAGS " * | cut -d ':' -f1 | egrep -v "default\.|\.lock"`; do
    unset trial_line; unset PASSED; unset rawdata; unset passed_cause_of_top_up; unset failed_cause_of_top_up
    unset MONTH_EXCLUDED; unset extratime; unset ON_VACATION

    proc_debug "Checking quota on $CURUSER"

    if [ "$QUOTA_ENABLED" = "FALSE" ]; then
      proc_debug "QUOTA_ENABLED is FALSE. Skipping cron quota"
      proc_logclean ""
      proc_logclean "Quota Stats for `date`"
      proc_logclean "QUOTA_ENABLED is FALSE. Skipping this month.."
    else

      ## Check if the user is excluded...
      rawdata="`$SQL "select excluded from $SQLTB_EXCLUDED where username = '$CURUSER'"`"
      case $rawdata in
        1) USER_EXCLUDED="TRUE" ;;
        0) USER_EXCLUDED="FALSE" ;;
        *) proc_is_user_excluded ;;
      esac

      ## Check if the user is excluded for the rest of the month.
      rawdata="`$SQL "select active, stats, extratime from $SQLTB where username = '$CURUSER'" | awk '{print $1"^"$2"^"$3}'`"
      active="`echo "$rawdata" | cut -d '^' -f1`"   
      if [ "$active" = "3" ]; then
        proc_debug "$CURUSER is excluded for the rest of the month."
        ## Also get the value from stats. Should be 0 or 1. If 0, we just change the active field.
        ## If 1, it means he wasnt in the database when put on exclude and we can wipe him from database.
        stats="`echo "$rawdata" | cut -d '^' -f2`"   
        extratime="`echo "$rawdata" | cut -d '^' -f3`"
        MONTH_EXCLUDED="TRUE"
      elif [ "$active" = "2" ]; then
        proc_debug "$CURUSER is permanently manually excluded."
        USER_EXCLUDED="TRUE"
      elif [ "$USER_EXCLUDED" = "TRUE" ]; then
         proc_debug "Skipping $CURUSER - excluded."
      fi

      ## If hes not excluded and does NOT have active 0 (forced quota), check if hes added this month (3.4 change).
      if [ "$USER_EXCLUDED" = "FALSE" ] && [ "$active" != "0" ]; then
        ## Check if the user was added this or last month. Skip if so. Returns THIS_MONTH=TRUE/FALSE
        ## and LAST_MONTH=TRUE/FALSE
        proc_check_this_month
        if [ "$THIS_MONTH" = "TRUE" ]; then
          proc_debug "Skipping check of $CURUSER as he was added this month."
          USER_EXCLUDED="TRUE"
        elif [ "$LAST_MONTH" = "TRUE" ]; then
          proc_debug "Skipping check of $CURUSER as he was added last month."
          USER_EXCLUDED="TRUE"
        fi
      fi

      if [ "$MONTH_EXCLUDED" = "TRUE" ]; then
        ## Check if were using tur-vacation interaction.
        proc_vacation
        if [ "$ON_VACATION" = "TRUE" ]; then
          proc_debug "Seems like it. Leaving active 3 in database."
          if [ "$extratime" -gt "0" ]; then
            proc_debug "Warning. Extratime is $extratime but user is on vacation. Reseting extratime to 0."
            $SQL "update $SQLTB set extratime = '0' where username = '$CURUSER'"           
          fi
        else
          if [ "$extratime" -gt "0" ]; then
            new_extratime=$[$extratime-1]
            if [ "$TEST" != "TRUE" ]; then
              $SQL "update $SQLTB set extratime = '$new_extratime' where username = '$CURUSER'"           
              proc_debug "$CURUSER is excluded for $new_extratime more months."
              echo "$CURUSER is excluded from quota for $new_extratime more months." >> /tmp/tt3.quota.passed.tmp
            else
              proc_debug "$CURUSER is excluded for $new_extratime more months (test)."
            fi
          else
            if [ "$TEST" != "TRUE" ]; then
              if [ "$stats" = "0" ]; then
                proc_debug "Not excluded anymore. Setting active = 0"
                $SQL "update $SQLTB set active = '0' where username = '$CURUSER'"
              else
                proc_debug "Not excluded anymore. Wiping user from database"
                proc_wipe
              fi
              echo "$CURUSER is excluded this month, but enabled for quota the next." >> /tmp/tt3.quota.passed.tmp
            else
              if [ "$stats" = "0" ]; then
                proc_debug "Removing month exclude. Setting active = 0 (test)"
              else
                proc_debug "Removing month exclude. Wiping user from database (test)"
              fi
            fi
          fi
        fi
      fi

      if [ "$USER_EXCLUDED" = "FALSE" ]; then
        ## Check how this user is doing. Returns PASSED=TRUE if the user passed.
        proc_check_quota
        proc_get_groups

        if [ "$PASSED" = "TRUE" ]; then
          proc_debug "$CURUSER/$CURPRIGROUP has passed this month. $trial_line"
          if [ "$TOP_UPLOADERS" != "TRUE" ]; then
            proc_quota_passed
          else
            proc_get_user_pos_nice
            if [ "$TOP_UP_PASSED" = "FALSE" ]; then
              proc_debug "$CURUSER/$CURPRIGROUP has FAILED this Monthup. $POSITION_NICE"
              failed_cause_of_top_up="TRUE"
              proc_quota_failed
            else
              proc_debug "$CURUSER/$CURPRIGROUP has passed this Monthup. $POSITION_NICE"
              passed_cause_of_top_up="TRUE"
              proc_quota_passed
            fi
          fi

        else
          proc_debug "$CURUSER/$CURPRIGROUP has not passed this month. $trial_line"
          proc_quota_failed
        fi
      fi

    fi
    proc_debug ""
  done

  ## Create the logfile if LOG is defined and TEST is not TRUE.
  if [ -e "/tmp/tt3.quota.passed.tmp" ] || [ -e "/tmp/tt3.quota.failed.tmp" ]; then
    if [ -z "$LOG" ] || [ "$TEST" = "TRUE" ]; then
      proc_debug "Not logging this. Either LOG is disabled or TEST is TRUE"
      rm -f "/tmp/tt3.quota.passed.tmp"
      rm -f "/tmp/tt3.quota.failed.tmp"
    else
      proc_logclean ""
      proc_logclean "Quota Stats for `date`"
      if [ -e "/tmp/tt3.quota.passed.tmp" ]; then
        proc_logclean "#--[ Passed users ]----------------------#"
        cat "/tmp/tt3.quota.passed.tmp" >> $LOG
        proc_logclean ""
        rm -f "/tmp/tt3.quota.passed.tmp"
      fi
      if [ -e "/tmp/tt3.quota.failed.tmp" ]; then
        proc_logclean "#--[ Failed users $LOG_CREDS $LOG_CREDS2 $LOG_FLAGS ]----------------------#"
        cat "/tmp/tt3.quota.failed.tmp" >> $LOG
        rm -f "/tmp/tt3.quota.failed.tmp"
      fi
      proc_logclean ""
    fi
  fi
}

## Used to create actionfiles to sync MSS slaves.
proc_mss_sync() {
  if [ "$MSS_CONFIG" ]; then
    if [ ! -e "$MSS_CONFIG" ]; then
      proc_debug "Error.MSS_CONFIG defined but $MSS_CONFIG was not found."
      proc_log "Error.MSS_CONFIG defined but $MSS_CONFIG was not found."
    else
      SLAVES="`grep "^SLAVES=" $MSS_CONFIG | cut -d '=' -f2 | tr -d '"'`"
      proc_debug "Sending SYNC BASIC $CURUSER to $SLAVES"
      for slave in $SLAVES; do
        echo "SYNC BASIC $CURUSER" >> /glftpd/etc/$slave.actions
      done
    fi
  fi
}

## Used to check if the user is in the vacationgroup and return ON_VACATION=TRUE/FALSE
## Only used if VACATION_GROUP is set.
proc_vacation() {
  if [ "$VACATION_GROUP" ]; then
    if [ "`grep "^GROUP\ $VACATION_GROUP" "$USERSDIR/$CURUSER"`" ]; then
      proc_debug "proc_vacation reports that $CURUSER is on vacation."
      ON_VACATION="TRUE"
    else
      ON_VACATION="FALSE"
    fi
  else
    ON_VACATION="FALSE"
  fi
}


## This is execute if a user passed quota.
proc_quota_passed() {
  unset passed_section; unset MONTHS

  echo "$CURUSER passed quota: $trial_line" >> /tmp/tt3.quota.passed.tmp

  if [ "$passed_cause_of_top_up" = "TRUE" ]; then
    echo "$CURUSER passed Monthup: $POSITION_NICE" >> /tmp/tt3.quota.passed.tmp
  fi

  ## If the user passed multiple sections.
  if [ "$PASS_SECTIONS_EXCLUDE" ] && [ "$PASS_SECTIONS_EXCLUDE" != "0" ]; then
    passed_sections="0"
    for passd in $PASS_DATA; do
      if [ "`echo "$passd" | grep "\:P"`" ]; then
        passed_sections=$[$passed_sections+1]
      fi
    done
    if [ "$passed_sections" -ge "$PASS_SECTIONS_EXCLUDE" ]; then
      passed_section="true"
      if [ "$TEST" != "TRUE" ]; then
        SACTIVE="3"; ANNOUNCE="FALSE"; proc_addquota
        proc_debug "$CURUSER passed $passed_sections sections and gets excluded next month."
        echo "$CURUSER passed $passed_sections sections and gets excluded 1 month." >> /tmp/tt3.quota.passed.tmp
        . $theme
        proc_gllog "$GLLOG_PASSED_MULTIPLE_SECTIONS"
      else
        proc_debug "$CURUSER passed $passed_sections sections and gets excluded next month (test)."
      fi
    fi
    unset passed_sections; unset SACTIVE
  fi


  ## If the user passed multiple times in the same section.
  if [ "$PASS_TIMES_EXCLUDE" ] && [ "$PASS_TIMES_EXCLUDE" != "0" ]; then
    if [ "$times_over" -ge "$PASS_TIMES_EXCLUDE" ]; then

      ## If the user passed extra both in the sections AND the limits and PASS_TIMES_EXCLUDE isnt 0..
      if [ "$passed_section" = "true" ] && [ "$PASS_BOTH_EXCLUDE_MONTHS" != "0" ]; then
        ## Remove one from months so we can present number of months.
        MONTHS=$[$PASS_BOTH_EXCLUDE_MONTHS-1]

        if [ "$TEST" != "TRUE" ]; then 
          SACTIVE="3"; MONTHS="$PASS_BOTH_EXCLUDE_MONTHS"; ANNOUNCE="FALSE"; proc_addquota

          proc_debug "$CURUSER ALSO passed the quota limit $times_over times in $times_over_sec. Exclude for $PASS_BOTH_EXCLUDE_MONTHS months."
          echo "$CURUSER ALSO passed the quota limit $times_over times in $times_over_sec. Exclude $PASS_BOTH_EXCLUDE_MONTHS months." >> /tmp/tt3.quota.passed.tmp
          . $theme
          proc_gllog "$GLLOG_PASSED_MULTIPLE_BOTH"
        else
          proc_debug "$CURUSER ALSO passed the quota limit $times_over times in $times_over_sec. Exclude for $PASS_BOTH_EXCLUDE_MONTHS ( set: $MONTHS ) months (test)."
        fi

      else

        ## Either the user passed only the limit a few times or PASS_TIMES_EXCLUDE is 0.
        if [ "$passed_section" != "true" ]; then
          if [ "$TEST" != "TRUE" ]; then
            SACTIVE="3"; ANNOUNCE="FALSE"; proc_addquota
            proc_debug "$CURUSER passed the quota limit $times_over times in $times_over_sec. Exclude next month."
            echo "$CURUSER passed the quota limit $times_over times in $times_over_sec. Exclude next month." >> /tmp/tt3.quota.passed.tmp
            . $theme
            proc_gllog "$GLLOG_PASSED_MULTIPLE_TIMES"
          else
            proc_debug "$CURUSER passed the quota limit $times_over times in $times_over_sec. Exclude next month (test)."
          fi
        fi
      fi
    fi
  fi

}

## This is executed if the user failed quota.
proc_quota_failed() {
  unset QFAIL_SET_CREDITS_CURRENT

  if [ -z "$CURUSER" ]; then
    echo "Internal error. No CURUSER supplied to proc_quota_failed."
    exit 0
  fi
  ## Remove old file if there is one.
  if [ -e "/tmp/tt3.$CURUSER.failed" ]; then
    rm -f "/tmp/tt3.$CURUSER.failed"
  fi

  if [ "$QFAIL_SET_CREDITS" ]; then
    ## If its not 0, set KB instead.
    if [ "$QFAIL_SET_CREDITS" != "0" ]; then
      QFAIL_SET_CREDITS_CURRENT=$[$QFAIL_SET_CREDITS*1024]
    else
      QFAIL_SET_CREDITS_CURRENT="0"
    fi
    CUR_EXTRA_CREDS="`grep "^CREDITS " "$USERSDIR/$CURUSER" | cut -d ' ' -f3-`"
    grep -v "^CREDITS " "$USERSDIR/$CURUSER" > /tmp/tt3.$CURUSER.failed
    echo "CREDITS $QFAIL_SET_CREDITS_CURRENT $CUR_EXTRA_CREDS" >> /tmp/tt3.$CURUSER.failed
    LOG_CREDS="- CS:$QFAIL_SET_CREDITS_CURRENT"
    if [ "$TEST" = "TRUE" ]; then
      proc_debug "$CURUSER got credits: $QFAIL_SET_CREDITS_CURRENT - Just a test. Would-be file: /tmp/tt3.$CURUSER.failed"
    else

      if [ "$MSGS" ]; then
        CUR_CREDS="`grep "^CREDITS " "$USERSDIR/$CURUSER" | cut -d ' ' -f2`"
        CUR_CREDS=$[$CUR_CREDS/1024]
        echo "" >> $MSGS/$CURUSER
        echo "!H------------------------------------------------------------------------------!0" >> $MSGS/$CURUSER
        echo "!HYou missed quota, hence your credits went from $CUR_CREDS MB to $QFAIL_SET_CREDITS MB!0" >> $MSGS/$CURUSER
        echo "!HStats: $trial_line !0" >> $MSGS/$CURUSER
        if [ "$failed_cause_of_top_up" = "TRUE" ]; then
          echo "!HAlthough, the reason were the top-up: $POSITION_NICE !0" >> $MSGS/$CURUSER
        fi
        chmod 666 $MSGS/$CURUSER
      fi

      cp -f "/tmp/tt3.$CURUSER.failed" "$USERSDIR/$CURUSER"
      rm -f "/tmp/tt3.$CURUSER.failed"

    fi
  fi
 
  if [ "$QFAIL_LOWER_CREDITS" ] && [ "$QFAIL_LOWER_CREDITS" != "0" ]; then

    ## Grab current credits
    CUR_CREDS="`grep "^CREDITS " "$USERSDIR/$CURUSER" | cut -d ' ' -f2`"
    CUR_CREDS_MB=$[$CUR_CREDS/1024]

    CUR_EXTRA_CREDS="`grep "^CREDITS " "$USERSDIR/$CURUSER" | cut -d ' ' -f3-`"

    if [ "$QFAIL_LOWER_CREDITS" -ge "$CUR_CREDS_MB" ]; then
      NEW_CREDS_MB="0"
    else
      NEW_CREDS_MB=$[$CUR_CREDS_MB-$QFAIL_LOWER_CREDITS]
    fi

    if [ "$NEW_CREDS_MB" ]; then
      NEW_CREDS_KB=$[$NEW_CREDS_MB*1024]
      grep -v "^CREDITS " "$USERSDIR/$CURUSER" > /tmp/tt3.$CURUSER.failed
      echo "CREDITS $NEW_CREDS_KB $CUR_EXTRA_CREDS" >> /tmp/tt3.$CURUSER.failed
      LOG_CREDS2="- LC:$QFAIL_LOWER_CREDITS"
      if [ "$TEST" = "TRUE" ]; then
        proc_debug "$CURUSER got credits: $NEW_CREDITS from $CUR_CREDS_MB - Just a test. Would-be file: /tmp/tt3.$CURUSER.failed"
      else
        if [ "$MSGS" ]; then
          echo "" >> $MSGS/$CURUSER
          echo "!H------------------------------------------------------------------------------!0" >> $MSGS/$CURUSER
          echo "!HYou missed quota, hence your credits went from $CUR_CREDS MB to $QFAIL_SET_CREDITS MB!0" >> $MSGS/$CURUSER
          echo "!HStats: $trial_line !0" >> $MSGS/$CURUSER
          if [ "$failed_cause_of_top_up" = "TRUE" ]; then
            echo "!HAlthough, the reason were the top-up: $POSITION_NICE !0" >> $MSGS/$CURUSER
          fi
          chmod 666 $MSGS/$CURUSER
        fi

        cp -f "/tmp/tt3.$CURUSER.failed" "$USERSDIR/$CURUSER"
        rm -f "/tmp/tt3.$CURUSER.failed"
      fi
    fi
  fi

  if [ "QFAIL_SET_FLAGS" ]; then
    CURFLAGS="`grep "^FLAGS " "$USERSDIR/$CURUSER" | cut -d ' ' -f2`"
    grep -v "^FLAGS " "$USERSDIR/$CURUSER" > /tmp/tt3.$CURUSER.failedf
    echo "FLAGS $QFAIL_SET_FLAGS$CURFLAGS" >> /tmp/tt3.$CURUSER.failedf
    LOG_FLAGS="- Flag:$QFAIL_SET_FLAGS"
    if [ "$TEST" = "TRUE" ]; then
      proc_debug "$CURUSER got flag(s): $CURFLAGS$QFAIL_SET_FLAGS - Just a test. Would-be file: /tmp/tt3.$CURUSER.failedf"
    else
      cp -f "/tmp/tt3.$CURUSER.failedf" "$USERSDIR/$CURUSER"
      rm -f "/tmp/tt3.$CURUSER.failedf"

      ## Check if flag 6 is given. If so, if BYEFILES is defined, send a goodbye message to the user.
      if [ "`echo "$QFAIL_SET_FLAGS" | grep "6"`" ]; then
        if [ "$BYEFILES" ]; then
          echo "You were deleted because of failed Quota." > $BYEFILES/$CURUSER.bye
          echo "Stats: $trial_line" >> $BYEFILES/$CURUSER.bye
          if [ "$failed_cause_of_top_up" = "TRUE" ]; then
            echo "Although, the reason were the top-up: $POSITION_NICE" >> $BYEFILES/$CURUSER.bye
          fi
          chmod 666 $BYEFILES/$CURUSER.bye
        fi
      fi

    fi
  fi

  if [ "$QFAIL_BACK_TO_TRIAL" = "TRUE" ]; then
    if [ "$TEST" = "TRUE" ]; then
      proc_debug "Adding $CURUSER on trial again with default values (test)."
    else

      proc_debug "Adding $CURUSER on trial again with default values."
      if [ "`$SQL "select username from $SQLTB where username = '$CURUSER'"`" ]; then
        RUNMODE="WIPE"
        ANNOUNCE="FALSE"
        proc_wipe
      fi
      proc_addtrial
    fi
  fi

  ## Announce to glftpd.log, if TEST isnt TRUE
  if [ "$TEST" != "TRUE" ]; then
    . $theme

    proc_gllog "$GLLOG_FAILED_QUOTA"
    if [ "$failed_cause_of_top_up" = "TRUE" ]; then
      proc_gllog "$GLLOG_FAILED_TOPUP"
    fi
  fi

  ## Log it in the failed file, once again, if TEST isnt TRUE.
  if [ "$failed_cause_of_top_up" = "TRUE" ]; then
    echo "$CURUSER passed quota: $trial_line but missed the monthup: $POSITION_NICE" >> /tmp/tt3.quota.failed.tmp
  else
    echo "$CURUSER failed quota: $trial_line" >> /tmp/tt3.quota.failed.tmp
  fi

  ## Make actionfile for MSS.
  if [ "$TEST" != "TRUE" ]; then
    proc_mss_sync
  fi
}


proc_quota_tlimit() {
  ## make a new tlimit for when moving from trial to quota."
  unset new_tlimit
  for rawdata in $QUOTA_SECTIONS; do
    new_tlimit="$new_tlimit 0"
  done
  new_tlimit="`echo $new_tlimit`"
}    


## Executed when a user passes trial.
proc_trial_passed() {
  proc_debug "Entering proc_trial_passed for $CURUSER"
  if [ -z "$CURUSER" ]; then
    echo "Internal error. No CURUSER passed to proc_trial_passed"
    exit 0
  fi
  . $theme

  if [ "$TEST" != "TRUE" ]; then
    proc_log "$CURUSER PASSED trial with $trial_line"
    proc_gllog "$GLLOG_PASSED_TRIAL"
  fi

  ## Wipe the user from the database and add him excluded for the rest of the month.
  ANNOUNCE="FALSE"
  proc_wipe
  SACTIVE="3"
  proc_addquota
}


## Executed when a user fails trial.
proc_trial_failed() {
  proc_debug "Entering proc_trial_failed for $CURUSER"
  if [ -z "$CURUSER" ]; then
    echo "Internal error. No CURUSER passed to proc_trial_failed"
    exit 0
  fi

  ## Remove user from the database.
  ANNOUNCE="FALSE"
  proc_wipe

  ## Check if the user is deleted. If he isnt, we add flag 6 to him.
  proc_check_delete
  if [ "$USER_DELETED" = "TRUE" ]; then
    proc_log "$CURUSER FAILED with $trial_line - Already got flag 6 though."
  else
    ## Add flag 6 to user.  
    CURFLAGS="`grep "^FLAGS " "$USERSDIR/$CURUSER" | cut -d ' ' -f2`"
    if [ -z "$CURFLAGS" ]; then
      echo "ERROR: Could not get current flags for $CURUSER in proc_trial_failed"
      proc_log "ERROR: Could not get current flags for $CURUSER in proc_trial_failed"
    else
      NEWFLAGS="6$CURFLAGS"
      proc_debug "Old flags for $CURUSER: $CURFLAGS - New flags: $NEWFLAGS"
    fi
    grep -v "^FLAGS " "$USERSDIR/$CURUSER" > /tmp/$CURUSER.tt3.tmp
    echo "FLAGS $NEWFLAGS" >> /tmp/$CURUSER.tt3.tmp
    if [ "$TEST" != "TRUE" ]; then
      cp -f "/tmp/$CURUSER.tt3.tmp" "$USERSDIR/$CURUSER"
      rm -f "/tmp/$CURUSER.tt3.tmp"
      proc_log "$CURUSER FAILED trial with $trial_line - Oldflags: $CURFLAGS Newflags: $NEWFLAGS"
      . $theme
      proc_gllog "$GLLOG_FAILED_TRIAL"

      ## Give the user a nice byemessage.
      if [ "$BYEFILES" ]; then
        echo "You were deleted because of failed Trial." > $BYEFILES/$CURUSER.bye
        echo "Stats: $trial_line" >> $BYEFILES/$CURUSER.bye
        chmod 666 $BYEFILES/$CURUSER.bye
      fi
          
    else
      proc_debug "TEST TRUE. No change for user. Would be userfile in: /tmp/$CURUSER.tt3.tmp"
    fi
  fi

  ## Make actionfile for MSS.
  proc_mss_sync
}


## Procedure for getting all excluded groups.
proc_check_excluded_groups() {
 if [ -z "$EXCLUDED_GROUPS" ]; then
   if [ "$QUOTA_EXCLUDED_GROUPS" ]; then
     EXCLUDED_GROUPS=" $QUOTA_EXCLUDED_GROUPS "
   fi
   if [ "$QUOTA_EXCLUDED_AFFILS_DIRS" ]; then
     for predir in $QUOTA_EXCLUDED_AFFILS_DIRS; do
       if [ "$RUN_MODE" = "irc" ]; then
         predir="$GLROOT$predir"
       fi
       if [ ! -d "$predir" ]; then
         echo "Error. predir $predir defined in QUOTA_EXCLUDED_AFFILS_DIRS does not exist."
       else
         cd "$predir"
         for excluded_group in `ls -1`; do
           if [ -z "`echo "$EXCLUDED_GROUPS" | grep "\ $excluded_group\ "`" ]; then
             EXCLUDED_GROUPS=" $EXCLUDED_GROUPS $excluded_group "
           fi
         done
       fi
     done
   fi
   EXCLUDED_GROUPS="`echo $EXCLUDED_GROUPS`"

   ## Make em searchable with egrep.
   for excluded_group in $EXCLUDED_GROUPS; do
     if [ "$GL_VERSION" = "1" ]; then
       if [ -z "$EXCLUDED_GROUPS_2" ]; then
         EXCLUDED_GROUPS_2="^GROUP\ $excluded_group$|^PRIVATE\ $excluded_group$"
       else
         EXCLUDED_GROUPS_2="$EXCLUDED_GROUPS_2|^GROUP\ $excluded_group$|^PRIVATE\ $excluded_group$"
       fi
     else
       if [ -z "$EXCLUDED_GROUPS_2" ]; then
         EXCLUDED_GROUPS_2="^GROUP\ $excluded_group |^PRIVATE\ $excluded_group "
       else
         EXCLUDED_GROUPS_2="$EXCLUDED_GROUPS_2|^GROUP\ $excluded_group |^PRIVATE\ $excluded_group "
       fi
     fi
   done
   EXCLUDED_GROUPS_2="`echo $EXCLUDED_GROUPS_2`"
 fi
}


## Procedure to check if the user is excluded based on group.
## Returns EXCLUDED_USER=TRUE/FALSE       
## Only executed for quota and if the user is NOT currently in the database.
## If he is, it goes by the active field for that user.
proc_check_excluded() {
  if [ -z "$CURUSER" ]; then
    echo "Internal error: No CURUSER passed to proc_check_excluded."
    exit 0
  fi

  unset EXCLUDED_USER; unset EXCLUDED_BY

  ## Get all excluded groups in a list.
  proc_check_excluded_groups
  if [ "`egrep "$EXCLUDED_GROUPS_2" "$USERSDIR/$CURUSER"`" ]; then
    EXCLUDED_USER="TRUE"
    ## Find out which group hes excluded by..
    for group in $EXCLUDED_GROUPS; do
      if [ "`egrep "^GROUP $group|^PRIVATE $group" "$USERSDIR/$CURUSER"`" ]; then
        if [ "$EXCLUDED_BY" ]; then
          EXCLUDED_BY="$EXCLUDED_BY/$group"
        else
          EXCLUDED_BY="$group"
        fi
        proc_debug "Found group $group for $CURUSER which is excluded"
      fi
    done
  else
    EXCLUDED_USER="FALSE"
  fi
  proc_debug "$CURUSER excluded by group? : $EXCLUDED_USER ($EXCLUDED_BY)"
}


## This one is used to update the list of excluded users in table excluded (SQLTB_EXCLUDED).
## Also used to update the list of rankings in table ranking ($SQLTB_RANK).
proc_update_excludelist() {

  ## Dont run update if its within one hour of the new month."
  if [ "$UPDATE_ONLY" = "TRUE" ]; then
    proc_debug "This is an update only. Checking if its within an hour of the last day of the month."
    if [ "`$DATEBIN -d "+1 day" +%d`" = "01" ]; then
      if [ "`$DATEBIN +%H`" = "23" ] && [ "`$DATEBIN +%M`" -gt "30" ]; then
        proc_debug "Skipping 'tur-trial3.sh update' as this is the last 30 minutes of the last month."
        exit 0
      fi
    elif [ "`$DATEBIN +%d`" = "01" ]; then
      if [ "`$DATEBIN +%H`" = "00" ] && [ "`$DATEBIN +%M`" -lt "30" ]; then
        proc_debug "Skipping 'tur-trial3.sh update as this is the first 30 minutes of the new month."
        exit 0
      fi
    fi
  fi

  cd $USERSDIR

  ## Clean out users everywhere that does not exist anymore.
  TABLE_LIST="$SQLTB $SQLTB_EXCLUDED $SQLTB_RANK $SQLTB_PASSED"
  for table in $TABLE_LIST; do
    proc_debug "Checking for leftover data in table: $table"
    for CURUSER in `$SQL "select username from $table"`; do
      if [ ! -e "$USERSDIR/$CURUSER" ]; then
        proc_debug "Removing $CURUSER from table $table - Dosnt exist anymore."
        $SQL "delete from $table where username = '$CURUSER'"
      fi
    done
  done
  proc_debug ""
  proc_debug "Starting update of tables \"$SQLTB_EXCLUDED\" and \"$SQLTB_RANK\""

  ## Remove any old output from stats if its there.
  proc_debug "Removing old stats files /tmp/tt3.stats*"
  proc_debug ""
  rm -f /tmp/tt3.stats*

  ## Start updating excluded and ranking tables.
  for CURUSER in `grep "^FLAGS " * | cut -d ':' -f1 | egrep -v "default\.user|\.lock"`; do

    ## New way of checking exclude. Goes through everything itself..
    proc_is_user_excluded
    if [ "$USER_EXCLUDED" = "TRUE" ]; then
      VALUE="1"
    else
      VALUE="0"
    fi

    excluded="`$SQL "select excluded from $SQLTB_EXCLUDED where username = '$CURUSER'"`"
    if [ -z "$excluded" ]; then
      $SQL "insert into $SQLTB_EXCLUDED (username, excluded) VALUES ('$CURUSER', '$VALUE')"
      proc_debug "-- Inserting $CURUSER into excluded table with status: $VALUE"
    elif [ "$excluded" != "$VALUE" ]; then
      $SQL "update $SQLTB_EXCLUDED set excluded = '$VALUE' where username = '$CURUSER'"
      proc_debug "-- Updating excluded status for $CURUSER from $excluded to $VALUE"
    fi

    proc_recalctlimit

    ## Check for vacation interaction.
    if [ "$VACATION_GROUP" ]; then
      proc_vacation
      ## Continue if the user really is in the vacation group.
      if [ "$ON_VACATION" = "TRUE" ]; then
        ## Get the current active status
        active="`$SQL "select active from $SQLTB where username = '$CURUSER'"`"
        ## No active status returned. User isnt in the database so add him
        if [ -z "$active" ]; then
          proc_debug "$CURUSER is in group $VACATION_GROUP - Adding with active 3 to database."
          SACTIVE="3"
          proc_addquota

        elif [ "$active" = "1" ]; then
          proc_debug "$CURUSER is in group $VACATION_GROUP. Should get active 3 but he got active 1 now."
          proc_log "Warning. $CURUSER is on vacation AND on trial. This dosnt look good. Assuming trial."
        
        ## User is in the database, but dosnt have active 3. Set it.
        elif [ "$active" != "3" ]; then
          proc_debug "$CURUSER is in group $VACATION_GROUP - Currently have active $active - setting 3 instead."
          $SQL "update $SQLTB set active = '3' where username = '$CURUSER'"
        fi
      fi
    fi

    ## If both TOP_UPLOADERS and SHOW_MONTHUP is FALSE, there is no need for the ranking table
    ## to be updated. Skip it if so. Note that SHOW_MONTHUP is always TRUE if 
    ## TOP_UPLOADERS is TRUE, so no need to check TOP_UPLOADERS here. If SHOW_MONTHUP is FALSE its
    ## safe to say that TOP_UPLOADERS is FALSE as well.
    if [ "$SHOW_MONTHUP" = "TRUE" ]; then

      ## Only update the user_positions (ratings) if this isnt run from qcron and TOP_UPLOADERS
      ## is FALSE. Really no use since its just for show then.

      proc_create_exclude_list

      if [ "$RUNMODE" = "qcron" ]; then
        if [ "$TOP_UPLOADERS" = "TRUE" ]; then
          proc_get_user_position
        fi
      else
        proc_get_user_position
      fi

    fi
  done
  
  ## Dont update the passed table if UPDATE_PASSED_TABLE is TRUE and 
  ## we're not running the montly quota check.

  if [ "$UPDATE_PASSED_TABLE" = "TRUE" ] && [ "$RUNMODE" != "qcron" ]; then
    proc_debug "---------"
    proc_debug "Starting update on the $SQLTB_PASSED table."
    for CURUSER in `$SQL "select username from $SQLTB_EXCLUDED where excluded = '0'"`; do
      proc_debug ""
      proc_debug "Checking $CURUSER"
      proc_check_quota
      if [ "$PASSED" = "TRUE" ]; then
        current_status="1"
      else
        current_status="0"
      fi

      ## Get current status from passed table
      passed_table_status="`$SQL "select passed from $SQLTB_PASSED where username = '$CURUSER'"`"
      if [ -z "$passed_table_status" ]; then
        proc_debug "-- Inserting $CURUSER into passed table with status: $current_status"
        $SQL "insert into $SQLTB_PASSED (username, passed) VALUES ('$CURUSER', '$current_status')"
      else
        if [ "$current_status" != "$passed_table_status" ]; then
          proc_debug "-- $CURUSER passed status is $current_status - Switching in passed table from $passed_table_status."
          $SQL "update $SQLTB_PASSED set passed = '$current_status' where username = '$CURUSER'"
        fi
      fi
    done

    ## Remove users from passed table if they are excluded from quota.
    for CURUSER in `$SQL "select username from $SQLTB_EXCLUDED where excluded = '1'"`; do
      if [ "`$SQL "select username from $SQLTB_PASSED where username = '$CURUSER'"`" ]; then
        proc_debug "Removing $CURUSER from $SQLTB_PASSED table - Not on quota right now."
        $SQL "delete from $SQLTB_PASSED where username = '$CURUSER'"
      fi
    done

  fi
  
  ## Clear up temp files if DEBUG isnt TRUE
  if [ "$DEBUG" != "TRUE" ]; then
    rm -f /tmp/tt3.stats*
  fi
}


proc_create_exclude_list() {
  if [ -z "$EXCLUDED_LIST_OF_USERS" ]; then
    for rawdata in `$SQL "select username from $SQLTB_EXCLUDED where excluded = '1'"`; do 

      ## Unset the list if its noneatall so its not added to the list of excluded users.
      if [ "$EXCLUDED_LIST_OF_USERS" = "noneatall" ]; then
        unset EXCLUDED_LIST_OF_USERS
      fi

      ## Create the list.
      if [ -z "$EXCLUDED_LIST_OF_USERS" ]; then
        EXCLUDED_LIST_OF_USERS="\]\^$rawdata\^"
      else
        EXCLUDED_LIST_OF_USERS="$EXCLUDED_LIST_OF_USERS|\]\^$rawdata\^"
      fi
    done

    ## Make a list of these users to a file if debug mode is on.
    if [ "$DEBUG" = "TRUE" ]; then
      echo "$EXCLUDED_LIST_OF_USERS" > /tmp/test.excluded.users
    fi
  fi
}

## Get list of which positions the user is in for each section.
## Only could non-excluded users.
## Returns $POSITION which is one num^max_num per section
proc_get_user_position() {
  unset POSITION
  unset RAN_QUOTA

#  if [ -z "$QUOTA_LIMITS" ]; then
#    echo "Error: proc_get_user_positions did not get QUOTA_LIMITS to work on."
#    exit 0
#  fi

  ## Get a nice egreppable list of excluded users from excluded table.
  ## This was moved out of this proc in 3.2 and the proc for 'update' runs
  ## proc_create_exclude_list instead.
  # if [ "$USER_EXCLUDED" = "FALSE" ]; then
  #   if [ -z "$EXCLUDED_LIST_OF_USERS" ] || [ "$EXCLUDED_LIST_OF_USERS" = "noneatall" ]; then
  #     proc_create_exclude_list
  #   fi
  #   if [ -z "$EXCLUDED_LIST_OF_USERS" ]; then
  #     proc_debug "Warning. proc_create_exclude_list got NO excluded users. Is this correct? Lets pretend that it is."
  #     EXCLUDED_LIST_OF_USERS="noneatall"
  #   fi
  # else
  #   ## DONT CHANGE THE nonatall WORD. Its used in the proc to see if it should be remade or not.
  #   EXCLUDED_LIST_OF_USERS="noneatall"
  #   proc_debug "This user is excluded/on trial. Grabbing the REAL values from the statsbinary"
  # fi

  unset POSITION
  PASSED_TOPUP="FALSE"

  for each in $QUOTA_SECTIONS; do
    unset POSITION_PASSED
    unset CURUSER_UPLOAD_NUM; unset rawdata
    secnum="`echo "$each" | cut -d ':' -f1`"
    secname="`echo "$each" | cut -d ':' -f2`"

    ## If the stats file for this section does not exist, create a new one.
    ## This highly speeds up the process instead of running 'stats' for each user times the number
    ## of sections.
    if [ ! -e "/tmp/tt3.stats.$secnum" ]; then
      $STATSBIN -um -s$secnum -x1000 | grep "^\[[0-9]" | tr ' ' '^' | grep -v "\^0MB\^Unknown\^" > /tmp/tt3.stats.$secnum

      ## Make a debug log of the stats per section.
      if [ "$DEBUG" = "TRUE" ]; then
        if [ -e "/tmp/tt3.stats.$secnum" ]; then
          cp /tmp/tt3.stats.$secnum /tmp/test.stats.$secnum
        else
          echo "Got no stats from running: $STATSBIN -um -s$secnum -x1000 | grep \"^\[[0-9]\" | tr ' ' '^'" > /tmp/test.stats.$secnum
        fi
      fi
      
      proc_debug "Creating the stats list to use. Put it in /tmp/tt3.stats.$secnum"

      ## Make sure a file was created. If not, theres probably no monthly stats yet. Create an empty file
      ## if so, so we do not get 'cat: no such file or directory' further down the script."
      if [ ! -e "/tmp/tt3.stats.$secnum" ]; then
        proc_debug "WARNING: Got no stats from $STATSBIN -um -s$secnum -x1000"
        proc_debug "Assuming there are no uploaders yet in that section."
        proc_log "WARNING: Got no stats from $STATSBIN -um -s$secnum -x1000 - Assuming there are no uploaders yet."
        touch /tmp/tt3.stats.$secnum
      fi
    fi

    ## If this limit for this section isnt disabled...
    if [ "`echo "$each" | cut -d ':' -f3`" != "DISABLED" ]; then

      ## If the file containing non-excluded users dosnt exist, create it.
      if [ ! -e "/tmp/tt3.stats.quota.$secnum" ]; then
        touch "/tmp/tt3.stats.quota.$secnum"
        ## Read the file containing the output from stats, from each section.
        proc_debug "Creating the stats list for non-excluded users only using /tmp/tt3.stats.$secnum."
        userpos=0
        ## This is for quota users, exclude the excluded users from list.
        for rawdata in `cat /tmp/tt3.stats.$secnum | egrep -v "$EXCLUDED_LIST_OF_USERS"`; do
          userpos=$[$userpos+1]
          MAX_UPLOAD_NUM_NONEX="$userpos"
          echo "$userpos^$rawdata" >> "/tmp/tt3.stats.quota.$secnum"
        done
      fi

      ## If the file containing non-excluded users dosnt exist, create it.
      if [ ! -e "/tmp/tt3.stats.all.$secnum" ]; then
        touch "/tmp/tt3.stats.all.$secnum"
        proc_debug "Creating the stats list for excluded users only using /tmp/tt3.stats.$secnum."
        userpos=0
        ## This is for users that are excluded only. So only list users that are excluded.
        for rawdata in `cat /tmp/tt3.stats.$secnum`; do
          userpos=$[$userpos+1]
          MAX_UPLOAD_NUM_EX="$userpos"
          echo "$userpos^$rawdata" >> "/tmp/tt3.stats.all.$secnum"
        done
      fi

      if [ "$USER_EXCLUDED" = "TRUE" ]; then
        proc_debug "Trying to find $CURUSER in excluded list for section $secnum."
        rawdata2="`grep "\]\^${CURUSER}\^" "/tmp/tt3.stats.all.$secnum" | head -n1`"
        ## Grab the user from the last line in the file for the section. That number is total users
        MAX_UPLOAD_NUM="`tail -n1 "/tmp/tt3.stats.all.$secnum" | cut -d '^' -f1`"
      else
        proc_debug "Trying to find $CURUSER in non-excluded list for section $secnum."
        rawdata2="`grep "\]\^${CURUSER}\^" "/tmp/tt3.stats.quota.$secnum" | head -n1`"
        ## Grab the user from the last line in the file for the section. That number is total users
        MAX_UPLOAD_NUM="`tail -n1 "/tmp/tt3.stats.quota.$secnum" | cut -d '^' -f1`"
      fi
      if [ -z "$MAX_UPLOAD_NUM" ]; then
        MAX_UPLOAD_NUM="0"
      fi

      if [ "$rawdata2" ]; then
        CURUSER_UPLOAD_NUM="`echo "$rawdata2" | cut -d '^' -f1`"
        proc_debug "Got $CURUSER in list. Position is $CURUSER_UPLOAD_NUM / $MAX_UPLOAD_NUM (uploaders so far)."
        rawdata="`echo "$rawdata2" | cut -d '^' -f2-`"
        unset rawdata2
      else
        proc_debug "No data found. Nothing uploaded in this section."
      fi

      NEED_TO_PASS="`echo "$each" | cut -d ':' -f4`"
      if [ -z "$NEED_TO_PASS" ]; then
        NEED_TO_PASS="0"
      fi

      if [ -z "$rawdata" ]; then
        CURUSER_UPLOAD_NUM="0"
#        MAX_UPLOAD_NUM="0"
        if [ "$NEED_TO_PASS" != "0" ]; then
          if [ -z "$POSITION_PASSED" ] && [ "$TOP_UPLOADERS" = "TRUE" ]; then
            POSITION_PASSED="F"
            proc_debug "Didnt pass $secname topup. Needs $NEED_TO_PASS, but so far there are no non-quota users in list."
          fi
        else
          POSITION_PASSED="D"
        fi
      elif [ -z "$CURUSER_UPLOAD_NUM" ]; then
        if [ "$TOP_UPLOADERS" = "TRUE" ]; then
          proc_debug "$CURUSER Didnt pass $secname topup. Needs $NEED_TO_PASS, but havent uploaded anything yet."
          POSITION_PASSED="F"  
        fi
        CURUSER_UPLOAD_NUM="0" 
      fi

      ## Delve deeper on whether they passed top-up or not, but dont do this if TOP_UPLOADERS is FALSE.
      ## Theres really no point as its just for presentation if its disabled."
      if [ "$NEED_TO_PASS" != "0" ] && [ "$TOP_UPLOADERS" = "TRUE" ]; then
        if [ "$CURUSER_UPLOAD_NUM" = "0" ]; then
          if [ -z "$POSITION_PASSED" ]; then
            POSITION_PASSED="F"
          fi
        else
          if [ "$NEED_TO_PASS" = "-1" ]; then
            ## If the topup is -1 for this section, check if the user passed quota for that section.
            ## If so, they also passed topup.
            ## Start with running the check if he passed. Need to save current secnum and secname values first
            ## or proc_check_quota will mess them up.
            secnumorg=$secnum; secnameorg="$secname"

            ## Only do this once for each user... Check how much they upped etc.
            ## unset at the start of this proc.
            if [ -z "$RAN_QUOTA" ]; then
              proc_check_quota
              RAN_QUOTA="TRUE"
            fi

            secnum=$secnumorg; secname="$secnameorg"; unset secnumorg; unset secnameorg

            ## If the user has $secnum:P ( from proc_quota_check ), he also passed here.
            if [ "`echo " $PASS_DATA " | grep "\ $secnum:P\ "`" ]; then
              PASSED_TOPUP="TRUE"
              POSITION_PASSED="P"
              proc_debug "$CURUSER passed quota in $secname and therefor passed topup in this section."
            else
              proc_debug "$CURUSER didnt pass quota in $secname and topup is -1 for this section. Didnt pass."
              if [ -z "$POSITION_PASSED" ]; then
                POSITION_PASSED="F"
              fi
            fi
             
          elif [ "$CURUSER_UPLOAD_NUM" -le "$NEED_TO_PASS" ]; then
            PASSED_TOPUP="TRUE"
            POSITION_PASSED="P"
            proc_debug "$CURUSER Passed $secname topup. Needs $NEED_TO_PASS and is at $CURUSER_UPLOAD_NUM"
          else
            if [ -z "$POSITION_PASSED" ]; then
              POSITION_PASSED="F"
            fi
            proc_debug "$CURUSER Didnt pass $secname topup. Needs $NEED_TO_PASS but only at $CURUSER_UPLOAD_NUM"
          fi
        fi
      else
        POSITION_PASSED="D"
        if [ "$TOP_UPLOADERS" = "TRUE" ]; then
          proc_debug "TopUP for section $secname is disabled in tur-trial3.conf"
        fi
      fi

      if [ -z "$POSITION" ]; then
        POSITION="$secnum^$CURUSER_UPLOAD_NUM^$MAX_UPLOAD_NUM^$NEED_TO_PASS^$POSITION_PASSED"
      else
        POSITION="$POSITION $secnum^$CURUSER_UPLOAD_NUM^$MAX_UPLOAD_NUM^$NEED_TO_PASS^$POSITION_PASSED"
      fi
    fi
  done

  proc_debug "$CURUSER's numbers are $POSITION"
  # proc_debug "Format: Section_Num^Current_Position^Total_Positions^Need_To_Pass^Passed_Status"

  if [ -z "`$SQL "select username from $SQLTB_RANK where username = '$CURUSER'"`" ]; then
    $SQL "insert into $SQLTB_RANK (username, rank) VALUES ('$CURUSER', '$POSITION')"
    proc_debug "Inserting into $SQLTB_RANK: $CURUSER - $POSITION"
  elif [ "`$SQL "select rank from $SQLTB_RANK where username = '$CURUSER'"`" != "$POSITION" ]; then
    proc_debug "Updating rank on $CURUSER to $POSITION"
    $SQL "update $SQLTB_RANK set rank = '$POSITION' where username = '$CURUSER'"
  fi
  proc_debug ""
}

proc_get_user_pos_nice() {
  if [ -z "$CURUSER" ]; then
    echo "Internal Error: proc_get_user_pos_nice did not get a CURUSER."
    exit 0
  fi  

  unset TOP_UP_PASSED; unset POSITION_NICE

  ## If the user is excluded, get a list of all users.
  ## Only do this for presentation purposes if TOP_UPLOADERS is FALSE.
  # (changed for 3.1beta4) # if [ "$EXCLUDED_USER" = "TRUE" ] && [ "$TOP_UPLOADERS" = "FALSE" ]; then

  ## If user is excluded and $TOP_UPLOADERS_EXCLUDED_SHOW_AS_QUOTA is FALSE; set TOP_UPLOADERS to
  ## FALSE so we get the number of all users, not just excluded ones.
  if [ "$USER_EXCLUDED" = "TRUE" ]; then # && [ "$TOP_UPLOADERS_EXCLUDED_SHOW_AS_QUOTA" = "FALSE" ]; then
    TOP_UPLOADERS="FALSE"
  fi

  ## If user is excluded and top uploaders is false, get number from ALL users.
  if [ "$USER_EXCLUDED" = "TRUE" ] && [ "$TOP_UPLOADERS" = "FALSE" ]; then
    total_quota_users="`$SQL "select count(username) from $SQLTB_EXCLUDED"`"
  else
    ## If he isnt excluded get a list of total non-excluded users.
    total_quota_users="`$SQL "select count(username) from $SQLTB_EXCLUDED where excluded = '0'"`"
  fi

  ## Get a list of which positions the user is for each section.
  POSITION="`$SQL "select rank from $SQLTB_RANK where username = '$CURUSER'"`"
  if [ -z "$POSITION" ]; then
    proc_debug "proc_get_user_pos_nice did not get a POSITION from table $SQLTB_RANK. Getting a new list."
    proc_get_user_position
  else
    proc_debug "Got $POSITION from table $SQLTB_RANK"
  fi
  if [ -z "$POSITION" ]; then
    proc_debug "Warning: proc_get_user_position didnt return POSITION to proc_check."
  else

    for rawdata in $POSITION; do
      posnum="`echo "$rawdata" | cut -d '^' -f1`"          
      for secraw in $QUOTA_LIMITS; do
        secnum="`echo "$secraw" | cut -d ':' -f1`"
        if [ "$secnum" = "$posnum" ] && [ "`echo "$secraw" | cut -d ':' -f3`" != "DISABLED" ]; then
          secname="`echo "$secraw" | cut -d ':' -f2`"
          curuser_position="`echo "$rawdata" | cut -d '^' -f2`"
          maxuser_position="`echo "$rawdata" | cut -d '^' -f3`"
          needed_position="`echo "$rawdata" | cut -d '^' -f4`"
          curuser_passed="`echo "$rawdata" | cut -d '^' -f5`"

          ## If the user have no stats in this section, dont show the information.
          if [ "$curuser_position" != "0" ]; then

            ## If this user is excluded and TOP_UPLOADERS_EXCLUDED_SHOW_AS_QUOTA = FALSE; then set TOP_UPLOADERS
            ## to FALSE so we dont get the "DEFAULT 5/6 Needed: 10(PASS)" info.. Instead: "DEFAULT 5/6"
            if [ "$USER_EXCLUDED" = "TRUE" ]; then # && [ "$TOP_UPLOADERS_EXCLUDED_SHOW_AS_QUOTA" = "FALSE" ]; then
              TOP_UPLOADERS="FALSE" 
            fi


            if [ "$TOP_UPLOADERS" = "FALSE" ]; then
              . $theme
#              if [ -z "$POSITION_NICE" ]; then
#                POSITION_NICE="[ $secname $curuser_position/$total_quota_users ]"
#              else
#                POSITION_NICE="$POSITION_NICE [ $secname - $curuser_position/$total_quota_users ]"
#              fi

              if [ -z "$POSITION_NICE" ]; then
                POSITION_NICE="${POSITION_NICE_ANNOUNCE_INFO}"
              else
                POSITION_NICE="${POSITION_NICE}${POSITION_NICE_SEPERATOR}${POSITION_NICE_ANNOUNCE_INFO}"
              fi

              TOP_UP_PASSED="DISABLED"

            elif [ "$TOP_UPLOADERS" = "TRUE" ]; then
              . $theme

              ## Only doing this if TOP_UPLOADERS is actually enabled.
              case $curuser_passed in
                P) if [ "$needed_position" = "-1" ]; then
                     # WORD=" (Passed Quota)"
                     WORD="$PN_WORD_END_DISABLED_PASSED"
                   else
                     # WORD=" Needed: $needed_position(PASS)"
                     WORD="$PN_WORD_END_ENABLED_PASSED"
                  fi
                   TOP_UP_PASSED="TRUE"
                   ;;
                F) if [ "$needed_position" = "-1" ]; then
                     # WORD=" (Pass Quota)"
                     WORD="$PN_WORD_END_DISABLED_FAILED"                  
                   else
                     # WORD=" Needed: $needed_position"
                     WORD="$PN_WORD_END_ENABLED_FAILED"
                   fi
                   if [ -z "$TOP_UP_PASSED" ]; then
                     TOP_UP_PASSED="FALSE"
                   fi
                   ;;
                D|*) WORD=""
                   if [ -z "$TOP_UP_PASSED" ]; then
                     TOP_UP_PASSED="DISABLED"
                   fi
                   ;;
              esac

              . $theme

              ## Build our nice list to present.
              if [ -z "$POSITION_NICE" ]; then
                # POSITION_NICE="[ $secname $curuser_position/$total_quota_users$WORD ]"
                POSITION_NICE="${POSITION_NICE_ANNOUNCE}"
              else
                # POSITION_NICE="$POSITION_NICE [ $secname $curuser_position/$total_quota_users$WORD ]"
                POSITION_NICE="${POSITION_NICE}${POSITION_NICE_SEPERATOR}${POSITION_NICE_ANNOUNCE}"
              fi

            else
              echo "ERROR: TOP_UPLOADERS needs to be either TRUE of FALSE. Not: \"$TOP_UPLOADERS\""
              exit 0
            fi
          else
            if [ "$TOP_UPLOADERS" = "TRUE" ]; then
              if [ -z "$TOP_UP_PASSED" ]; then
                TOP_UP_PASSED="FALSE"
              fi
            else
              TOP_UP_PASSED="DISABLED"
            fi
          fi

        fi
      done
    done
  fi

  if [ -z "$POSITION_NICE" ]; then
    POSITION_NICE="NONE"
  fi
}



## Used to check how many days are in this month. Returns MONTHTOTAL
proc_get_days_in_month() {
  case `$DATEBIN +%m` in
    01) MONTHTOTAL="31" ;;
    02) if [ "$( $DATEBIN -d "-1day `$DATEBIN +%Y`-03-01" +%d )" = "29" ]; then
          MONTHTOTAL="29"
          proc_debug "This is a leap year. Setting 29 days for FEB"
        else
          MONTHTOTAL="28"
        fi
        ;;
    03) MONTHTOTAL="31" ;;
    04) MONTHTOTAL="30" ;;
    05) MONTHTOTAL="31" ;;
    06) MONTHTOTAL="30" ;;
    07) MONTHTOTAL="31" ;;
    08) MONTHTOTAL="31" ;;
    09) MONTHTOTAL="30" ;;
    10) MONTHTOTAL="31" ;;
    11) MONTHTOTAL="30" ;;
    12) MONTHTOTAL="31" ;;
    *) echo "ERROR: \"$DATEBIN +%m\" didnt return 01-12 for month."; exit 0 ;;
  esac
}


## Show info.
proc_ratios() {

  TOT_EXCLUDED="`$SQL "select count(username) from $SQLTB_EXCLUDED where excluded = '1'"`"
  TOT_NON_EXCLUDED="`$SQL "select count(username) from $SQLTB_EXCLUDED where excluded = '0'"`"

  TOT_FORCED_QUOTA="`$SQL "select count(username) from $SQLTB where active = '0'"`"
  TOT_TRIAL="`$SQL "select count(username) from $SQLTB where active = '1'"`"
  TOT_EXCLUDED_F="`$SQL "select count(username) from $SQLTB where active = '2'"`"
  TOT_EXCLUDED_M="`$SQL "select count(username) from $SQLTB where active = '3'"`"

  if [ -z "$TOT_TRIAL" ]; then
    TOT_TRIAL="0"
  fi
  if [ -z "$TOT_EXCLUDED" ]; then
    TOT_EXCLUDED="0"
  fi
  if [ -z "$TOT_NON_EXCLUDED" ]; then
    TOT_NON_EXCLUDED="0"
  fi
  if [ -z "$TOT_EXCLUDED_M" ]; then
    TOT_EXCLUDED_M="0"
  fi
  if [ -z "$TOT_EXCLUDED_F" ]; then
    TOT_EXCLUDED_F="0"
  fi
  if [ -z "$TOT_FORCED_QUOTA" ]; then
    TOT_FORCED_QUOTA="0"
  fi
  TOT_THIS_MONTH="0"
  TOT_DELETED="0"
  TOT_LEECH="0"
  TOT_BYGROUP="0"
  TOT_VACATION="0"
  TOT_USERS=$[$TOT_EXCLUDED+$TOT_NON_EXCLUDED]

  cd $USERSDIR
  for CURUSER in `grep "^FLAGS " * | cut -d ':' -f1 | egrep -v "default\.user|\.lock"`; do

    proc_check_excluded
    if [ "$EXCLUDED_USER" = "TRUE" ]; then
      TOT_BYGROUP=$[$TOT_BYGROUP+1]
    fi    

    proc_check_this_month
    if [ "$THIS_MONTH" = "TRUE" ]; then
      TOT_THIS_MONTH=$[$TOT_THIS_MONTH+1]
    fi

    proc_check_delete
    if [ "$USER_DELETED" = "TRUE" ]; then
      TOT_DELETED=$[$TOT_DELETED+1]
    fi

    proc_vacation
    if [ "$ON_VACATION" = "TRUE" ]; then
      TOT_VACATION=$[$TOT_VACATION+1]
    fi

    if [ "$QUOTA_EXCLUDE_LEECH" = "TRUE" ]; then
      if [ "`grep "^RATIO 0" "$USERSDIR/$CURUSER"`" ]; then
        TOT_LEECH=$[$TOT_LEECH+1]
      fi
    fi

  done

  total_quota="0"
  if [ "$UPDATE_PASSED_TABLE" = "TRUE" ]; then
    total_passed="0"
    total_failed="0"
    proc_debug "Grabbing passed/failed users from $SQLTB_PASSED"
    for rawdata in `$SQL "select username, passed from $SQLTB_PASSED" | awk '{print $1"^"$2}'`; do
      CURUSER="`echo "$rawdata" | cut -d '^' -f1`"
      PASSED_STATUS="`echo "$rawdata" | cut -d '^' -f2`"
      total_quota=$[$total_quota+1]
      ## Count users. Announce if the the line is more then 50 lines long so that
      ## IRC dosnt cut it short.
      if [ "$PASSED_STATUS" = "1" ]; then
        total_passed=$[$total_passed+1]
      else
        total_failed=$[$total_failed+1]
      fi
    done
  fi
  
#  QUOTA_USERS=$[$TOT_NON_EXCLUDED-$TOT_TRIAL-$TOT_EXCLUDED_F-$TOT_EXCLUDED_M+$TOT_FORCED_QUOTA-$TOT_THIS_MONTH-$TOT_DELETED]

  echo ""
  echo "#--[ Overview of number of users ]------------------#"
  echo "#"
  echo "# Total Users..........: $TOT_USERS"
  echo "# Excluded.............: $TOT_EXCLUDED"
  echo "# Not Excluded.........: $TOT_NON_EXCLUDED"
  echo "# Users on Trial.......: $TOT_TRIAL"
  echo "# Group excluded.......: $TOT_BYGROUP"
  echo "# Manually excluded....: $TOT_EXCLUDED_F"
  echo "# Excluded this Month..: $TOT_EXCLUDED_M"
  if [ "$QUOTA_EXCLUDE_LEECH" = "TRUE" ]; then
    echo "# Has leech............: $TOT_LEECH"
  fi
  if [ "$VACATION_GROUP" ]; then
    echo "# In vacation group....: $TOT_VACATION"
  fi
  echo "# Added this month.....: $TOT_THIS_MONTH"
  echo "# Deleted..............: $TOT_DELETED"
  echo "# Forced Quota.........: $TOT_FORCED_QUOTA"
  if [ "$total_quota" != "0" ]; then
    echo "# Passed quota users...: $total_passed/$total_quota"
    echo "# Failed quota users...: $total_failed/$total_quota"
  fi
  echo "#"
  echo "# Note: A user can be excluded for more then one reason"
  echo "#       Hence, the numbers might not add up."
  echo "#"

  if [ "$TOT_EXCLUDED_F" != "0" ]; then
    echo "#--[ Permanently Excluded Users (manually) ]--------#"
    echo "#"
    secs_now="`$DATEBIN +%s`"
    for rawdata in `$SQL "select username, added from $SQLTB where active = '2'" | awk '{print $1"^"$2}'`; do    
      CURUSER="`echo "$rawdata" | cut -d '^' -f1`"
      added="`echo "$rawdata" | cut -d '^' -f2`"
      ## Calculate when they were added to DB...
      secs_check=$[$secs_now-$added]
      proc_calctime1

      proc_get_groups
      CURUSER="$CURUSER / $CURPRIGROUP"

      ## Fix the lenght of $username...
      while [ -z "`echo "$CURUSER" | grep "....................."`" ]; do
        CURUSER="$CURUSER "
      done

      echo "# $CURUSER Added to DB $TIME_COUNTH ago."
    done
    echo "#"
  fi


  ## Check if total excluded this month isnt 0. Initiate it if it isnt.
  if [ "$TOT_EXCLUDED_M" != "0" ]; then
    echo "#--[ Excluded users - Number of Months ]------------#"
    if [ "$VACATION_GROUP" ]; then
      echo "# Note: Users in the $VACATION_GROUP group are listed as \"This month\""
    fi
    echo "#"
    secs_now="`$DATEBIN +%s`"
    for rawdata in `$SQL "select username, active, added, extratime from $SQLTB where active = '3' order by extratime" | awk '{print $1"^"$2"^"$3"^"$4}'`; do
      CURUSER="`echo "$rawdata" | cut -d '^' -f1`"
      active="`echo "$rawdata" | cut -d '^' -f2`"
      added="`echo "$rawdata" | cut -d '^' -f3`"
      extratime="`echo "$rawdata" | cut -d '^' -f4`"

      ## Calculate when they were added to DB...
      secs_check=$[$secs_now-$added]
      proc_calctime1

      proc_get_groups
      CURUSER="$CURUSER / $CURPRIGROUP"

      ## Fix the lenght of $username...
      while [ -z "`echo "$CURUSER" | grep "....................."`" ]; do
        CURUSER="$CURUSER "
      done

      ## Show different text depending on 'extratime' flag. 0 = This month, 1 = This and the next, etc.
      case $extratime in
        0) echo "# This month: $CURUSER Added to DB $TIME_COUNTH ago." ;;
        1) echo "# 2 months  : $CURUSER Added to DB $TIME_COUNTH ago." ;;
        2) echo "# 3 months  : $CURUSER Added to DB $TIME_COUNTH ago." ;;
        3) echo "# 4 months  : $CURUSER Added to DB $TIME_COUNTH ago." ;;
        4) echo "# 5 months  : $CURUSER Added to DB $TIME_COUNTH ago." ;;
        *) echo "# More then 6 months: $CURUSER Added to DB $TIME_COUNTH ago." ;;
      esac

    done
    echo "#"
  fi

  echo "#--------------------------------------------------#"
}


## Used to list everyone who either passed or failed from quota.
proc_quotalist() {
  unset userlist

  if [ "$QUOTA_ENABLED" = "FALSE" ]; then
    echo "Quota is disabled at the moment. Can not perform this operation."
    exit 0
  fi

  ## Make sure the user specified failed or passed. Make it uppercase.
  LIST_MODE="`echo "$LIST_MODE" | tr '[:lower:]' '[:upper:]'`"
  if [ -z "$LIST_MODE" ] || [ "$LIST_MODE" != "FAILED" ] && [ "$LIST_MODE" != "PASSED" ]; then
    echo "Enter 'passed' or 'failed' to show quota status."
    exit 0
  fi

  ## Unset some variables. Make counters 0.
  unset failed_users
  unset passed_users
  total_passed=0
  total_failed=0
  total_quota=0

  ## Use the passed table if UPDATE_PASSED_TABLE is TRUE. Otherwise do it the old way.
  if [ "$UPDATE_PASSED_TABLE" = "TRUE" ]; then
    proc_debug "Running proc_quotalist() the new way. UPDATE_PASSED_TABLE is TRUE."
    for rawdata in `$SQL "select username, passed from $SQLTB_PASSED" | awk '{print $1"^"$2}'`; do
      CURUSER="`echo "$rawdata" | cut -d '^' -f1`"
      PASSED_STATUS="`echo "$rawdata" | cut -d '^' -f2`"
      if [ "$PASSED_STATUS" = "1" ]; then
        PASSED="TRUE"
      else
        PASSED="FALSE"
      fi

      total_quota=$[$total_quota+1]

      ## Count users. Announce if the the line is more then 50 lines long so that
      ## IRC dosnt cut it short.
      if [ "$PASSED" = "TRUE" ]; then
        total_passed=$[$total_passed+1]
        if [ "$LIST_MODE" = "PASSED" ]; then
          if [ "$( echo "$passed_users" | wc -c | tr -d ' ' )" -gt "50" ]; then
            echo "Passed:$passed_users"
            unset passed_users
          fi
          passed_users="$passed_users $CURUSER"
        fi
      else
        total_failed=$[$total_failed+1]
        if [ "$LIST_MODE" = "FAILED" ]; then
          if [ "$( echo "$failed_users" | wc -c | tr -d ' ' )" -gt "50" ]; then
            echo "Failed:$failed_users"
            unset failed_users
          fi
          failed_users="$failed_users $CURUSER"
        fi
      fi
    done

  ## If UPDATE_PASSED_TABLE is FALSE, run this the old slow way.
  else
    proc_debug "Running proc_quotalist() the old slow way. UPDATE_PASSED_TABLE is FALSE."
    ## For each user in the excluded database, do this.
    cd $USERSDIR
    for CURUSER in `grep "^FLAGS " * | cut -d ':' -f1 | egrep -v "default\.user|\.lock"`; do
      excluded="`$SQL "select excluded from $SQLTB_EXCLUDED where username = '$CURUSER'"`"

      ## If the user is excluded, check the trial database that hes not on forced quota.
      if [ "$excluded" = "1" ]; then
        ON_QUOTA=FALSE
      elif [ "$excluded" = "0" ]; then
        ON_QUOTA=TRUE
      fi

      ## If the user is not excluded in the excluded table, make sure hes not excluded in the trial table.
      if [ "`$SQL "select username from $SQLTB where username = '$CURUSER' and active = '1'"`" ]; then
        ON_QUOTA="FALSE"
#        echo "$CURUSER currently on trial. No quota."
      elif [ "`$SQL "select username from $SQLTB where username = '$CURUSER' and active = '2'"`" ]; then
        ON_QUOTA="FALSE"
#        echo "$CURUSER currently hard excluded. No quota."
      elif [ "`$SQL "select username from $SQLTB where username = '$CURUSER' and active = '3'"`" ]; then
        ON_QUOTA="FALSE"
#        echo "$CURUSER currently excluded this month. No quota."
      elif [ "`$SQL "select username from $SQLTB where username = '$CURUSER' and active = '0'"`" ]; then
        ON_QUOTA="TRUE"
#        echo "$CURUSER on hard set quota."
      fi

      proc_check_this_month
      if [ "$THIS_MONTH" = "TRUE" ]; then
        ON_QUOTA="FALSE"
      fi

      ## Run this if they are on quota.. check how they did.
      if [ "$ON_QUOTA" = "TRUE" ]; then
        total_quota=$[$total_quota+1]
        proc_check_quota

        ## Count users. Announce if the the line is more then 50 lines long so that
        ## IRC dosnt cut it short.
        if [ "$PASSED" = "TRUE" ]; then
          total_passed=$[$total_passed+1]
          if [ "$LIST_MODE" = "PASSED" ]; then
            if [ "$( echo "$passed_users" | wc -c | tr -d ' ' )" -gt "50" ]; then
              echo "Passed:$passed_users"
              unset passed_users
            fi
            passed_users="$passed_users $CURUSER"
          fi
        else
          total_failed=$[$total_failed+1]
          if [ "$LIST_MODE" = "FAILED" ]; then
            if [ "$( echo "$failed_users" | wc -c | tr -d ' ' )" -gt "50" ]; then
              echo "Failed:$failed_users"
              unset failed_users
            fi
            failed_users="$failed_users $CURUSER"
          fi
        fi

      fi
    done
  fi

  ## Also announce the counters on number of failed / passed users.
  ## Announce the last passed/failed users too.
  if [ "$LIST_MODE" = "PASSED" ]; then
    if [ "$passed_users" ]; then
      echo "Passed:$passed_users"
      echo "Total Passed: $total_passed/$total_quota"
    fi
  else
    if [ "$failed_users" ]; then
      echo "Failed:$failed_users"
    fi
    echo "Total Failed: $total_failed/$total_quota"
  fi
  if [ "$UPDATE_PASSED_TABLE" = "TRUE" ]; then
    echo "Note: This is not realtime information." 
  fi
}



## Main help menu.
proc_mainhelp() {
  echo ""
  echo "#--[ Tur-Trial v$VER ]----------------------------------------"
  echo "#"
  echo "# Trial commands:"
  echo "# tadd    - Adds an existing user to trial."
  echo "# tdel    - Remove a trial user, put on quota."
  echo "# tt      - Change timelimit to pass trial."
  echo "# tl      - Change sectionlimit to pass trial."
  echo "# treset  - Restart this users trial from scratch"
  echo "#           (same as 'wipe' & 'tadd')."
  echo "# tinfo   - View trial information."
  echo "# tlist   - View information about everyone on trial."
  echo "#--"
  echo "# Quota commands:"
  echo "# qadd    - Adds/Change a user for quota. Normally this isnt"
  echo "#           needed as everyone goes on quota by default."
  echo "#           However, if hes excluded by group and you still"
  echo "#           want to FORCE quota on him OR if you want specific"
  echo "#           limits on the user."
  echo "# ql      - Change sectionlimit to pass quota. Must 'qadd' the"
  echo "#           user first." 
  echo "# qreset  - Reset all values on user and put him on"
  echo "#           quota (same as 'wipe' & 'qadd')."
  echo "# qlist   - List everyone who either passed or failed quota."
  echo "#--"
  echo "# Generic commands:"
  echo "# eadd    - Add/Change the user as an excluded quota user."
  echo "# meadd   - Add/Change the user as an excluded quota user for the"
  echo "#           rest of the month only. Put on quota after that."
  echo "#           You can also specify the number of months to exclude."
  echo "#           Run without arguments for more help."
  echo "#"
  echo "# ereset  - Reset all values on user and make him excluded."
  echo "#"
  echo "# wipe    - Wipe all information from selected user."
  echo "#           Good if you want to restart, say, trial."
  echo "# info    - General rundown on number of users."

  if [ "$RUN_MODE" != "gl" ]; then
    echo "# check   - Same as 'passed' on irc."
    echo "# stats   - Show MonthTopUp for Quota Users."
    echo "# statsex - Show MonthTopUp for Excluded Users."
  fi

  echo "#           For stats* commands above, a section number can"
  echo "#           be specified as first argument as well."
  echo "# rawq    - Run a mysql query. Used for debugging mostly."
  echo "#           Example: rawq select username, rank from ranking"
  echo "# rawusr  - Get raw data from a user. For debugging mostly."
  echo "# testa   - Write a test announce line to glftpd.log to check"
  echo "#           if the TURGEN trigger works in your botscript."
  echo "# help    - Show this help"
  echo "#--"
  echo "# Use any of the commands without arguments for more help."
  echo "#---------------------------------------------------------"
}

if [ "$3" = "test" ] || [ "$3" = "debug" ]; then
  DEBUG="TRUE"
  TEST="TRUE"
fi

proc_is_user_excluded() {
  USER_EXCLUDED="FALSE"
  EXCLUDED_REASON="NONE"

  ## If the user is not excluded in the excluded table, make sure hes not excluded in the trial table.
  if [ "`$SQL "select username from $SQLTB where username = '$CURUSER' and active = '1'"`" ]; then
    USER_EXCLUDED="TRUE"
    EXCLUDED_REASON="On_Trial"
  elif [ "`$SQL "select username from $SQLTB where username = '$CURUSER' and active = '2'"`" ]; then
    USER_EXCLUDED="TRUE"
    EXCLUDED_REASON="Manually_Excluded"
  elif [ "`$SQL "select username from $SQLTB where username = '$CURUSER' and active = '3'"`" ]; then
    USER_EXCLUDED="TRUE"
    EXCLUDED_REASON="Manually_Excluded_M"
  fi

  ## Check if excluded by group.
  if [ "$USER_EXCLUDED" = "FALSE" ]; then
    proc_check_excluded
    if [ "$EXCLUDED_USER" = "TRUE" ]; then
      USER_EXCLUDED="TRUE"
      EXCLUDED_REASON="Group_Exclude"
    fi    
  fi

  ## Check if the user is on vacation..
  proc_vacation
  if [ "$ON_VACATION" = "TRUE" ]; then
    USER_EXCLUDED="TRUE"
    EXCLUDED_REASON="On_Vacation"
  fi

  ## Check if the user was added this or last month. Skip if so. Returns THIS_MONTH=TRUE/FALSE
  if [ "$USER_EXCLUDED" = "FALSE" ]; then
    ## and LAST_MONTH=TRUE/FALSE
    proc_check_this_month
    if [ "$THIS_MONTH" = "TRUE" ]; then
      USER_EXCLUDED="TRUE"
      EXCLUDED_REASON="Added_This_Month"
    fi
  fi

  ## Check if the user has leech, if thats enabled.
  if [ "$USER_EXCLUDED" = "FALSE" ]; then
    if [ "$QUOTA_EXCLUDE_LEECH" = "TRUE" ]; then
      if [ "`grep "^RATIO 0" "$USERSDIR/$CURUSER"`" ]; then
        USER_EXCLUDED="TRUE"
        EXCLUDED_REASON="User_Has_Leech"
      fi
    fi
  fi

  ## If on forced quota, this overrides all others (except deleted user)
  if [ "`$SQL "select username from $SQLTB where username = '$CURUSER' and active = '0'"`" ]; then
    USER_EXCLUDED="FALSE"
    EXCLUDED_REASON="Forced_Quota"
    ## Unset THIS_MONTH if the user is on forced quota (3.4 change).
    if [ "$THIS_MONTH" = "TRUE" ]; then
      unset THIS_MONTH
    fi
  fi

  proc_check_delete
  if [ "$USER_DELETED" = "TRUE" ]; then
    USER_EXCLUDED="TRUE"
    EXCLUDED_REASON="User_is_deleted"
  fi

  proc_debug "Excluded? USER_EXCLUDED:$USER_EXCLUDED - Reason:$EXCLUDED_REASON"
}

## Used to list TopMonthUp list for non excluded quota users.
proc_stats() {

  ## Define number of users to show, if not set in config.
  if [ -z "$USERS_IN_STATSLIST" ]; then
    USERS_IN_STATSLIST="10"
  fi

  ## This command wont work from inside glftpd.
  if [ "$RUN_MODE" = "gl" ]; then
    echo "Not a valid command from inside glftpd."
    exit 1
  fi

  ## If SHOW_MONTHUP is not TRUE, it means that TOP_UPLOADERS is FALSE too.
  ## If so, the rankings table is not updated and this command wont work.
  if [ "$SHOW_MONTHUP" != "TRUE" ]; then
    echo "This command requires that TOP_UPLOADERS and/or SHOW_MONTHUP is set to TRUE."
    exit 0
  fi

  ## Check if the user specified a section. Otherwise assume section 0.
  if [ -z "$SELECTED_SECTION" ]; then
    proc_debug "No section provided. Using 0"
    SELECTED_SECTION="0"
  else
    if [ "`echo "$SELECTED_SECTION" | tr -d '[:digit:]'`" ]; then
      proc_getsections
      echo "Please use the section number when specifying section: $DEFINED_SECTIONS_NAME"
      exit 0
    fi
  fi

  ## Add 1 to a temporary value so we get the correct section...
  SELECTED_SECTION_RAW=$[$SELECTED_SECTION+1]

  ## Check if the selected section exists. Otherwise, present valid sections.
  SELECTED_SECTION="`echo "$QUOTA_SECTIONS" | cut -d ' ' -f$SELECTED_SECTION_RAW`"
  if [ -z "$SELECTED_SECTION" ]; then
    proc_getsections
    echo "No such section. Valid sections: $DEFINED_SECTIONS_NAME"
    exit 0
  fi

  ## Grab the name for this section so we have something nice to present.
  SELECTED_SECTION_NAME="`echo "$SELECTED_SECTION" | cut -d ':' -f2`"
  proc_debug "Selected section is: $SELECTED_SECTION $SELECTED_SECTION_NAME"

  ## Run the statsbinary on the selected section. Pipe output to a file we can parse later.
  proc_debug "Creating the stats list to use. Put it in /tmp/tt3.stats.$SELECTED_SECTION_NAME"
  $STATSBIN -um -s$SELECTED_SECTION -x1000 | grep "^\[[0-9]" | tr ' ' '^' | grep -v "\^0MB\^Unknown\^" > /tmp/tt3.stats.$SELECTED_SECTION_NAME

  ## Set which excluded flag to use. Depending on if we selected quota or excluded users.
  if [ "$STATS_MODE" = "excluded" ]; then
    flag="1"
    WORD="Excluded"
  else
    flag="0"
    WORD="Quota"
  fi

  ## For each user that means the flag criteria above, run...
  for CURUSER in `$SQL "select username from $SQLTB_EXCLUDED where excluded = '$flag'"`; do
    proc_debug "Grabbind ranking stats for $WORD user: $CURUSER"
    curdata="`$SQL "select rank from $SQLTB_RANK where username = '$CURUSER'" | cut -d ' ' -f$SELECTED_SECTION_RAW`"

    proc_debug "Rawdata for $CURUSER = $curdata"

    ## Get current position from ranking.
    cur_pos="`echo "$curdata" | cut -d '^' -f2`"

    ## Check that its not 0. If it is, the user havent uploaded anything and we'll skip em.
    if [ "$cur_pos" != "0" ]; then

      ## Grab the current stats line from the piped file, created earlier.
      cur_stats="`grep "^\[.*\]\^$CURUSER\^" /tmp/tt3.stats.$SELECTED_SECTION_NAME | head -n1`"

      ## Check that we got anything from the file or not.
      if [ -z "$cur_stats" ]; then
        proc_debug "Got no stats from STATSBIN on $CURUSER -  Skipping."
      else
        proc_debug "Current: $cur_stats"

        ## Make sure $cur_pos is 01 instead of 1, etc (up to 9).
        if [ -z "`echo "$cur_pos" | grep ".."`" ]; then
          cur_pos="0${cur_pos}"
        fi

        ## Put the final output for this user in another temporary file.
        echo "[$cur_pos] $cur_stats" >> "/tmp/tt3.quotastats.$SELECTED_SECTION_NAME"
      fi
    fi
  done

  ## Loop completed. Check if we got any file to work on. If not, quit.
  if [ ! -e "/tmp/tt3.quotastats.$SELECTED_SECTION_NAME" ]; then
    echo "No userdata yet..."
  else

    ## Output the generic header.
    echo "           Month Top ${USERS_IN_STATSLIST} - $WORD Users (up) for section $SELECTED_SECTION_NAME"
    echo "<--------------------------------------------------------------------------->"
    echo "Rank Real Username     Tagline                       Files     Mbytes   K/sec"
    echo "-----------------------------------------------------------------------------"

    ## If we are NOT checking excluded users, we can just sort and echo the file.
    if [ "$STATS_MODE" != "excluded" ]; then
      cat "/tmp/tt3.quotastats.$SELECTED_SECTION_NAME" | sed -e 's/\[/\ /' | sed -e 's/\]/\ /' | sort -k 1,1 -n | sed -e 's/\ /\[/' | sed -e 's/\ /\]/' | tr '^' ' ' | head -n${USERS_IN_STATSLIST}
    else

      ## If however, we are running for excluded users, we need to make our own rankings
      ## since the "excluded ranking" isnt in the rankings table as they are with quota users.
      ## UPDATE 3.2: Bah, 2 seperate lists.
      num="1"
#      cat "/tmp/tt3.quotastats.$SELECTED_SECTION_NAME" | sed -e 's/\[/\ /' | sed -e 's/\]/\ /' | sort -k 1,1 -n | sed -e 's/\ /\[/' | sed -e 's/\ /\]/' | tr '^' ' ' | head -n${USERS_IN_STATSLIST}


## Old way before we got seperate lists for quota and non quota.
      cat "/tmp/tt3.quotastats.$SELECTED_SECTION_NAME" | sed -e 's/\[/\ /' | sed -e 's/\]/\ /' | sort -k 1,1 -n | sed -e 's/\ /\[/' | sed -e 's/\ /\]/' | tr '^' ' ' > /tmp/tt3.sorted.tmp

      for rawdata in `cat "/tmp/tt3.sorted.tmp" | tr ' ' '^' | cut -d '^' -f2-`; do
        if [ -z "`echo "$num" | grep ".."`" ]; then
          num_nice="0${num}"
        else
          num_nice="$num"
        fi        

        ## Echo the output line.
        echo "[$num_nice] $rawdata" | tr '^' ' '

        ## Add +1 to the Rank field.
        num=$[$num+1]
        if [ "$num" -gt "$USERS_IN_STATSLIST" ]; then
          break
        fi
      done
    fi
    echo ".---------------------------------------------------------------------------."
  fi

  ## Delete the temporary files, if any.
  if [ -e "/tmp/tt3.quotastats.$SELECTED_SECTION_NAME" ]; then
    rm -f "/tmp/tt3.quotastats.$SELECTED_SECTION_NAME"
  fi
  if [ -e "/tmp/tt3.stats.$SELECTED_SECTION_NAME" ]; then
    rm -f /tmp/tt3.stats.$SELECTED_SECTION_NAME
  fi
  if [ -e "/tmp/tt3.sorted.tmp" ]; then
    rm -f "/tmp/tt3.sorted.tmp"
  fi

  
  if [ -z "$DEFINED_SECTIONS_NAME" ]; then
    proc_getsections
    echo "Sections are: $DEFINED_SECTIONS_NAME"
  fi

} ## End proc_stats()

## Used to get rawdata from the tables.
proc_get_rawdata() {
  if [ -z "`echo "$QUERY" | grep "\ "`" ]; then
    echo "Specify a mysql query too."
    exit 1
  fi

  COMMAND="`echo "$QUERY" | cut -d ' ' -f2-`"
  if [ -z "$COMMAND" ]; then
    echo "Got no queryline from $QUERY"
    exit 1
  fi

  echo "Running query: $COMMAND"
  $SQL "$COMMAND"
}

proc_get_userdata() {
  if [ -z "$CURUSER" ]; then
    echo "Specify a username to get rawdata from."
    exit 1
  fi

  if [ ! -e "$USERSDIR/$CURUSER" ]; then
    echo "$CURUSER does not exist in $USERSDIR"
    exit 1
  fi

  echo "Displaying raw mysql data for user $CURUSER"  
  echo "--------------------------------------------------------"
  echo "Data from the Excluded table ($SQLTB_EXCLUDED):"
  $SQL "select * from $SQLTB_EXCLUDED where username = '$CURUSER'"
  echo "--------------------------------------------------------"
  echo "Data from the Passed table ($SQLTB_PASSED):"
  $SQL "select * from $SQLTB_PASSED where username = '$CURUSER'"
  echo "--------------------------------------------------------"
  echo "Data from the Ranking table ($SQLTB_RANK):"
  $SQL "select * from $SQLTB_RANK where username = '$CURUSER'"
  echo "--------------------------------------------------------"
  echo "Data from the Trial table ($SQLTB):"
  $SQL "select * from $SQLTB passed where username = '$CURUSER'"
  echo "--------------------------------------------------------"
}

## Main menu
case $1 in
  [tT][aA][dD][dD]) CURUSER="$2"; proc_addtrial; exit 0 ;;
  [tT][dD][eE][lL]) CURUSER="$2"; proc_deltrial; exit 0 ;;
  [tT][rR][eE][sS][eE][tT]) CURUSER="$2"; proc_treset; exit 0 ;;
  [tT][lL][iI][sS][tT]) proc_triallist; exit 0 ;;
  [tT][tT]) CURUSER="$2"; CHANGE_TIME="$3"; proc_changetime; exit 0 ;;
  [tT][iI][nN][fF][oO]) CURUSER="$2"; proc_info; exit 0 ;;
  [tT][lL]) CURUSER="$2"; CHANGE_SECTION="$3"; MODE="TRIAL"; proc_changesection; exit 0 ;; 
  [tT][cC][rR][oO][nN]) proc_crontrial; exit 0 ;;

  [qQ][aA][dD][dD]) CURUSER="$2"; SACTIVE="0"; ANNOUNCE=TRUE; proc_addquota; exit 0 ;;
  [qQ][rR][eE][sS][eE][tT]) CURUSER="$2"; proc_qreset; exit 0 ;;
  [qQ][lL][iI][sS][tT]) LIST_MODE="$2"; proc_quotalist; exit 0 ;;
  [qQ][lL]) CURUSER="$2"; CHANGE_SECTION="$3"; MODE="QUOTA"; proc_changesection; exit 0 ;; 
  [qQ][cC][rR][oO][nN]) RUNMODE="qcron"; proc_cronquota; exit 0 ;;

  [eE][aA][dD][dD]) CURUSER="$2"; SACTIVE="2"; ANNOUNCE=TRUE; proc_addquota; exit 0 ;;
  [eE][lL]) CURUSER="$2"; CHANGE_SECTION="$3"; MODE="EXCLUDE"; proc_changesection; exit 0 ;; 
  [eE][rR][eE][sS][eE][tT]) CURUSER="$2"; SACTIVE="2"; proc_qreset; exit 0 ;;

  [mM][eE][aA][dD][dD]) CURUSER="$2"; SACTIVE="3"; MONTHS="$3"; ANNOUNCE=TRUE; proc_addquota; exit 0 ;;

  [wW][iI][pP][eE]) CURUSER="$2"; RUNMODE="WIPE"; ANNOUNCE=TRUE; proc_wipe; exit 0 ;;
  [cC][hH][eE][cC][kK]) CURUSER="$2"; proc_check; exit 0 ;;

  [iI][nN][fF][oO]) proc_ratios; exit 0 ;;

  [sS][tT][aA][tT][sS]) STATS_MODE="quota"; SELECTED_SECTION="$2"; proc_stats; exit 0 ;;
  [sS][tT][aA][tT][sS][eE][xX]) STATS_MODE="excluded"; SELECTED_SECTION="$2"; proc_stats; exit 0 ;;

  [tT][eE][sS][tT][aA]) proc_gllog "Testing testing 1,2,3"; exit 0 ;;
  [uU][pP][dD][aA][tT][eE]) UPDATE_ONLY="TRUE"; proc_update_excludelist; exit 0 ;;

  [rR][aA][wW][qQ]) QUERY="$@"; proc_get_rawdata; exit 0 ;;
  [rR][aA][wW][uU][sS][rR]) CURUSER="$2"; proc_get_userdata; exit 0 ;;

  [hH][eE][lL][pP]|*) proc_mainhelp; exit 0 ;;

esac

exit 0
