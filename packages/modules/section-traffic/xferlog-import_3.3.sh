#!/bin/bash
VER=3.4
#--[ Info ]-----------------------------------------------------
#                                                          
# This script is used to import your xferlog into a mysql  
# database so you can do other fun stuff with it.          
#                                                          
# Only tested on glftpd 2.                                 
# 3.1 Fixed to work... better? Now uses a TAB seperator    
#     and also specifies the fieldnames to insert into.    
#     3.0 gave me errors on newer MariaDBs without this.   
#     Also fixed/renamed "transfefype" to "transfertype"   
#     so if you're upgrading, take that into account!      
#                                                          
# 3.2 Database structure changed. "load data" changed so   
#     that the various date/time fields are stored in a    
#     single 'datetime' instead.                           
#     Also removed (not importing) all the crap fields.    
#     You can NOT update directly from 3.1. If you want    
#     to use this new structure, create a new table for it 
#     and import your old xferlog.archived file in it.     
#                                                          
# 3.3 Modified by Teqno to contain relname & section with  
#     optimized length of columns for improved performance 
#
# 3.4 Optimized code and fixed default SSL issue that was introduced
#     in newer versions of Debian.
#                                                          
#--[ Setup ]----------------------------------------------------
#                                                          
# * Setup the database and table to something like this:   
#
# CREATE TABLE $(transfers) (
#  $(ID) bigint(20) NOT NULL AUTO_INCREMENT,
#  $(datetime) datetime DEFAULT NULL,
#  $(ip) varchar(20) DEFAULT NULL,
#  $(FTPuser) varchar(20) DEFAULT NULL,
#  $(FTPgroup) varchar(20) DEFAULT NULL,
#  $(path) varchar(300) DEFAULT NULL,
#  $(filename) varchar(255) DEFAULT NULL,
#  $(relname) varchar(255) DEFAULT NULL,
#  $(section) varchar(30) DEFAULT NULL,
#  $(transfertime) bigint(20) DEFAULT NULL,
#  $(bytes) bigint(20) DEFAULT NULL,
#  $(direction) char(1) DEFAULT '',
#  $(ident) varchar(20) DEFAULT NULL,
#  PRIMARY KEY ($(ID)),
#  KEY $(IP) ($(ip)(7)),
#  KEY $(Direction) ($(direction)),
#  KEY $(FTPuser) ($(FTPuser)(2)),
#  KEY $(Section) ($(section)(2)),
#  KEY $(Filename) ($(filename)(8))
# ) ENGINE=MyISAM DEFAULT CHARSET=latin1;
#
#
# CREATE INDEX idx_section_datetime_ftpuser ON transfers(section, datetime, FTPuser);
# CREATE INDEX idx_section_datetime_direction ON transfers(section, datetime, direction);
#
#--[ Settings ]-------------------------------------------------

## Path to mysql binary. Leave as "mysql" if in path.
SQLBIN="mysql"

## Hostname of MySQL server. Try localhost if 127.0.0.1 gives you problems.
SQLHOST="localhost"

## MySQL user.
SQLUSER="admin"

## MySQL users password.
SQLPASS=""

## Database to use.
SQLDB="transfers"

## Table to use.
SQLTB="changeme"

## Path to current xferlog.
xferlog=/glftpd/ftp-data/logs/xferlog

## Path where it will be stored instead.
archive=/glftpd/ftp-data/logs/xferlog.archived

## Lockfile to use. 
lockfile=/tmp/xferlog-import.lock

## Temporary path to store stuff. Make sure it exists.
tmp=/glftpd/tmp

#--[ Script Start ]---------------------------------------------

SQL="$SQLBIN --ssl=0 -P 3307 -u $SQLUSER -p"$SQLPASS" -h $SQLHOST -D $SQLDB -N -s -e"

DEBUG="FALSE"

if [[ "${1:-}" = "debug" || "${1:-}" = "test" ]]
then

    DEBUG="TRUE"

fi

proc_debug() {
    if [[ "${DEBUG}" = "TRUE" ]]
    then

        printf '[DEBUG] %s\n' "$*"

    fi
}

# Ensure tmp exists
mkdir -p "${tmp:-/tmp}"

# Lockfile handling (corrected, consistent variable name)
if [[ -e "$lockfile" ]]
then

    # If the lockfile is newer than 60 minutes, quit; otherwise remove stale lock
    if find "$lockfile" -type f -mmin -60 -print -quit >/dev/null
    then

        echo "Lockfile $lockfile exists and is not 60 minutes old yet. Quitting."
        exit 0

    else

        echo "Lockfile exists, but it's older than 60 minutes. Removing lockfile."
        rm -f "$lockfile"

    fi

fi

# Ensure xferlog is readable
if [[ ! -r "$xferlog" ]]
then

    proc_debug "Can't read xferlog ($xferlog). Quitting."
    exit 1

fi

# Test SQL connection
proc_sqlconnecttest() {

    sqldata="$($SQL "show table status" | tr -s '\t' '^' | cut -d '^' -f1)"

    if [[ -z "$sqldata" ]]
    then

        unset ERRORLEVEL
        echo "Mysql error. Check server"
        exit 1
    fi

}

proc_sqlconnecttest

# Create lockfile and ensure cleanup on exit
touch "$lockfile"
trap 'rm -f "$lockfile"' EXIT

mv -f $xferlog $tmp/xferlog.processing

cat $tmp/xferlog.processing | tr ' ' '\t' | tr -s '\t' | tr '?' ' ' > $tmp/xferlog.processing.sort
$SQL "load data local infile \"$tmp/xferlog.processing.sort\" INTO TABLE $SQLTB fields terminated BY '\t' (@day, @month, @daynum, @time, @year, transfertime, ip, bytes, path, @transfertype, @underscore, direction, @r, FTPuser, FTPgroup, @0or1, ident) set datetime = str_to_date(concat(@month, \"-\",@daynum, \"-\",@year, \" \", @time),'%b-%d-%Y %H:%i:%s')"
$SQL "UPDATE $SQLTB SET section = SUBSTRING_INDEX(SUBSTRING_INDEX(path, '/', 3), '/', -1), filename = SUBSTRING_INDEX(path, '/', -1), relname = CASE WHEN LOWER(SUBSTRING_INDEX(SUBSTRING_INDEX(path, '/', -2), '/', 1)) IN ('sample', 'proof', 'covers', 'subs') OR LOWER(SUBSTRING_INDEX(SUBSTRING_INDEX(path, '/', -2), '/', 1)) LIKE 'cd%' OR LOWER(SUBSTRING_INDEX(SUBSTRING_INDEX(path, '/', -2), '/', 1)) LIKE 'disk%' THEN SUBSTRING_INDEX(SUBSTRING_INDEX(path, '/', -3), '/', 1) ELSE SUBSTRING_INDEX(SUBSTRING_INDEX(path, '/', -2), '/', 1) END"
$SQL "DELETE FROM $SQLTB WHERE section='PRE'"
cat $tmp/xferlog.processing >> $archive

rm -f $tmp/xferlog.processing
rm -f $tmp/xferlog.processing.sort

exit 0
