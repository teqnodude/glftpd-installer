#!/bin/bash
VER=1.0
#--[ Info ]-----------------------------------------------------
#
# nuke_cache by Teqno
#
# This script adds nuked releases to the /tmp/incomplete-list-nuker.cache
# that then are used by incomplete-list-nuker.sh to track and clean nuked 
# releases. It removes the need for 'find' based scripts to clean manually 
# or automatically nuked releases with the highest efficency.
#
#--[ Install ]--------------------------------------------------
# 
# Copy this to /glftpd/bin, then set this line in glftpd.conf
# cscript SITE[:space:]NUKE post /bin/nuke_cache.sh
#
# If you are currently using this line: cscript SITE[:space:]NUKE post /bin/cleanup
# then replace it with the line above.
#
#--[ Script start ]---------------------------------------------

cache_file=/tmp/incomplete-list-nuker.cache
prefix="$(grep nukedir_style /etc/glftpd.conf | awk '{print $2}' | cut -d '-' -f1)-"
now="$(date +%Y-%m-%d" "%H:%M:%S)"

# SITE NUKE Test 1 kewl admin Admin
target=$(echo $1 | awk '{print $3}')
multi=$(echo $1 | awk '{print $4}')
reason=$(echo $1 | awk '{print $5}')
user=$(echo $2)

# Sat Sep 27 09:55:45 2025 NUKE: "/site/TV-720/Test" "admin" "1" "kewl" "admin 520237.7"
logfile=$(tac /ftp-data/logs/glftpd.log | grep -m1 "$target\" \"$user\" \"$multi\" \"$reason\"")
relname=$(echo $logfile | awk '{print $7}' | tr -d '"')
nukedir=$(echo $relname | sed "s/$target/$prefix$target/")

echo "$now:$nukedir" >> $cache_file

/bin/cleanup
