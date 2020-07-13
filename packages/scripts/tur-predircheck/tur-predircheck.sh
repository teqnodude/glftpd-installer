#!/bin/bash
VER=1.4.1

#--[ Different Case Settings ]----------------------------------------#

SKIPSECTIONS="/PRE|/REQUESTS|/ARCHIVE"

SKIPUSERS=""
SKIPGROUPS=""
SKIPFLAGS=""

#--[ On Site Before Settings ]----------------------------------------#

NUKE_PREFIX=""

DIRLOGLIST_GL="/bin/dirloglist_gl"

SKIPDIRS="^sample$|^Dis[ck][0-9]$|^vobsub$|^extra$|^cover$|^sub$|^subs$|^bonus$|^approved$|^allowed$|^CD[0-9]$|^proof$|^DVD[0-9]$|^Tools$|^Covers$"

ALLOWFILE=/tmp/tur-predircheck.allow

#--[ Other Settings ]-------------------------------------------------#

DENYGROUPS=""

DENYDIRS="
/site:^\[NUKED\]\-|^\[INCOMPLETE\]\-
"

ALLOWDIRS=""

ALLOWDIRS_OVERRULES_DENYGROUPS=FALSE
ALLOWDIRS_OVERRULES_DENYDIRS=FALSE

#--[ Error Output ]---------------------------------------------------#

## $1 = CreateDir, $2 = InPath
ERROR1="$1 already exists with a different case structure. Skipping."
ERROR2="$1 is already on site or was nuked. Wanker."
ERROR3="Denying creation of $1. This group is BANNED!"
ERROR4="Denying creation of $1. Watch what you're doing!"
ERROR5="Denying creation of $1. Not allowed group/release."

DEBUG=FALSE

GLLOG=/ftp-data/logs/glftpd.log

bold=""
lred=4
ldgry=14
IERROR1="${lred}$USER ${ldgry}tried to create ${lred}$1 ${ldgry}which already exists with a different case structure."
IERROR2="${lred}$USER ${ldgry}tried to create ${lred}$1 ${ldgry}which is already on site or was nuked."
IERROR3="${lred}$USER ${ldgry}tried to create ${lred}$1 ${ldgry}which is from a BANNED GROUP."
IERROR4="${lred}$USER ${ldgry}tried to create ${lred}$1 ${ldgry}but was denied."
IERROR5="${lred}$USER ${ldgry}tried to create ${lred}$1 ${ldgry}which isnt an allowed group or release."


#--[ Script Start ]---------------------------------------------------#

proc_debug() {
  if [ "$DEBUG" = "TRUE" ]; then
    echo "#0PreDirCheck: $@"
  fi
}

proc_announce() {
  if [ "$GLLOG" ]; then
    if [ ! -w "$GLLOG" ]; then
      proc_debug "Error. Can not write to $GLLOG"
    else
      proc_debug "Sending to gllog: $OUTPUT"
      echo `date "+%a %b %e %T %Y"` PREDIRCHECK: \"$OUTPUT\" >> $GLLOG
    fi
  fi
}

if [ -z "$1" -o -z "$2" ]; then
  proc_debug "Stop & Allow: Didnt get 2 arguments."
  exit 0
fi

if [ "$DEBUG" = "TRUE" ]; then
  if [ "$DIRLOGLIST_GL" ]; then
    if [ ! -x "$DIRLOGLIST_GL" ]; then
      proc_debug "ERROR: Cant execute DIRLOGLIST_GL: $DIRLOGLIST_GL"
      exit 1
    fi    
    proc_debug "Testing dirloglist_gl binary. Should output 5 last lines in dirlog."
    for rawdata in `$DIRLOGLIST_GL | tr -d '\t' | tr ' ' '^' | cut -d '^' -f3 | tail -n5`; do
      proc_debug "$rawdata"
    done
  fi
fi

if [ "$SKIPSECTIONS" ]; then
  if [ "`echo "$2" | egrep -i "$SKIPSECTIONS"`" ]; then
    proc_debug "Stop & Allow: Excluded section in SKIPSECTIONS"
    exit 0
  fi
fi

if [ "$SKIPUSERS" ]; then
  if [ "`echo "$USER" | egrep -i "$SKIPUSERS"`" ]; then
    proc_debug "Stop & Allow: Excluded user in SKUPUSERS"
    exit 0
  fi
fi

if [ "$SKIPGROUPS" ]; then
  if [ "`echo "$GROUP" | egrep -i "$SKIPGROUPS"`" ]; then
    proc_debug "Stop & Allow: Excluded group $GROUP in SKUPGROUPS"
    exit 0
  fi
fi

if [ "$SKIPFLAGS" ]; then
  if [ "`echo "$FLAGS" | egrep -i "$SKIPFLAGS"`" ]; then
    proc_debug "Stop & Allow: Excluded flag on $USER. ($FLAGS) in SKIPFLAGS"
    exit 0
  fi
fi

proc_checkallow() {
  if [ "$ALLOWFILE" ]; then
    if [ -e "$ALLOWFILE" ]; then
      if [ "`grep "^$1$" "$ALLOWFILE" `" ]; then
        proc_debug "Stop & Allow: This file has been allowed"
        exit 0
      fi
    fi
  fi
}

if [ ! -d "$2/$1" ]; then
  if [ -d "$2" ]; then
    if [ "`ls -al "$2" | grep -i "[0-9] $1$" | cut -c1`" = "d" ]; then
      proc_debug "Stop & Deny: This dir exists here with another case structure already."
      if [ "$IERROR1" ]; then OUTPUT="$IERROR1"; proc_announce; fi
      echo -e "$ERROR1\n"
      exit 2
    fi
  fi
 
  if [ "$NUKE_PREFIX" ]; then
    if [ -d "$NUKE_PREFIX$1" ]; then
      proc_checkallow "$1"
      proc_debug "Stop & Deny: This dir has been nuked and found by NUKE_PREFIX."
      if [ "$IERROR2" ]; then OUTPUT="$IERROR2"; proc_announce; fi
      echo -e "$ERROR2\n"
      exit 2
    fi
  fi

  if [ "`echo "$1" | egrep -i "$SKIPDIRS"`" ]; then
    proc_debug "Stop & Allow: This dirname is excluded in SKIPDIRS"
    exit 0
  fi

  if [ "$ALLOWDIRS" ]; then
    for rawdata in $ALLOWDIRS; do
      section="`echo "$rawdata" | cut -d ':' -f1`$"
      allowed="`echo "$rawdata" | cut -d ':' -f2`"
      if [ "`echo "$2" | egrep "$section"`" ]; then
        if [ -z "`echo "$1" | egrep -i "$allowed"`" ]; then
          proc_checkallow "$1"
          proc_debug "Stop & Deny: This dir/group is not allowed."
          if [ "$IERROR5" ]; then OUTPUT="$IERROR5"; proc_announce; fi
          echo -e "$ERROR5\n"
          exit 2
        else
          if [ "$ALLOWDIRS_OVERRULES_DENYDIRS" = "TRUE" ]; then
            ALLOW_OVERRULE_DIR=TRUE
            proc_debug ".. Overruling any DENYDIRS"
          fi
          if [ "$ALLOWDIRS_OVERRULES_DENYGROUPS" = "TRUE" ]; then
            ALLOW_OVERRULE_GROUP=TRUE
            proc_debug ".. Overruling any DENYGROUPS"
          fi
        fi
      fi
    done
  fi

  if [ "$DENYGROUPS" ] && [ "$ALLOW_OVERRULE_GROUP" != "TRUE" ]; then
    for rawdata in $DENYGROUPS; do
      section="`echo "$rawdata" | cut -d ':' -f1`"
      deniedgroup="`echo "$rawdata" | cut -d ':' -f2`"

      if [ "`echo "$2" | egrep -i "$section"`" ]; then
        if [ "`echo "$1" | egrep -i "$deniedgroup"`" ]; then
          proc_checkallow "$1"
          proc_debug "Stop & Deny: This group is banned."
          if [ "$IERROR3" ]; then OUTPUT="$IERROR3"; proc_announce; fi
          echo -e "$ERROR3\n"
          exit 2
        fi
      fi
    done
  fi

  if [ "$DENYDIRS" ] && [ "$ALLOW_OVERRULE_DIR" != "TRUE" ]; then
    for rawdata in $DENYDIRS; do
      section="`echo "$rawdata" | cut -d ':' -f1`$"
      denied="`echo "$rawdata" | cut -d ':' -f2`"

      if [ "`echo "$2" | egrep -i "$section"`" ]; then
        if [ "`echo "$1" | egrep -i "$denied"`" ]; then
          proc_checkallow "$1"
          proc_debug "Stop & Deny: This dir seems denied in DENYDIRS"
          if [ "$IERROR4" ]; then OUTPUT="$IERROR4"; proc_announce; fi
          echo -e "$ERROR4\n"
          exit 2
        fi
      fi
    done
  fi

  if [ "$DIRLOGLIST_GL" ]; then
    #if [ "`$DIRLOGLIST_GL | grep "/$1$"`" ]; then
    if [ "`$DIRLOGLIST_GL | grep -iv "STATUS: 3" | grep "/$1$"`" ]; then
      proc_checkallow "$1"
      proc_debug "Stop & Deny: It was found in dirlog, thus already upped before (NOPARENT CHECK)."
      if [ "$IERROR2" ]; then OUTPUT="$IERROR2"; proc_announce; fi
      echo -e "$ERROR2\n"
      exit 2
    fi
  fi

fi

proc_debug "Stop & Allow: This dir passed all checks."

exit 0
