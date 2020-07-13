#!/bin/bash
VER=2.15.1

#-[ Script Start ]----------------------------------------------#
#                                                               #
# No changes below here unless you want to change some text.    #
#                                                               #
#---------------------------------------------------------------#

## Read config
if [ -z $config ]; then
  config="`dirname $0`/tur-request.conf"
fi
if [ ! -r $config ]; then
  echo "Error. Can not read $config"
  exit 0
else
  . $config
fi

if [ -z "$datebin" ]; then
  datebin="date"
fi

## Check if we're in glftpd or shell (irc)..
if [ "$FLAGS" ]; then
  mode=gl
  HOWTOFILL='site reqfilled <number or name>'
  if [ "$DONT_SHOW_STATUSANNOUNCE_FROM_GL" = "TRUE" ]; then
    unset STATUSANNOUNCE
  fi
  username="$USER"
  BY="$username"
  arg1="$1"
else
  mode=irc
  requests=$glroot$requests
  reqfile=$glroot$reqfile
  tmp=$glroot$tmp
  tuls=$glroot$tuls
  dirloglist_gl=$glroot/bin/dirloglist
  passwd=$glroot$passwd
  passchk=$glroot$passchk
  if [ "$msgsdir" ]; then
    msgsdir=$glroot$msgsdir
  fi
  if [ "$usersdir" ]; then
    usersdir="$glroot$usersdir"
  fi
  if [ "$gllog" ]; then
    gllog=$glroot$gllog
  fi
  if [ "$log" ]; then
    log="$glroot$log"
  fi
  HOWTOFILL='!reqfilled <number or name>'
fi

if [ "$filled_dir" ]; then
  if [ ! -d "${requests}/${filled_dir}" ]; then
    echo "Error: filled_dir (${requests}/${filled_dir}) does not exist."
    exit 0
  fi

  filled_dir="$filled_dir/"
fi

proc_mainerror() {
  echo "Got neither request, reqfilled, reqwipe, status, fix or checkold... quitting."
  exit 0
}

if [ -z "$1" ]; then
  proc_mainerror
fi

## Procedure for logging
proc_log() {
  if [ "$log" ]; then
    if [ -w "$log" ]; then
      echo `$datebin "+%a %b %e %T %Y"` "$@" >> $log
    else
      if [ "$USER" = "root" ]; then
        touch $log
        if [ -x "chmod" ]; then
          chmod 666 $log
        fi
      else
        logname=`basename $log`
        echo "Error: Can not write to $logname. Create and set chmod 666."
      fi
    fi
  fi
}

## Heres where we change those %blabla% into real text.
proc_cookies() {
  if [ "$BY" ]; then
    OUTPUT=`echo $OUTPUT | sed -e "s/%WHO%/$BY/g"`
  fi
  if [ "$WHAT" ]; then
    OUTPUT=`echo $OUTPUT | sed -e "s/%WHAT%/$WHAT/g"`
  fi
  if [ "$ACTION" ]; then
    OUTPUT=`echo $OUTPUT | sed -e "s/%ACTION%/$ACTION/g"`
  fi
  if [ "$RELEASE" ]; then
    OUTPUT=`echo $OUTPUT | sed -e "s/%RELEASE%/$RELEASE/g"`
  fi
  if [ "$mode" ]; then
    OUTPUT=`echo $OUTPUT | sed -e "s/%MODE%/$mode/g"`
  fi
  if [ "$name" ]; then
    OUTPUT=`echo $OUTPUT | sed -e "s/%NAME%/$name/g"`
  fi
  if [ "$adddate" ]; then
    OUTPUT=`echo $OUTPUT | sed -e "s/%ADDDATE%/$adddate/g"`
  fi
  if [ "$requesthead" ]; then
    OUTPUT=`echo $OUTPUT | sed -e "s/%REQUESTHEAD%/"$requesthead"/g"`
  fi
  if [ "$filledhead" ]; then
    OUTPUT=`echo $OUTPUT | sed -e "s/%FILLEDHEAD%/$filledhead/g"`
  fi
  if [ "$HOWTOFILL" ]; then
    OUTPUT=`echo $OUTPUT | sed -e "s/%HOWTOFILL%/$HOWTOFILL/g"`
  fi
  if [ "$sitename" ]; then
    OUTPUT=`echo $OUTPUT | sed -e "s/%SITENAME%/$sitename/g"`
  fi
  if [ "$FOR" ]; then
    OUTPUT=`echo $OUTPUT | sed -e "s/%FOR%/$FOR/g"`
  fi
  if [ "$num" ]; then
    OUTPUT=`echo $OUTPUT | sed -e "s/%NUM%/$num/g"`
  fi
  if [ "$REWARD" ]; then
    OUTPUT=`echo $OUTPUT | sed -e "s/%REWARD%/$REWARD/g"`
  fi
  ## Uses = when creating list. Will be replaced by / after the sed (sed dont like /).
  if [ "$REWARD_LIST" ]; then
    OUTPUT=`echo $OUTPUT | sed -e "s/%REWARDLIST%/$REWARD_LIST/g" | tr '=' '/'`
  fi
  if [ "$total_files" ]; then
    OUTPUT=`echo $OUTPUT | sed -e "s/%REWARD_FILES%/$total_files/g"`
  fi
  if [ "$total_files" ]; then
    OUTPUT=`echo $OUTPUT | sed -e "s/%REWARD_FILES%/$total_files/g"`
  fi
  if [ "$total_users" ]; then
    OUTPUT=`echo $OUTPUT | sed -e "s/%REWARD_USERS%/$total_users/g"`
  fi
  if [ "$IRCOUTPUT" = "TRUE" -o "$AUTO" = "TRUE" ]; then
    OUTPUT=`echo $OUTPUT | sed -e "s/%BOLD%//g"`
    OUTPUT=`echo $OUTPUT | sed -e "s/%ULINE%//g"`
  else
    OUTPUT=`echo $OUTPUT | sed -e "s/%BOLD%//g"`
    OUTPUT=`echo $OUTPUT | sed -e "s/%ULINE%//g"`
  fi
}

## This is used for a few function to change config settings with spaces so we can egrep em.
## Example: Setting="ost ost2" -> "^ost$|^ost2$"
## Needs FIX_LIST as input and returns FIXED_LIST
proc_make_egrep_list() {
  for temp_each in $FIX_LIST; do
    if [ "$temp_fixed_list" ]; then
      temp_fixed_list="$temp_fixed_list|^${temp_each}$"
    else
      temp_fixed_list="^${temp_each}$"
    fi
  done
  FIXED_LIST="$temp_fixed_list"
  unset temp_fixed_list; unset temp_each; unset FIX_LIST
}

if [ -z "$tuls" ] && [ "$enable_rewardsystem" = "TRUE" ]; then
  echo "ERROR. You have enable_rewardsystem=TRUE but tuls= is not defined."
  exit 0
fi
if [ "$enable_rewardsystem" = "TRUE" ] && [ "$do_not_create_dir_until_filled" = "TRUE" ]; then
  echo "ERROR. You have enable_rewardsystem=TRUE AND do_not_create_dir_until_filled=TRUE"
  echo "This will not work"
  exit 0
fi

## Get all arguments into RAWSTRING.
RAWSTRING="`echo "$@" | tr -d '\]' | tr -d '\[' | tr -d '\|' | tr -d '^'`"

## Make initial check. Cant include a /
if [ "$( echo "$RAWSTRING" | grep "\/" )" ]; then
  if [ "$mode" = "irc" ]; then
    IRCOUTPUT="TRUE"
  fi

  OUTPUT="$NONSTANDARDCHAR"
  proc_cookies
  echo "$OUTPUT"
  exit 0
fi

if [ "$mode" = "irc" -a "$1" != "checkold" ]; then
  ## If from irc, cut out second word to BY. This is who its from.
  BY=`echo "$RAWSTRING" | cut -d ' ' -f2`
  ## Remove that one when done.
  RAWSTRING=`echo "$RAWSTRING" | sed -e "s/$BY//" | tr -s ' '`
fi

## Check first word. This is the action to take (request, reqfilled etc).
RUN=`echo "$RAWSTRING" | cut -d' ' -f1`
## Remove run command from RAWSTRING.
RAWSTRING=`echo "$RAWSTRING" | sed -e "s/^$RUN//"`
## Make it lowercase
RUN="`echo "$RUN" | tr '[:upper:]' '[:lower:]'`"
## Clear up RAWSTRING from leftover spaces.
RAWSTRING=`echo $RAWSTRING`

if [ "$RAWSTRING" = "$RUN" -a "$RUN" = "request" -o "$RAWSTRING" = "" -a "$RUN" = "request" ]; then
  if [ "$mode" = "irc" ]; then
    if [ "$AUTH_SYSTEM" = "TRUE" ]; then
      echo "Usage: /msg botnick !request <username> <password> <request> (-hide) (-for:<username>)"
    else
      echo "Usage: /msg botnick !request <request> (-hide) (-for:<username>)"
    fi
    echo "-hide is used to not announce to chan."
    echo "-for:<username> is used to specify who the request is for."
  else
    echo "Usage: site request <request> (-hide) (-for:<username>)"
    echo "-hide is used to not announce to chan."
    echo "-for:<username> is used to specify who the request is for."
  fi
  exit 0
fi

## If this is a request, reqdel or reqwipe and we are running from irc, check the username and password.
if [ "$AUTH_SYSTEM" = "TRUE" ]; then
  if [ "`echo "$RUN" | egrep "^request$|^reqdel$|^reqwipe$"`" ] && [ "$mode" = "irc" ]; then
    username="`echo "$RAWSTRING" | cut -d ' ' -f1`"
    userpass="`echo "$RAWSTRING" | cut -d ' ' -f2`"
    RAWSTRING="`echo "$RAWSTRING" | cut -d ' ' -f3-`"
    if [ "`$passchk "$username" "$userpass" "$passwd"`" != "$passchk_ok" ]; then
      echo "Wrong username or password. Use !$1 <username> <password> <request>"
      exit 0
    fi
    ## Use this BY instead of the irc nick to get correct name in .requests file, etc.
    BY="$username"
    arg1="$1"
  fi

  ## If this is a request, make sure the user has access to run it.
  if [ "$RUN" = "request" ]; then
    if [ "$request_allowed_flags" ] || [ "$request_allowed_users" ]; then
      ALLOWED_TO_REQUEST="FALSE"

      ## Allowed by flag?
      if [ "$request_allowed_flags" ]; then
        request_allowed_flags="`echo "$request_allowed_flags" | tr -s ' ' '|'`"
        if [ "`grep "^FLAGS " "$usersdir/$username" | cut -d ' ' -f2 | egrep "$request_allowed_flags"`" ]; then
          ALLOWED_TO_REQUEST="TRUE"
        fi
      fi

      ## Remake userlist to add ^ $ to each defined user for perfect matches.
      ## Allowed by user?
      if [ "$request_allowed_users" ]; then
        FIX_LIST="$request_allowed_users"
        proc_make_egrep_list
        request_allowed_users="$FIXED_LIST"; unset FIXED_LIST

        ## Check if username matches.
        if [ "`echo "$username" | egrep "$request_allowed_users"`" ]; then
          ALLOWED_TO_REQUEST="TRUE"
        fi
      fi

      ## No access ?
      if [ "$ALLOWED_TO_REQUEST" != "TRUE" ]; then
        echo "You do not have access to do new requests."
        exit 0
      fi
    fi
  fi
else
  ## Disable rewardsystem if AUTH_SYSTEM=FALSE
  enable_rewardsystem="FALSE"
fi

## Check if -hide is in RAWSTRING. If so, remove it and set HIDE=TRUE
if [ "`echo "$RAWSTRING" | grep -w "\-hide"`" ]; then
  HIDE=TRUE
  RAWSTRING=`echo "$RAWSTRING" | sed -e "s/\-hide//"`
else
  HIDE=FALSE
fi

## Check if -reward is in RAWSTRING. If so, remove it and set REWARD=amount
## Only if its a request.
if [ "$RUN" = "request" ] && [ "`echo "$RAWSTRING" | grep " \-reward\:"`" ]; then
  if [ "$enable_rewardsystem" != "TRUE" ]; then
    echo "Error: -reward: is not enabled."
    exit 0
  fi

  ## Check if the user has access to the reward system.
  ## If no security is set, automatically allow it. Otherwise, disallow it by
  ## default. If its not allowed, it will run the checks further down to enable it.
  if [ "$reward_allowed_users" ] || [ "$reward_allowed_flags" ]; then
    REWARD_ACCESS="FALSE"
  else
    REWARD_ACCESS="TRUE"
  fi

  ## Allowed by flag?
  if [ "$reward_allowed_flags" ]; then
    reward_allowed_flags="`echo "$reward_allowed_flags" | tr -s ' ' '|'`"
    if [ "`grep "^FLAGS " "$usersdir/$username" | cut -d ' ' -f2 | egrep "$reward_allowed_flags"`" ]; then
      REWARD_ACCESS="TRUE"
    fi
  fi

  ## Remake userlist to add ^ $ to each defined user for perfect matches.
  ## Allowed by user?
  if [ "$reward_allowed_users" ]; then
    FIX_LIST="$reward_allowed_users"
    proc_make_egrep_list
    reward_allowed_users="$FIXED_LIST"; unset FIXED_LIST

    ## Check if username matches.
    if [ "`echo "$username" | egrep "$reward_allowed_users"`" ]; then
      REWARD_ACCESS="TRUE"
    fi
  fi

  ## No access ?
  if [ "$REWARD_ACCESS" != "TRUE" ]; then
    echo "You do not have access to use -reward:"
    exit 0
  fi

  REWARD_FREE="FALSE"

  ## No decuction when using -reward:? Check by flag.
  if [ "$reward_free_flags" ]; then
    reward_free_flags="`echo "$reward_free_flags" | tr -s ' ' '|'`"
    if [ "`grep "^FLAGS " "$usersdir/$username" | cut -d ' ' -f2 | egrep "$reward_free_flags"`" ]; then
      REWARD_FREE="TRUE"
    fi
  fi

  ## Remake userlist to add ^ $ to each defined user for perfect matches.
  ## No decuction when using -reward:? Check by username
  if [ "$reward_free_users" ]; then
    FIX_LIST="$reward_free_users"
    proc_make_egrep_list
    reward_free_users="$FIXED_LIST"; unset FIXED_LIST

    ## Check if username matches.
    if [ "`echo "$username" | egrep "$reward_free_users"`" ]; then
      REWARD_FREE="TRUE"
    fi
  fi

  ## Keep going.
  for crap in $RAWSTRING; do
    if [ "$( echo "$crap" | grep '\-reward\:' )" ]; then
      REWARD=`echo $crap | cut -d ':' -f2`
      break
    fi
  done

  if [ -z "$REWARD" ]; then
    echo "You used -reward: but no amount of credits specified that will be rewarded."
    exit 0
  elif [ "`echo "$REWARD" | tr -d '[:digit:]'`" ]; then
    echo "Error. Only use pure MB number in the reward amount."
    exit 0
  fi

  if [ "$REWARD_FREE" != "TRUE" ]; then
    current_credits_kb="`grep "^CREDITS " "$usersdir/$username" | cut -d ' ' -f2`"
    current_credits_mb=$[$current_credits_kb/1024]
    if [ -z "$current_credits_mb" ]; then
      echo "Internal error. Did not manage to read current credits for $username."
      echo "Debug: current_credits_kb: $current_credits_kb"
      echo "Debug: current_credits_mb: $current_credits_mb"
      exit 0
    fi

    if [ "$current_credits_mb" -lt "$REWARD" ]; then
      echo "You do not have ${REWARD}MB credits. Only ${current_credits_mb}MB."
      exit 0
    fi
  fi

  RAWSTRING=`echo "$RAWSTRING" | sed -e "s/\-reward:$REWARD//"`

else
  unset REWARD
fi

## Clear up RAWSTRING from start and ending spaces.
RAWSTRING=`echo $RAWSTRING`

## Check if -for: is in RAWSTRING. If so, cut it out and check who its for.
## Only if its a request.
unset FOR; unset FORLAST
if [ "$RUN" = "request" ] && [ "$( echo "$RAWSTRING" | grep '\-for\:' )" ]; then
  for crap in $RAWSTRING; do
    if [ "$( echo "$crap" | grep '\-for\:' )" ]; then
      FOR=`echo $crap | cut -d ':' -f2`
      break
    fi
  done

  ## Check that FOR isnt empty.
  if [ -z "$FOR" ]; then
    echo "When using '-for:' then specify a user who its for too."
    exit 0
  fi

  RAWSTRING=`echo "$RAWSTRING" | sed -e "s/\-for:$FOR//"`

  unset FORLAST
fi

## Clear up RAWSTRING again
RAWSTRING=`echo $RAWSTRING`

## DEBUG VALUES. Remove below #'s to only get debug output.
# echo "full  : <$@>"
# echo "by    : <$BY>"
# echo "action: <$RUN>"
# echo "hide  : <$HIDE>"
# echo "for   : <$FOR>"
# echo "rel   : <$RAWSTRING>"
# echo "reward: <$REWARD>"
# exit 0

## Set request to $WHAT from $RAWSTRING and clear RAWSTRING
WHAT="$RAWSTRING"; unset RAWSTRING

## If this is a reqwipe, make sure the user has access to to that.
if [ "$AUTH_SYSTEM" = "TRUE" ]; then
  if [ "$RUN" = "reqwipe" ] && [ "$mode" = "irc" ]; then
    ## Set default = no access.
    ALLOWED_REQWIPE="FALSE"

    ## Remake flags. put a | in between. See if they match a userflag.
    if [ "$reqwipe_access_flags" ]; then
      reqwipe_access_flags="`echo "$reqwipe_access_flags" | tr -s ' ' '|'`"
      if [ "`grep "^FLAGS " "$usersdir/$username" | cut -d ' ' -f2 | egrep "$reqwipe_access_flags"`" ]; then
        ALLOWED_REQWIPE="TRUE"
      fi
    fi

    ## Remake userlist to add ^ $ to each defined user for perfect matches.
    if [ "$reqwipe_access_users" ]; then
      FIX_LIST="$reqwipe_access_users"
      proc_make_egrep_list
      reqwipe_access_users="$FIXED_LIST"; unset FIXED_LIST

      ## Check if username matches.
      if [ "`echo "$username" | egrep "$reqwipe_access_users"`" ]; then
        ALLOWED_REQWIPE="TRUE"
      fi
    fi

    ## Check if its still not allowed. Exit if not.
    if [ "$ALLOWED_REQWIPE" = "FALSE" ]; then
      echo "You dont have reqwipe access."
      exit 0
    fi
    arg1="$1"
  fi

  ## Check if max number of requests are set. Check it otherwise.
  if [ "$RUN" = "request" ] && [ "$max_requests_per_user" ]; then
    MAX_REQS_EXCLUDED="FALSE"

    ## Remake flags. put a | in between. See if they match a userflag.
    if [ "$max_requests_ignore_flags" ]; then
      max_requests_ignore_flags="`echo "$max_requests_ignore_flags" | tr -s ' ' '|'`"
      if [ "`grep "^FLAGS " "$usersdir/$username" | cut -d ' ' -f2 | egrep "$max_requests_ignore_flags"`" ]; then
        MAX_REQS_EXCLUDED="TRUE"
      fi
    fi

    ## Remake userlist to add ^ $ to each defined user for perfect matches.
    if [ "$max_requests_ignore_users" ]; then
      for temp_each in $max_requests_ignore_users; do
        if [ "$temp_access_users" ]; then
          temp_access_users="$temp_access_users|^${temp_each}$"
        else
          temp_access_users="^${temp_each}$"
        fi
      done
      max_requests_ignore_users="$temp_access_users"
      unset temp_access_users

      ## Check if username matches.
      if [ "`echo "$username" | egrep "$max_requests_ignore_users"`" ]; then
        MAX_REQS_EXCLUDED="TRUE"
      fi
    fi

    if [ "$MAX_REQS_EXCLUDED" = "FALSE" ]; then
      user_requests="0"
      for rawdata in `cat $reqfile | tr ' ' '~'`; do
        if [ "`echo "$rawdata" | grep "by~${username}~("`" ]; then
          user_requests=$[$user_requests+1]
        fi
      done
      # echo "Current requests by $username: $user_requests"
      if [ "$user_requests" -ge "$max_requests_per_user" ]; then
        echo "Sorry, you are only allowed to make $max_requests_per_user requests. You currently have $user_requests requests."
        exit 0
      fi
    fi
  fi
fi

## Check if allowspace is FALSE.
if [ "$allowspace" = "FALSE" ]; then
  ## If it was, check if theres a space in $WHAT
  if [ "$( echo "$WHAT" | grep ' ' )" ]; then
    ## If there was a space, check if replacewith is set.
    if [ "$replacewith" ]; then
      ## If it was, replace all spaces with it.
      WHAT=`echo "$WHAT" | tr ' ' "$replacewith"`
    else
      ## If replacewith is empty, say the NOSPACES error.
      if [ "$mode" = "irc" ]; then
        IRCOUTPUT="TRUE"
      fi

      OUTPUT="$NOSPACES"
      proc_cookies
      echo "$OUTPUT"
      exit 0
    fi
  fi
fi

## Verify that $WHAT is set etc. If no argument is given...
proc_verify() {

  ## Check that $WHAT does not include bad chars..."
  if [ "$( echo "$WHAT" | egrep "$badchars" )" ]; then
    if [ "$mode" = "irc" ]; then
      IRCOUTPUT="TRUE"
    fi
    OUTPUT="$NONSTANDARDCHAR"
    proc_cookies
    echo "$OUTPUT"
    exit 0
  fi

  if [ -z "$WHAT" -o "$ERROR" = "TRUE" ]; then
    if [ "$mode" = "irc" ]; then
      IRCOUTPUT="TRUE"
    fi
    OUTPUT="$NOARGUMENT"
    proc_cookies
    echo "$OUTPUT"
    AUTO="TRUE"
    exit 0
  fi

  if [ ! -d "$tmp" ]; then
    if [ "$mode" = "irc" ]; then
      echo "Error. Cant find $tmp. Create it and set 777 in it."
    else
      echo "Error. Cant find $glroot$tmp. Create it and set 777 in it."
    fi
    exit 0
  fi
  touch "$tmp/testtouch.tmp"
  if [ ! -e "$tmp/testtouch.tmp" ]; then
    if [ "$mode" = "irc" ]; then
      echo "Error. Cant write to $tmp. Check perms."
    else
      echo "Error. Cant write to $glroot$tmp. Check perms."
    fi
    exit 0
  fi
  rm -f $tmp/testtouch.tmp

}

## Does the reqfile exist and can we read it?
proc_checkfile() {
  if [ ! -e "$reqfile" ]; then
    echo "Can not find $reqfile. Create it and set proper perms on it (777)"
    exit 0
  fi
  if [ ! -w "$reqfile" ]; then
    echo "Found requestfile, but can not write to it. Set proper perms on it."
    exit 0
  fi
}

## Reorder reqfile so numbers are in order.
proc_reorder() {
  ## Can the reqfile be written to?
  if [ ! -w "$reqfile" ]; then
    echo "Cant read $reqfile for fix. Create it and/or set perms."
    exit 0
  fi

  ## Remove previous file just incase.
  if [ -e "$tmp/reorder.tmp" ]; then
    rm -f "$tmp/reorder.tmp"
  fi

  ## Count each line in the reqfile to see which number we should put on it.
  num=0
  for line in `cat $reqfile | tr -s ' ' '^' | tr -d ']' | tr -d '[' | cut -d':' -f2-`; do
    num=$[$num+1]
    if [ -z "$( echo "$num" | grep ".." )" ]; then
      newnum="[ $num:]"
    else
      newnum="[$num:]"
    fi

    ## Add requests to new reqfile.
    echo "$newnum $line" | tr -s '^' ' ' >> $tmp/reorder.tmp
  done

  ## Was any file created? Copy it if so. If not, no requests were found.
  if [ -e "$tmp/reorder.tmp" ]; then
    cp -f "$tmp/reorder.tmp" "$reqfile"
    rm -f "tmp/reorder.tmp"
    chmod 666 "$reqfile" >/dev/null 2>&1
  else
    ## Only say this if fix was run manually. Not when reqfilling etc.
    if [ "$name" = "fix" ]; then
      echo "No requests to fix was found."
    fi
  fi
}  

## Check for old requests.
proc_checkold() {
  if [ "$removedays" ]; then
    for line in `cat $reqfile | tr -s ' ' '^'`; do
      unset FIRST; unset SECOND; unset THIRD; unset GOTNAME; unset RELEASE
      unset SECONDSOLD; unset OLD; unset RELNUMBER; unset return_username
      if [ "$line" ]; then
        for each in `echo "$line" | tr -s '^' ' '`; do
          if [ "$GOTNAME" != "TRUE" ]; then
            if [ "$each" = "~" ]; then
              GOTNAME=TRUE
            else
              RELEASE="$each"
            fi
          fi

          if [ "$GOT_REQUESTER" != "TRUE" ]; then
            if [ "`echo "$each" | grep "^by$"`" ]; then
              GOT_REQUESTER="TRUE"
            fi
          else
            return_username="$each"
            unset GOT_REQUESTER
          fi

          FIRST="$SECOND"
          SECOND="$THIRD"
          THIRD="$each"

          ## Fixes depending on which date format is in the .requests file.
          if [ "$FIRST" = "at" ]; then
            unset FIRST
          fi
          if [ "`echo "$THIRD" | grep "^REWARD"`" ]; then
            unset THIRD
          fi

        done

        THIRD="$( echo "$THIRD" | tr -s '-' '/' )"
        SECONDSOLD="$( $datebin -d "$FIRST $SECOND $THIRD" +%s )"
        SECONDSMAX="$( $datebin -d "-$removedays day" +%s )"

        if [ "$SECONDSOLD" -lt "$SECONDSMAX" ]; then
          REAL_POSITION="$( echo "$line" | cut -d ']' -f1 )]"
          RELNUMBER="$( echo "$line" | cut -d ':' -f1 | tr -d '[' | tr -d ']' | tr -d ' ' | tr -d '^' )"
          OLD=TRUE

          ## Any reward offered? Find it, set REWARD to the value and return the credits to the requester.
          if [ "`echo "$line" | grep "\^REWARD:.*MB"`" ]; then
            temp_line="`echo "$line" | tr -s '^' ' '`"
            for each_line in $temp_line; do
              if [ "`echo "$each_line" | grep "^REWARD:"`" ]; then
                REWARD="`echo "$each_line" | cut -d ':' -f2 | tr -d '[:alpha:]'`"
                if [ "$REWARD" ]; then
                  break
                fi
              fi
            done

            current_credits_kb="`grep "^CREDITS\ " "$usersdir/$return_username" | cut -d ' ' -f2`"
            full_credits="`grep "^CREDITS\ " "$usersdir/$return_username" | cut -d ' ' -f2-`"
            add_credits_kb=$[$REWARD*1024]
            if [ "$current_credits_kb" ] && [ "$add_credits_kb" ]; then
              new_credits_kb=$[$current_credits_kb+add_credits_kb]
              if [ "$new_credits_kb" ]; then
                # echo "New credits: $new_credits_kb"
                NEWVALUES="`echo "$full_credits " | sed -e "s/[0-9]* /$new_credits_kb /"`"
                # echo "new values: $NEWVALUES"
                grep -v "^CREDITS\ " "$usersdir/$return_username" > "/tmp/${return_username}.tmp"
                echo "CREDITS $NEWVALUES" >> "/tmp/${return_username}.tmp"
                if [ -e "$usersdir/${return_username}.lock" ]; then
                  sleep 1
                fi
                cp -f "/tmp/${return_username}.tmp" "$usersdir/$return_username"
                rm -f "/tmp/${return_username}.tmp"
              fi
            fi

          fi

        fi
      fi

      ## This release is too old. Delete it.

      if [ "$OLD" = "TRUE" ]; then
        GOT_OLD_RELEASE="TRUE"
        if [ "$gllog" ]; then
          mode="gl"
          OUTPUT="$STATUSANNOUNCE"
          IRCOUTPUT="TRUE"
          proc_cookies
          proc_output "$OUTPUT $REAL_POSITION $RELEASE has been deleted because it's older than $removedays days."
        fi
        if [ -d "$requests/$requesthead$RELEASE" ]; then
          #rmdir "$requests/$requesthead$RELEASE" >/dev/null 2>&1
          rm -rf "$requests/$requesthead$RELEASE" >/dev/null 2>&1
        fi

        proc_log "REQDELAUTO: \"crontab deleted $RELEASE - older than $removedays days.\""
        if [ "$REWARD" ]; then
          proc_log "REQDELAUTOREWARD: \"Returned $REWARD MB to $return_username\""
        fi
 
        DEL_NUMBERS="$DEL_NUMBERS $REAL_POSITION"

      fi

    done

    ## Make a new file without the reqfilled ones and copy it over the old one.
    if [ "$GOT_OLD_RELEASE" = "TRUE" ]; then
      for REAL_POSITION in $DEL_NUMBERS; do
        REAL_POSITION="`echo "$REAL_POSITION" | tr '^' ' '`"
        grep -vF "$REAL_POSITION" "$reqfile" > $tmp/newreqfile.tmp
        cp -f "$tmp/newreqfile.tmp" "$reqfile"
        rm -f "$tmp/newreqfile.tmp"
      done
      ## Reorder new one so numbers are linear.
      proc_reorder

      ## Announce the remaining requests.
      if [ "$showonauto" = "TRUE" ]; then
        auto="auto"
        proc_status
      fi
    fi

  fi      

  if [ "$removefdays" ]; then
    if [ -d "$requests" ]; then

      if [ -z "$mustinclude" ]; then
        mustinclude="."
      fi
      if [ -z "$exclude" ]; then
        exclude="fejfklJ252452delj"
      fi
      if [ ! -x "$file_date" ]; then
        echo "Was going to check for old requests, but file_date ($file_date) is not executable."
        exit 0
      fi

      cd "${requests}/${filled_dir}"
      for dir in `ls | grep "$mustinclude" | egrep -v "$exclude"`; do
        # echo="checking $dir because its from $reldate"
        timestamp=`$file_date $dir`
        secsold=`$datebin -d "$timestamp" +%s`
        seclimit=`$datebin -d "-$removefdays day" +%s`
        if [ "$secsold" -lt "$seclimit" ]; then
          reldate=`$datebin -d "$timestamp" +%m%d`
          rm -rf "$dir"
          IRCOUTPUT="TRUE"
          if [ ! -e "$dir" ]; then
            if [ "$gllog" ]; then
              OUTPUT="$STATUSANNOUNCE"
              proc_cookies
              LINETOSAY="$OUTPUT Deleting $dir because its from $reldate"
              echo `$datebin "+%a %b %e %T %Y"` TURGEN: \"$LINETOSAY\" >> $gllog
              unset LINETOSAY
            fi
          else
            if [ "$gllog" ]; then
              OUTPUT="$STATUSANNOUNCE"
              proc_cookies
              LINETOSAY="$OUTPUT Was going to delete $dir because its from $reldate, but seems I couldnt."
              echo `$datebin "+%a %b %e %T %Y"` TURGEN: \"$LINETOSAY\" >> $gllog
              unset LINETOSAY
            fi
          fi
        fi
      done
    else
      echo "Should have checked for old requests, but $requests wasnt found or not a dir."
    fi
  fi
}

## Make a request.
proc_request() {

  proc_checkfile

  if [ "$date_format_in_reqfile" = "NEW" ]; then
    adddate="`$datebin +%Y'-'%m'-'%d' '%H':'%M`"
  elif [ "$date_format_in_reqfile" = "OLD" ]; then
    adddate="$( $datebin +%r" "%x | tr -s '/' '-' )"
  else
    echo "Error in config. date_format_in_reqfile should be set to either NEW or OLD"
    exit 0
  fi

  ## Dont mess with these ones.
  REQINFILE="%NUM% %WHAT% ~ by %WHO% (%MODE%) at %ADDDATE%"
  REQINFILE2="%NUM% %WHAT% ~ by %WHO% (%MODE%) for %FOR% at %ADDDATE%"

  ## If requesthead is set, is there already a dir with this name ?
  if [ "$requesthead" ]; then
    if [ -d "$requests/$requesthead$WHAT" ]; then
      if [ "$mode" = "irc" ]; then
        IRCOUTPUT="TRUE"
      fi
      OUTPUT="$ALREADYREQUESTED"
      proc_cookies
      echo "$OUTPUT"
      exit 0
    fi
  fi

  if [ "`$dirloglist_gl | grep -iv "STATUS: 3" | grep "/$WHAT$"`" ]; then
    if [ "$mode" = "gl" ]; then
        echo "Release already exist on site: `$dirloglist_gl | grep -iv "STATUS: 3" | grep "/$WHAT$" | tr -s "[:blank:]" "-" | sed 's/STATUS:-[0-2]-DIRNAME:-\/site//'`"
    else
        echo "14Release already exist on site: 4`$dirloglist_gl | grep -iv "STATUS: 3" | grep "/$WHAT$" | tr -s "[:blank:]" "-" | sed 's/STATUS:-[0-2]-DIRNAME:-\/site//'`"
    fi
    exit 0
  fi

  ## Is it already requested in file ? This one needs work to recognize . as a char.
  if [ "$( cat $reqfile | cut -c5- | grep -w -- "$WHAT " )" ]; then
    if [ "$mode" = "irc" ]; then
      IRCOUTPUT="TRUE"
    fi
    OUTPUT="$ALREADYREQUESTED"
    proc_cookies
    echo "$OUTPUT"
    exit 0
  else
    ## Figure out which number its gonna get.
    num=1
    for each in `cat $reqfile | tr -s ' ' '^'`; do
      num=$[$num+1]
    done

    if [ "$max_requests" ]; then
      if [ "`cat $reqfile | wc -l | tr -d ' '`" -ge "$max_requests" ]; then
        OUTPUT="$TOOMANYREQUESTS"
        proc_cookies
        echo "$OUTPUT"
        exit 0
      fi
    fi

    if [ -z "$( echo "$num" | grep ".." )" ]; then
      num="\[ $num:\]"
    else
      num="\[$num:\]"
    fi

    ## If REWARD is set and REWARD_FREE is not TRUE, check if the user has leech. Dont allow if if so.
    if [ "$REWARD" ] && [ "$REWARD_FREE" != "TRUE" ]; then
      if [ "`grep "^RATIO\ 0" "$usersdir/$username"`" ]; then
        echo "You have leech and can not set a reward unless a siteop approves it in the config."
        exit 0
      fi
    fi

    ## Announce it unless gllog is empty ( not set ).
    if [ "$gllog" ]; then
      if [ -w "$gllog" ]; then
        if [ "$HIDE" != "TRUE" ]; then
          RELEASE="$num $WHAT"

          if [ "$FOR" ]; then
            OUTPUT="$REQANNOUNCE2"
          else
            OUTPUT="$REQANNOUNCE"
          fi
          IRCOUTPUT="TRUE"
          proc_cookies

          ## Since this is from private message to bot, we need to write to glftpd.log instead of
          ## just echoing it to screen. Otherwise it goes back to private mess and we want to announce
          ## when something is requested.
          if [ "$mode" = "irc" ]; then
            TEMPCHANGE="TRUE"
            mode="gl"
          fi

          ## Announce it.
          proc_output "$OUTPUT"

          ## If a reward was added, announce that as well.
          if [ "$REWARD" ]; then
            OUTPUT="$REQANNOUNCE_REWARD"
            proc_cookies
            proc_output "$OUTPUT"
          fi

          IRCOUTPUT="FALSE"

          ## Change back the mode to irc if it was that to start with.
          if [ "$TEMPCHANGE" = "TRUE" ]; then
            mode="irc"
            unset TEMPCHANGE
          fi

        fi
      else
        echo "Error. Cant write to $gllog. Check paths and perms."
        exit 0
      fi
    fi

    ## Say "request added". Take output from GLOK. Only from glftpd. irc is handled in botscript.
    if [ "$mode" = "gl" ]; then
      if [ "$mode" = "irc" ]; then
        IRCOUTPUT="TRUE"
      fi
      OUTPUT="$GLOK"
      proc_cookies
      echo "$OUTPUT"
    fi

    ## Create the dir.
    if [ "$requesthead" ] && [ "$do_not_create_dir_until_filled" != "TRUE" ]; then
      mkdir -m777 "$requests/$requesthead$WHAT"
    fi

    ## Log it.
    if [ "$REWARD" ]; then
      if [ "$REWARD_FREE" = "TRUE" ]; then
        proc_log "REQUEST: \"$BY requested $WHAT with ${REWARD}MB reward (free. No deduction).\""
      else
        proc_log "REQUEST: \"$BY requested $WHAT with ${REWARD}MB reward.\""
      fi
    else
      proc_log "REQUEST: \"$BY requested $WHAT\""
    fi

    IRCOUTPUT="TRUE"
    if [ "$FOR" ]; then
      OUTPUT="$REQINFILE2"
    else
      OUTPUT="$REQINFILE"
    fi
    proc_cookies

    if [ "$REWARD" ]; then
      echo "$OUTPUT REWARD:${REWARD}MB" >> $reqfile
    else
      echo "$OUTPUT" >> $reqfile
    fi
    chmod 666 "$reqfile" > /dev/null 2>&1

    ## If REWARD is set and REWARD_FREE is not TRUE, remove the MB from the user.
    if [ "$REWARD" ] && [ "$REWARD_FREE" != "TRUE" ]; then
      REWARD_KB=$[$REWARD*1024]
      current_credits="`grep "^CREDITS " "$usersdir/$username" | cut -d ' ' -f2`"

      full_credits="`grep "^CREDITS " "$usersdir/$username" | cut -d ' ' -f2-`"

      new_credits=$[$current_credits-$REWARD_KB]
      # echo "Will deduct: $REWARD_KB kb"
      # echo "Current    : $current_credits"
      # echo "New credits: $new_credits"

      NEWVALUES="`echo "$full_credits " | sed -e "s/[0-9]* /$new_credits /"`"
      # echo "OLD: $full_credits"
      # echo "NEW: $NEWVALUES"
      grep -v "^CREDITS " "$usersdir/$username" > "$tmp\$username.tmp"
      echo "CREDITS $NEWVALUES" >> "$tmp\$username.tmp"
      retries=1
      if [ -e "$usersdir/$username.lock" ]; then
        # echo "Found a lockfile on your account. Please hold."
        while [ -e "$usersdir/$username.lock" ]; do
          retries=$[$retries+1]
          sleep 1
          if [ ! -e "$usersdir/$username.lock" ]; then
            break
          fi
          if [ "$retries" -ge "10" ]; then
            rm -f "$usersdir/$username.lock"
            break
          fi
        done
      fi
      cp -f "$tmp\$username.tmp" "$usersdir/$username"
      rm -f "$tmp\$username.tmp" 
    fi

    if [ "$showonrequest" = "TRUE" ]; then
      proc_status
    fi

    exit 0

  fi
} ## End of proc_request.


proc_reqfilled() {
  proc_checkfile

   if [ -z "$WHAT" ]; then
     echo "Specify the name or number when reqfilling."
     exit 0
   fi

  ## Is it requested? (check by number)
  if [ -z "`echo "$WHAT" | tr -d '[:digit:]'`" ]; then
    if [ -z "$( echo "$WHAT" | grep ".." )" ]; then
      WHATNEW="[ $WHAT:]"
    else
      WHATNEW="[$WHAT:]"
    fi
  fi
  
  ## By default we pretend it was found in the request list. Will be set to FALSE if its actually not, below.
  REQUEST_FOUND="TRUE"

  if [ -z "`echo "$WHAT" | tr -d '[:digit:]'`" ]; then
    ## Check if requested by number
    if [ -z "$( cat $reqfile | cut -d ':' -f1 | cut -d '~' -f1 | tr -d '[' | tr -d ']' | grep -w -- "$WHAT" )" ]; then
      REQUEST_FOUND="FALSE"
    fi
  else
    ## Check if requested by name
    if [ -z "$( cat $reqfile | cut -d ']' -f2 | cut -d '~' -f1 | cut -c2- | grep -w -- "$WHAT" )" ]; then
      REQUEST_FOUND="FALSE"
    else

      ## It WAS requested by name. Extract the number of the release.
      WHATNEW="$( cat $reqfile | grep "\[[\ |0-9][0-9]:\] $WHAT \~" | cut -d ']' -f1 | head -n1 )"

      if [ -z "$WHATNEW" ]; then
        echo "Internal Error: Found the $WHAT request in the list but failed to extract its number.."
        echo "Use the number instead."
        exit 0
      fi

      ## Add a ] at the end of it.
      WHATNEW="${WHATNEW}]"
      if [ "$mode" = "gl" ]; then
        echo "Request number for $WHAT seems to be: $WHATNEW"
      fi
    fi
  fi

  if [ "$REQUEST_FOUND" = "FALSE" ]; then
    if [ "$mode" = "irc" ]; then
      IRCOUTPUT="TRUE"
    fi
    OUTPUT="$NOTREQUESTED"
    proc_cookies
    echo "$OUTPUT"
    exit 0
  else

    LINETODEL="$( grep -F "${WHATNEW}" "$reqfile" | head -n1 )"

    ## Verify that the number we got from the search really is the correct one.
    if [ "`echo "$LINETODEL" | cut -c1-5`" != "$WHATNEW" ]; then
      echo "Error. Searched for $WHATNEW but got $LINETODEL"
      echo "Aborting. Report this to author."
      exit 0
    else
      if [ "$mode" = "gl" ]; then
        echo "Verified selected row from requests file."
      fi
    fi

    ## Grab who its for (if any) and who made the request.
    if [ "$( echo "$LINETODEL" | grep " for " )" ]; then
      REQUESTFOR=`echo "$LINETODEL" | cut -d ')' -f2 | cut -d ' ' -f3`
    fi
    REQUESTBY=`echo "$LINETODEL" | cut -d '~' -f2- | cut -d ' ' -f3`

    ## Get release name.
    RELEASE=`echo "$LINETODEL" | cut -d ':' -f2 | cut -d '~' -f1 | cut -c2-`
    RELEASE=`echo $RELEASE` ## Clean it up from initial and ending spaces.

    if [ "$enable_rewardsystem" = "TRUE" ]; then
      ## Any reward offered? Find it, set REWARD to the value.
      if [ "`echo "$LINETODEL" | grep "\ REWARD:.*MB"`" ]; then
        for each_line in $LINETODEL; do
          if [ "`echo "$each_line" | grep "^REWARD:"`" ]; then
            REWARD="`echo "$each_line" | cut -d ':' -f2 | tr -d '[:alpha:]'`"
            if [ "$REWARD" ]; then
              break
            fi
          fi
        done
      fi
    fi

    case $name in
      reqfill)

        ## Fix the dir..
        if [ "$requesthead" ] && [ "$do_not_create_dir_until_filled" = "TRUE" ]; then
          mkdir -m777 "$requests/$filledhead$RELEASE"
          if [ "$REWARD" ]; then
            proc_reward
          fi
        elif [ "$requesthead" ]; then

          if [ -d "$requests/$requesthead$RELEASE" ]; then

            ## Check that its not empty.
            if [ -z "`ls -1 "$requests/$requesthead$RELEASE"`" ]; then
              if [ "$mode" = "gl" ]; then
                echo "$REQFILLEDEMPTY"
              else
                IRCOUTPUT="TRUE"
                OUTPUT="$REQFILLEDEMPTYIRC"
                proc_cookies
                echo "$OUTPUT"
              fi
              exit 0
            fi

            ## If the filled dir already exists, add a number to the end of it.
            if [ -e "$requests/${filled_dir}$filledhead$RELEASE" ]; then
              num=0; unset NUMBER; unset NOMOVE
              while [ -e "$requests/${filled_dir}$filledhead$RELEASE$NUMBER" ]; do
                num=$[$num+1]
                NUMBER=$num
                if [ "$NUMBER" -gt "20" ]; then
                  NOMOVE=TRUE
                  break
                fi
              done
              if [ "$NOMOVE" != "TRUE" ]; then
                mv -f "$requests/$requesthead$RELEASE" "$requests/${filled_dir}$filledhead$RELEASE$NUMBER"
                COMPLETE_REQUEST="$requests/${filled_dir}$filledhead$RELEASE$NUMBER"
              fi
            else
              ## All ok, just move the dir.
              mv -f "$requests/$requesthead$RELEASE" "$requests/${filled_dir}$filledhead$RELEASE"
              COMPLETE_REQUEST="$requests/${filled_dir}$filledhead$RELEASE"
            fi

            if [ "$REWARD" ]; then
              proc_reward
            fi

          else
            if [ "$mode" = "gl" ]; then
              requestname=`basename $requests`
              echo "$requesthead$RELEASE was not found in $requestname. Skipping rename of dir!"
              unset requestname
            fi
          fi
        fi

        if [ "$mode" = "gl" ]; then
          echo "$WHAT : $RELEASE has been filled. Thank you."
        fi

        proc_sendmsg "reqfilled" "Go fetch!"
        ACTION="reqfilled" ## Action for irc announce
        proc_log "REQFILL: \"$BY filled $RELEASE\""
        if [ "$REWARD_LIST" ]; then
          REWARD_LIST_TEMP="`echo "$REWARD_LIST" | tr '=' '/'`"
          proc_log "REQFILLREWARD: \"Rewarded: $total_users users - $total_files files : $REWARD_LIST_TEMP\""
        fi
        ;;

      reqdel)
        if [ "`echo "$BY" | grep -i "^$REQUESTBY$"`" ]; then
          ## Say this to glftpd in either case.

          if [ -d "$requests/$requesthead$RELEASE" ]; then
            rmdir "$requests/$requesthead$RELEASE" >/dev/null 2>&1
          fi

          if [ "$REWARD" ]; then
            COMPLETE_REQUEST="RETURN-$REQUESTBY"
            proc_reward
          fi

          proc_sendmsg "deleted" "Sorry!"
          ACTION="reqdelled" ## Action for irc announce
          proc_log "REQDEL: \"$BY deleted -reqdel- $RELEASE\""
          if [ "$REWARD" ]; then
            proc_log "REQDELREWARD: \"$REWARD MB returned to $REQUESTBY"
          fi

          if [ "$mode" = "gl" ]; then
            echo "$WHAT : $RELEASE has been deleted."
          fi

        else
          echo "Permission denied. $RELEASE requested by $REQUESTBY, not $BY"
          exit 0
        fi
        ;;

      reqwipe) 
        if [ -d "$requests/$requesthead$RELEASE" ]; then
          rm -rf "$requests/$requesthead$RELEASE"
        else
          echo "Gee, I would love to wipe out $RELEASE, but there is no such dir."
        fi
        if [ "$REWARD" ]; then
          COMPLETE_REQUEST="RETURN-$REQUESTBY"
          proc_reward
        fi

        if [ "$mode" = "gl" ]; then
          echo "Wiped out $requests/$requesthead$RELEASE"
        fi

        proc_sendmsg "wiped" "Sorry!"
        ACTION="reqwiped" ## Action for irc announce
        proc_log "REQWIPE: \"$BY wiped -reqwipe- $RELEASE\""
        if [ "$REWARD" ]; then
          proc_log "REQWIPEREWARD: \"$REWARD MB returned to $REQUESTBY"
        fi
        ;;

    esac

    ## Make a new file without the reqfilled one and copy it over the old one.

    grep -vF "$WHATNEW" "$reqfile" > $tmp/newreqfile.tmp
    if [ -e "$tmp/newreqfile.tmp" ]; then
      cp -f "$tmp/newreqfile.tmp" "$reqfile"
      rm -f "$tmp/newreqfile.tmp"
      chmod 666 "$reqfile" >/dev/null 2>&1
    else
      echo "Error: $tmp/newreqfile.tmp was not created."
      exit 0
    fi

    ## Reorder new one so numbers are linear.
    proc_reorder

    if [ "$gllog" ]; then
      if [ -w "$gllog" ]; then
        if [ "$HIDE" != "TRUE" ]; then
          IRCOUTPUT="TRUE"

          case $ACTION in
            reqfilled) OUTPUT="$FILLANNOUNCE" ;;
            reqdelled) OUTPUT="$FILLANNOUNCE_DEL" ;;
            reqwiped) OUTPUT="$FILLANNOUNCE_WIPE" ;;
            *) OUTPUT="$FILLANNOUNCE" ;;
          esac

          proc_cookies

          if [ "$mode" = "irc" ] && [ "$MODE" != "reqfilled" ]; then
            TEMPCHANGE="TRUE"
            mode="gl"
          fi

          proc_output "$OUTPUT"
          if [ "$REWARD_LIST" ]; then
            OUTPUT="$FILLANNOUNCE_REWARD"
            proc_cookies
            proc_output "$OUTPUT"
          fi

          IRCOUTPUT="FALSE"

          if [ "$TEMPCHANGE" = "TRUE" ]; then
            mode="irc"
          fi

        fi
      else
        echo "Error. Cant write to $gllog. Check paths and perms."
        exit 0
      fi
    fi

    if [ "$showonfill" = "TRUE" ] && [ "$HIDE" != "TRUE" ]; then
      proc_status
    fi
  fi
}

proc_reward() {
  if [ -z "$REWARD" ]; then
    echo "Internal error. Proc_reward did not get a provided REWARD value"
    exit 0
  fi

  if [ -z "$COMPLETE_REQUEST" ]; then
    echo "Internal error. Proc_reward did not get a provided COMPLETE_REQUEST value."
    exit 0
  fi

  ## If the first part of COMPLETE_REQUEST is RETURN (RETURN-username), it will give the full
  ## reward to that guy instead of trying to split it up. Used for reqdel.
  if [ "`echo "$COMPLETE_REQUEST" | cut -d '-' -f1`" = "RETURN" ]; then
    return_username="`echo "$COMPLETE_REQUEST" | cut -d '-' -f2-`"
    # echo "returning creds to requester: $return_username"
    if [ ! -e "$usersdir/$return_username" ]; then
      echo "Was going to return $REWARD MB to $return_username, but that user does not exist."
    else
      REWARD_FREE="FALSE"
      ## No decuction when using -reward:? Check by flag.
      if [ "$reward_free_flags" ]; then
        reward_free_flags="`echo "$reward_free_flags" | tr -s ' ' '|'`"
        if [ "`grep "^FLAGS " "$usersdir/$return_username" | cut -d ' ' -f2 | egrep "$reward_free_flags"`" ]; then
          REWARD_FREE="TRUE"
        fi
      fi

      ## Remake userlist to add ^ $ to each defined user for perfect matches.
      ## No decuction when using -reward:? Check by username
      if [ "$reward_free_users" ]; then
        FIX_LIST="$reward_free_users"
        proc_make_egrep_list
        reward_free_users="$FIXED_LIST"; unset FIXED_LIST

        ## Check if username matches.
        if [ "`echo "$return_username" | egrep "$reward_free_users"`" ]; then
          REWARD_FREE="TRUE"
        fi
      fi


      ## Only return credits if it wasnt free when requesting.
      if [ "$REWARD_FREE" != "TRUE" ]; then
        current_credits_kb="`grep "^CREDITS\ " "$usersdir/$return_username" | cut -d ' ' -f2`"
        full_credits="`grep "^CREDITS\ " "$usersdir/$return_username" | cut -d ' ' -f2-`"
        add_credits_kb=$[$REWARD*1024]
        if [ "$current_credits_kb" ] && [ "$add_credits_kb" ]; then
          new_credits_kb=$[$current_credits_kb+add_credits_kb]
          if [ "$new_credits_kb" ]; then
            # echo "New credits: $new_credits_kb"
            NEWVALUES="`echo "$full_credits " | sed -e "s/[0-9]* /$new_credits_kb /"`"
            # echo "new values: $NEWVALUES"
            grep -v "^CREDITS\ " "$usersdir/$return_username" > "/tmp/${return_username}.tmp"
            echo "CREDITS $NEWVALUES" >> "/tmp/${return_username}.tmp"
            if [ -e "$usersdir/${return_username}.lock" ]; then
              sleep 1
            fi
            cp -f "/tmp/${return_username}.tmp" "$usersdir/$return_username"
            rm -f "/tmp/${return_username}.tmp"
          fi
        fi
      fi
    fi
  else
    if [ ! -d "$COMPLETE_REQUEST" ]; then
      echo "Error. Proc_reward reports that $COMPLETE_REQUEST does not exist. Can not give reward."
      exit 0
    else
      cd "$COMPLETE_REQUEST"
      proc_find_and_give
    fi
  fi
}

proc_find_and_give() {
 total_files="0"
 total_users="0"

  # Create list from maindir. New file made here. Others add to it.
  $tuls | tr -d ' ' | egrep -v "::::\.::::|::::\.\.::::|^d" | tr -s ':' ' ' > /tmp/reqlist.tmp
  # echo "Grabbing files from $PWD"

  for each_subdir in `$tuls | grep "^d" | egrep -v "::::\.::::|::::\.\.::::" | tr -d ' ' | tr -s ':' | cut -d ':' -f4`; do
    if [ -d "$each_subdir" ]; then
      cd "$each_subdir"
      # echo "entering $each_subdir"
      $tuls | tr -d ' ' | egrep -v "::::\.::::|::::\.\.::::|^d" | tr -s ':' ' ' >> /tmp/reqlist.tmp
      for each_subdir_2 in `$tuls | grep "^d" | egrep -v "::::\.::::|::::\.\.::::" | tr -d ' ' | tr -s ':' | cut -d ':' -f4`; do
        if [ -d "$each_subdir_2" ]; then
          cd "$each_subdir_2"
          # echo "entering $each_subdir_2"
          $tuls | tr -d ' ' | egrep -v "::::\.::::|::::\.\.::::|^d" | tr -s ':' ' ' >> /tmp/reqlist.tmp

          for each_subdir_3 in `$tuls | grep "^d" | egrep -v "::::\.::::|::::\.\.::::" | tr -d ' ' | tr -s ':' | cut -d ':' -f4`; do
            if [ -d "$each_subdir_3" ]; then
              cd "$each_subdir_3"
              # echo "entering $each_subdir_3"
              $tuls | tr -d ' ' | egrep -v "::::\.::::|::::\.\.::::|^d" | tr -s ':' ' ' >> /tmp/reqlist.tmp
              cd ..
              # echo "jumping back to $PWD"
            fi
          done
          cd ..
          # echo "jumping back to $PWD"
        fi
      done
      cd ..
      # echo "jumping back to $PWD"
    fi
  done

  if [ -e "/tmp/reqlist.tmp" ]; then
    # cat /tmp/reqlist.tmp | sort -k2,2 -n | tr ' ' ':' >> /tmp/reqlist.tmp2
    ## Sort the list
    cat /tmp/reqlist.tmp | sort -k2,2 -n | tr ' ' ':' > /tmp/reqlist.tmp2
    rm -f /tmp/reqlist.tmp 
  else
    echo "dummy_so_cat_dosnt_fuck_up" > /tmp/reqlist.tmp2
  fi

  for rawdata in `cat /tmp/reqlist.tmp2`; do
    filename="`echo "$rawdata" | cut -d ':' -f4`"
    if [ "`echo "$filename" | egrep -i "$reward_count"`" ]; then
      total_files=$[$total_files+1]
      uid="`echo "$rawdata" | cut -d ':' -f2`"
      if [ "$last_uid" != "$uid" ]; then
        total_users=$[$total_users+1]
      fi
      # echo "$filename $uid"
      last_uid="$uid"
    fi
  done
  unset last_uid

  user="0"
  for rawdata in `cat /tmp/reqlist.tmp2`; do
    filename="`echo "$rawdata" | cut -d ':' -f4`"
    if [ "`echo "$filename" | egrep -i "$reward_count"`" ]; then
      uid="`echo "$rawdata" | cut -d ':' -f2`"

      ## First user in list get one.
      if [ -z "$last_uid" ]; then
        files_for_uid="1"
        last_uid="$uid"
      else
        if [ "$last_uid" = "$uid" ]; then
          files_for_uid=$[$files_for_uid+1]
          # echo "files for $uid : $files_for_uid"
        else
          # echo "Total files for $last_uid: $files_for_uid"
          proc_reward_uid
          unset last_uid
          files_for_uid=1
        fi
      fi
      last_uid="$uid"
    fi
  done
  # echo "Total files for $uid: $files_for_uid"
  proc_reward_uid      
  # echo ""
  # echo "$REWARD_LIST"
  rm -f "/tmp/reqlist.tmp2"

  # echo "total      : $total_files"
  # echo "total users: $total_users"
  if [ "$leechers" ]; then
    if [ "$leechers" = "1" ]; then
      total_users="$total_users($leechers leecher)"
    else
      total_users="$total_users($leechers leechers)"
    fi
  fi
  last_subdir="$subdir"
}

proc_reward_uid() {
  # echo "uid        : $last_uid"
  # echo "files      : $files_for_uid"
  # echo "total_files: $total_files"
  # echo "reward     : $REWARD"
  total_reward_for_uid=$[$REWARD/$total_files*$files_for_uid]
  # echo "Reward uid : $total_reward_for_uid"
  reward_username="`grep "^.*:.*:${last_uid}:" "$passwd" | cut -d ':' -f1 | head -n1`"
  # echo "username   : $reward_username"

  if [ "$reward_username" ]; then
    ## Check if RATIO is not 0 (leech).
    if [ "`grep "^RATIO " "$usersdir/$reward_username" | grep "0"`" ]; then
      if [ -z "$leechers" ]; then
        leechers="1"
      else
        leechers=$[$leechers+1]
      fi
    else
      # echo "Giving $reward_username $total_reward_for_uid MB credits"
      current_credits_kb="`grep "^CREDITS\ " "$usersdir/$reward_username" | cut -d ' ' -f2`"
      full_credits="`grep "^CREDITS\ " "$usersdir/$reward_username" | cut -d ' ' -f2-`"
      add_credits_kb=$[$total_reward_for_uid*1024]
      if [ "$current_credits_kb" ] && [ "$add_credits_kb" ]; then
        new_credits_kb=$[$current_credits_kb+add_credits_kb]
        if [ "$new_credits_kb" ]; then
          # echo "New credits: $new_credits_kb"
          NEWVALUES="`echo "$full_credits " | sed -e "s/[0-9]* /$new_credits_kb /"`"
          # echo "new values: $NEWVALUES"
          grep -v "^CREDITS\ " "$usersdir/$reward_username" > "/tmp/${reward_username}.tmp"
          echo "CREDITS $NEWVALUES" >> "/tmp/${reward_username}.tmp"
          if [ -e "$usersdir/${reward_username}.lock" ]; then
            sleep 1
          fi
          cp -f "/tmp/${reward_username}.tmp" "$usersdir/$reward_username"
          rm -f "/tmp/${reward_username}.tmp"
        fi
      fi

      # echo "current credits: $current_credits_kb"

      # echo ""
      if [ -z "$REWARD_LIST" ]; then
        REWARD_LIST="[ $reward_username=${files_for_uid}F=${total_reward_for_uid}MB ]"
      else
        REWARD_LIST="$REWARD_LIST [ $reward_username=${files_for_uid}F=${total_reward_for_uid}MB ]"
      fi
    fi
  fi
}

proc_status() {
  if [ "$auto" = "auto" ]; then
    AUTO=TRUE
    mode="gl"
  fi

  if [ "$mode" = "irc" ]; then

    if [ "`echo "$arg1" | egrep -i "^request$|^reqdel$|^reqwipe$"`" ]; then
      AUTO=TRUE
      mode="gl"
    fi

    IRCOUTPUT="TRUE"
    ## Make HEADER ##
    OUTPUT="$STATUSANNOUNCE"
    proc_cookies
    HEADER="$OUTPUT"
  else
    IRCOUTPUT="FALSE"
  fi

  for each in `cat $reqfile | tr -s ' ' '^'`; do
    FOUNDONE="TRUE"

    ## Header stuff.
    if [ "$SAIDIT" != "TRUE" -a "$STATUSHEAD" != "" -a "$NOHEADFOOT" != "TRUE" -a "$HIDE" != "TRUE" ]; then
      OUTPUT="$STATUSHEAD"
      proc_cookies
      ## If its running 'status auto', always go to irc.
      if [ "$AUTO" = "TRUE" ]; then
        proc_output "$HEADER $OUTPUT"
      else
        echo "$HEADER $OUTPUT"
      fi
      SAIDIT="TRUE"

    fi

    ## Request. One per line in file.

    LINETOSAY=`echo "$each" | tr -s '^' ' '`
    OUTPUT="$LINETOSAY"
    proc_cookies
    if [ "$AUTO" = "TRUE" ]; then
      proc_output "$HEADER $OUTPUT"
    else
      echo "$HEADER $OUTPUT"
    fi

    unset LINETOSAY
  done
  unset SAIDIT

  ## Footer stuff.
  if [ "$FOUNDONE" != "TRUE" -a "$AUTO" != "TRUE" -a "$HIDE" != "TRUE" ]; then
    if [ "$mode" = "irc" ]; then
      IRCOUTPUT="TRUE"
    fi
    OUTPUT="$NOREQUESTS"
    proc_cookies
    if [ "$AUTO" = "TRUE" ]; then
      proc_output "$HEADER $OUTPUT"
    else
      echo "$HEADER $OUTPUT"
    fi
  fi

  if [ "$FOUNDONE" = "TRUE" -a "$TOFILL" != "" -a "$NOHEADFOOT" != "TRUE" -a "$HIDE" != "TRUE" ]; then
    if [ "$mode" = "irc" ]; then
      IRCOUTPUT="TRUE"
    fi
    OUTPUT="$TOFILL"
    proc_cookies
    if [ "$AUTO" = "TRUE" ]; then
      proc_output "$HEADER $OUTPUT"
    else
      echo "$HEADER $OUTPUT"
    fi
  fi
}

proc_sendmsg() {
  if [ "$msgsdir" ]; then
    if [ "$REQUESTFOR" ]; then

      if [ -e "$usersdir/$REQUESTFOR" ]; then
        ## -for: was specified. Sending message to that user.
        echo "--------------------------------------------------------------------------" >> $msgsdir/$REQUESTFOR
        echo "$RELEASE was requested by $REQUESTBY for you. $BY just $1 it. $2." >> $msgsdir/$REQUESTFOR
        echo "!HThis message was generated by Tur-Request $VER!0" >> $msgsdir/$REQUESTFOR
        echo " " >> $msgsdir/$REQUESTFOR
        chmod 666 $msgsdir/$REQUESTFOR >/dev/null 2>&1
      fi

      ## cc is TRUE. Sending a carbon copy to the requester.
      if [ "$cc" = "TRUE" -a "$REQUESTBY" ]; then
        if [ -e "$usersdir/$REQUESTBY" ]; then
          if [ "$BY" != "$REQUESTBY" ]; then
            echo "--------------------------------------------------------------------------" >> $msgsdir/$REQUESTBY
            echo "You requested $RELEASE for $REQUESTFOR. This has been $1 by $BY." >> $msgsdir/$REQUESTBY
            echo "!HThis message was generated by Tur-Request $VER!0" >> $msgsdir/$REQUESTBY
            echo " " >> $msgsdir/$REQUESTBY
            chmod 666 $msgsdir/$REQUESTBY >/dev/null 2>&1
          fi
        fi
      fi

    else
      ## No -for: was specified. Its for himself.
      if [ "$REQUESTBY" ]; then
        if [ -e "$usersdir/$REQUESTBY" ]; then
          if [ "$REQUESTBY" != "$BY" ]; then
            echo "--------------------------------------------------------------------------" >> $msgsdir/$REQUESTBY
            echo "Your request for $RELEASE has been $1 by $BY. $2!" >> $msgsdir/$REQUESTBY
            echo "!HThis message was generated by Tur-Request $VER!0" >> $msgsdir/$REQUESTBY
            echo " " >> $msgsdir/$REQUESTBY
            chmod 666 $msgsdir/$REQUESTBY >/dev/null 2>&1
          fi
        fi
      fi
    fi

  fi
}

## Here there be main menu, yar.
case $RUN in
  request) name="request"; proc_verify; proc_request ;;
  reqfilled) name="reqfill"; proc_verify; proc_reqfilled ;;
  reqdel) name="reqdel"; reqdel=TRUE; proc_verify; proc_reqfilled ;;
  reqwipe) name="reqwipe"; reqwipe=TRUE; proc_verify; proc_reqfilled ;;
  status) name="status"; auto="$2"; proc_status ;;
  fix) name="fix"; proc_reorder ;;
  checkold) name="checkold"; proc_checkfile; proc_checkold ;;
  *) echo "Hm, didnt get any reasonable action (${@}). Dont run this from shell." ;;
esac

exit 0
