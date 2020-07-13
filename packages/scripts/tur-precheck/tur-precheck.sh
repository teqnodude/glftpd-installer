#!/bin/bash
VER=1.5

VERIFY_RAR_WITH_SFV="TRUE"
VERIFY_MP3_WITH_SFV="TRUE"
VERIFY_ZIP_WITH_CURRENT_DISKS="TRUE"

DONT_ALLOW_DIZ="TRUE"

#ALLOWED="\.r[a|0-9][r|0-9]$ \.0[0-9][0-9]$ \.zip$ \.mp[g|2|3|4]$ \.vob$ \.avi$ \.jpg$ \.nfo$ \.diz$ \.sfv$ \.mkv$ \.m2ts$ \.flac$ \.s[0-9][0-9]$ \.t[0-9][0-9]$ \.u[0-9][0-9]$ \.v[0-9][0-9]$ \.w[0-9][0-9]$"
ALLOWED=""

BANNED="^5a\.nfo$ ^aks\.nfo$ ^atl\.nfo$ ^atlvcd\.nfo$ ^bar\.nfo$ ^cas\-pre\.jpg$ ^cmt\.nfo$ ^coke\.nfo$ ^dim\.nfo$ ^dkz\.nfo$ ^echobase\.nfo$ ^firesite\.nfo$ ^fireslut\.nfo$ ^ifk\.nfo$ ^lips\.nfo$ ^magfields\.nfo$ ^mfmfmfmf\.nfo$ ^mm\.nfo$ ^mob\.nfo$ ^mod\.nfo$ ^pbox\.nfo$ ^ph\.nfo$ ^pike\.nfo$ ^pre\.nfo$ ^release\.nfo$ ^sexy\.nfo$ ^tf\.nfo$ ^twh\.nfo$ ^valhalla\.nfo$ ^zn\.nfo$ ^imdb\.nfo$ ^vdrlake\.nfo$ ^dm\.nfo$ ^nud\.nfo$ ^thecasino\.nfo$ ^dtsiso21\.jpg$ ^dagger\.jpg$"

NODOUBLESFV="FALSE"
NOSAMENAME="TRUE"
NODOUBLENFO="TRUE"
NOFTPRUSHNFOS="TRUE"
DENY_SFV_IN_SAMPLE_DIRS="TRUE"

DENY_WHEN_NO_SFV="\.r[a0-9][r0-9]$ \.0[0-9][0-9]$ \.mp[2|3]$ \.flac$"

#GLLOG="/ftp-data/logs/glftpd.log"
GLLOG=""

EXCLUDEDDIRS="/REQUESTS /ARCHIVE /PRE /SPEEDTEST"

ERROR1="This file does not match any allowed file extentions. Skipping."
ERROR2="This filename is BANNED. Add it to your skiplists. Wanker."
ERROR3="There is already a .sfv in this dir. You must delete that one first."
ERROR4="This file is already there with a different case."
ERROR5="There is already a .nfo in this dir. You must delete that one first."
ERROR6="This nfo file format is not allowed ($1)"
ERROR7="You can not upload a .sfv or .nfo file into a Sample, Covers or Proof dir."
ERROR8="You must upload the .sfv file first."


#--[ Script Start ]--------------------------------#

if [ "$EXCLUDEDDIRS" ]; then
  EXCLUDEDDIRS=`echo "$EXCLUDEDDIRS" | tr -s ' ' '|'`
  if [ "`echo "$2" | egrep -i "$EXCLUDEDDIRS"`" ]; then
    exit 0
  fi
fi

case "$1" in

  *.[rR0-9][aA0-9][rR0-9])
    if [ "$VERIFY_RAR_WITH_SFV" ]; then
      sfv_file="`ls -1 "$2" | grep -i "\.sfv$"`"
      if [ -z "$sfv_file" ]; then
        echo -e "You must upload .sfv first!\n"
        exit 2
      else
        if [ -z "`grep -i "^$1\ " "$sfv_file"`" ]; then
          echo -e "File does not exist in sfv!\n"
          exit 2
        fi
      fi
    fi
  ;;

  *.[mM][pP]3)
    if [ "$VERIFY_MP3_WITH_SFV" ]; then
      sfv_file="`ls -1 "$2" | grep -i "\.sfv$"`"
      if [ -z "$sfv_file" ]; then
        echo -e "You must upload .sfv first!\n"
        exit 2
      else
        if [ -z "`grep -i "^$1\ " "$sfv_file"`" ]; then
          echo -e "File does not exist in sfv!\n"
          exit 2
        fi
      fi
    fi
  ;;


  *.[dD][iI][zZ])
    if [ "$DONT_ALLOW_DIZ" = "TRUE" ]; then
      exit 2
    fi
  ;;

  *.[zZ][iI][pP])
    if [ "$VERIFY_ZIP_WITH_CURRENT_DISKS" = "TRUE" ]; then
      if [ "`ls -1 | grep -i \.zip$`" ]; then
       searchstr=`echo "$1" | cut -c-3`
       if [ -z "`ls -1 | cut -c-3 | grep -i $searchstr`" ] ; then
         echo -e "Filename does not match with existing disks"
         exit 2
        fi
      fi
    fi
  ;;

esac

if [ "$ALLOWED" ]; then
  ALLOWED=`echo "$ALLOWED" | tr -s ' ' '|'`
  if [ -z "`echo "$1" | egrep -i "$ALLOWED"`" ]; then
    echo -e "$ERROR1\n"
    exit 2
  fi
fi

if [ "$DENY_WHEN_NO_SFV" ]; then
  DENY_WHEN_NO_SFV=`echo "$DENY_WHEN_NO_SFV" | tr -s ' ' '|'`
  if [ "`echo "$1" | egrep -i "$DENY_WHEN_NO_SFV"`" ]; then
    if [ -z "`ls -1 "$2" | grep -i "\.sfv$"`" ]; then
      echo -e "$ERROR8\n"
      exit 2
    fi
  fi
fi

if [ "$BANNED" ]; then
  BANNED=`echo "$BANNED" | tr -s ' ' '|'`
  if [ "`echo "$1" | egrep -i "$BANNED"`" ]; then
    echo -e "$ERROR2\n"
    exit 2
  fi
fi

if [ "$NOSAMENAME" = "TRUE" ]; then
  if [ "`ls -1 "$2" | grep -i "^$1$"`" ]; then
    if [ -z "`ls -1 "$2" | grep "^$1$"`" ]; then
      echo -e "$ERROR4\n"
      exit 2
    fi
  fi
fi

if [ "$NODOUBLESFV" = "TRUE" ]; then
  if [ "`echo "$1" | grep -i "\.sfv$"`" ]; then
    if [ -e $2/*.[sS][fF][vV] ]; then
      echo -e "$ERROR3\n"
      if [ "$GLLOG" ]; then
        DIR=`basename $2`

        # $1 = Filename. $2 = Full path. $DIR = Only the dir were currently in. $USER = duh
        echo `date "+%a %b %e %T %Y"` TURGEN: \"[WANKER] - $USER tried to upload $1 into $DIR where there already is a sfv!\" >> $GLLOG

      fi
      exit 2
    fi
  fi
fi

if [ "$DENY_SFV_IN_SAMPLE_DIRS" = "TRUE" ]; then
  if [ "`echo "$PWD" | grep -i "\/sample$\|\/covers$\|\/proof$"`" ]; then
    if [ "`echo "$1" | grep "\.[sS][fF][vV]$\|\.[nN][fF][oO]"`" ]; then
      echo -e "$ERROR7\n"
      exit 2
    fi
  fi
fi

if [ "$NODOUBLENFO" = "TRUE" ]; then
  if [ "`echo "$1" | grep "\.[nN][fF][oO]$"`" ]; then
    if [ -e $2/*.[nN][fF][oO] ]; then
      echo -e "$ERROR5\n"
      if [ "$GLLOG" ]; then
        DIR=`basename $2`

        # $1 = Filename. $2 = Full path. $DIR = Only the dir were currently in. $USER = duh
        echo `date "+%a %b %e %T %Y"` TURGEN: \"[WANKER] - $USER tried to upload $1 into $DIR where there already is a nfo!\" >> $GLLOG

      fi
      exit 2
    fi
  fi
fi

if [ "$NOFTPRUSHNFOS" = "TRUE" ]; then
  if [ "`echo "$1" | grep "\.[nN][fF][oO]$"`" ]; then
    if [ "`echo "$1" | grep "([0-9].*)\.[nN][fF][oO]$"`" ]; then
      echo -e "$ERROR6\n"
      exit 2      
    fi
  fi
fi

exit 0
