#!/bin/bash
#--[ Info ]-----------------------------------------------------
#
# A script by eur0dance to list (show) affils on the site.
# It's meant to be used via "SITE LISTAFFILS" and inside the sitebot.
# Version 1.0
#
# Note: Requires the following binaries: cat, grep, awk, basename. echo
#
#--[ Settings ]-------------------------------------------------
#
# Location of your glftpd.conf file. It will fully work only if
# this path is both the real path and the CHROOTED path to your
# glftpd dir. In other words: put your glftpd.conf inside 
# /glftpd/etc dir and make a symlink to i in /etc.
glftpd_conf="/etc/glftpd.conf"

#--[ Script Start ]---------------------------------------------

privpaths=$(grep privpath $glftpd_conf | grep -v "/site/PRE/SiteOP" | awk '{print $2}' | sort)

predirs=""

for path in $privpaths
do

    predirs="$predirs $(basename $path)"

done

echo $predirs
