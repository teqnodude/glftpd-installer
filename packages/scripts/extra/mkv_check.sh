#!/bin/bash 

# ARGUMENTS:
# ----------
# $1 = Name of the file
# $2 = Actual path to file
# $3 = CRC code of the file
# $PWD = Current Path.

# EXIT CODES:
# -----------
# 0 - Good: Give credit and add to user stats.
# 2 - Bad:  No credit / No stats & file is removed.
# 10-1010 - Same as 2, but glftpd will sleep for exitcode-10 seconds
# note: 127 is reserved, so don't use that. 127 is treated like 1,
# causing glftpd to spit out "script could not be executed".

### SETTINGS
#
# NOTE: entries in the PATHS_CHECK and PATHS_EXCLUDE lists are only separated by space
#

PATH_NEXT_POST_CHECK="/bin/zipscript-c"

PATH_GLFTPD_LOG="/ftp-data/logs/glftpd.log"

PATH_MKVINFO="/bin/mkvinfo"

PATHS_CHECK=("sample");     # case insensitive

PATHS_EXCLUDE=("/site/private/");   # case insensitive

DELETE_MKV_FAIL=0                   # set to 1 in order to delete broken mkv files automatically
 
#
###

chain_post_check() 
{
    $PATH_NEXT_POST_CHECK $1 $2 $3
    exit $?
}

# file must end in 'mkv'
if [[ $1 != *mkv ]]; then
  # echo "Not an MKV file, ignoring"
  
  # exit 0

  chain_post_check $1 $2 $3
fi 

# remove empty files right away
if [ ! -s "$2/$1" ]; then
  # echo "File is 0 bytes, deleting..."
  exit 2
fi

# check if the last component in the path is one of directores
# we want to check
pathLc=`echo "$2" | tr '[A-Z]' '[a-z]'`
element_count=${#PATHS_CHECK[@]}
index=0
bDoCheck=0

while [ "$index" -lt "$element_count" ]
do
  strDir=${PATHS_CHECK[$index]}
  strDirLc=`echo "$strDir" | tr '[A-Z]' '[a-z]'`
  
  if [[ $pathLc == */$strDirLc ]] || [[ $pathLc == */$strDirLc/ ]]; then
    bDoCheck=1
  fi
  
  let "index = $index + 1"
done

if [[ $bDoCheck == 0 ]]; then
  # echo "Directory will not be checked"
  # exit 0

  chain_post_check $1 $2 $3
fi

# check if we are in an excluded directory
element_count=${#PATHS_EXCLUDE[@]}
index=0
bDoCheck=1

while [ "$index" -lt "$element_count" ]
do
  strDir=${PATHS_EXCLUDE[$index]}
  strDirLc=`echo "$strDir" | tr '[A-Z]' '[a-z]'`
  
  if [[ $pathLc == $strDirLc* ]] ; then
    bDoCheck=0
  fi
  
  let "index = $index + 1"
done

if [[ $bDoCheck == 0 ]]; then
  # echo "Directory is excluded"
  # exit 0

  chain_post_check $1 $2 $3
fi

# mkvinfo needs LC_ALL to be set
export LC_ALL=C

EXPECTED=`$PATH_MKVINFO -z $2/$1 | grep '^+' | awk '{total += $NF} END{print total}'`

# deal with mkv files with broken header information
if [[ $EXPECTED -lt 10000 ]]; then
    EXPECTED=0
fi

# stat might not be portable
# ACTUAL=$(stat -c%s "$2/$1")

ACTUAL=$(wc -c <"$2/$1")

TIMESTAMP=`date +"%a %b %-d %T %Y"`

if [[ $EXPECTED == $ACTUAL ]]; then
  echo "$TIMESTAMP MKV_PASS: \"$2\" \"$1\" \"$EXPECTED\" \"$ACTUAL\"" >> $PATH_GLFTPD_LOG
  exit 0
fi

echo "$TIMESTAMP MKV_FAIL: \"$2\" \"$1\" \"$EXPECTED\" \"$ACTUAL\"" >> $PATH_GLFTPD_LOG;

if [[ $DELETE_MKV_FAIL == 1 ]] && [[ $EXPECTED -gt 0 ]]; then
  exit 2
fi

exit 0
