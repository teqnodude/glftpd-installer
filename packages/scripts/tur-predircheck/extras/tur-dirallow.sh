#!/bin/bash
VER=1.1

#------------------
# This script is used to add releases to the DIRALLOW file from irc together 
# with tur-dirallow.tcl on your eggdrop.
#
# Change ALLOWFILE below to point to the same ALLOWFILE as in tur-predircheck.sh
# but make this path NON chrooted, ie /glftpd/tmp/tur-predircheck.allow
#
# Create the ALLOWFILE and chmod it to 666.
#
# Copy this script to /glftpd/bin and chmod it to 755.
#
# Edit the .tcl for options in it and then load it in the bots config file
#
# 1.1 : Changed so only one allowed dir is in the ALLOWFILE at a time so
#       you dont have to remove the file from time to time.
#------------------

ALLOWFILE=/glftpd/tmp/tur-predircheck.allow

#------------------

if [ -z "$1" ]; then
  echo "Specify a release to allow too."
  exit 0
else
  if [ ! -e "$ALLOWFILE" ]; then
    echo "Error. Cant find $ALLOWFILE. Create it and set 666 on it."
    exit 0
  elif [ ! -w "$ALLOWFILE" ]; then
    echo "Error. Found $ALLOWFILE but cant write to it. Set chmod 666 on it."
    exit 0
  fi

  echo "$1" > "$ALLOWFILE"
  echo "$1 has been allowed for creation."
fi

exit 0