#!/bin/bash
VER=3.3

#----------------------------------------------------------#
#                                                          #
# This script is used to import your xferlog into a mysql  #
# database so you can do other fun stuff with it.          #
#                                                          #
# Only tested on glftpd 2.                                 #
# 3.1 Fixed to work... better? Now uses a TAB seperator    #
#     and also specifies the fieldnames to insert into.    #
#     3.0 gave me errors on newer MariaDBs without this.   #
#     Also fixed/renamed "transfefype" to "transfertype"   #
#     so if you're upgrading, take that into account!      #
#                                                          #
# 3.2 Database structure changed. "load data" changed so   #
#     that the various date/time fields are stored in a    #
#     single 'datetime' instead.                           #
#     Also removed (not importing) all the crap fields.    #
#     You can NOT update directly from 3.1. If you want    #
#     to use this new structure, create a new table for it #
#     and import your old xferlog.archived file in it.     #
#                                                          #
# 3.3 Modified by Teqno to contain relname & section with  #
#     optimized length of columns for improved performance #
#                                                          #
#-[ Setup ]------------------------------------------------#
#                                                          #
# * Setup the database and table to something like this:   #
#
# CREATE TABLE `transfers` (
#  `ID` bigint(20) NOT NULL AUTO_INCREMENT,
#  `datetime` datetime DEFAULT NULL,
#  `ip` varchar(20) DEFAULT NULL,
#  `FTPuser` varchar(20) DEFAULT NULL,
#  `FTPgroup` varchar(20) DEFAULT NULL,
#  `path` varchar(300) DEFAULT NULL,
#  `filename` varchar(255) DEFAULT NULL,
#  `relname` varchar(255) DEFAULT NULL,
#  `section` varchar(30) DEFAULT NULL,
#  `transfertime` bigint(20) DEFAULT NULL,
#  `bytes` bigint(20) DEFAULT NULL,
#  `direction` char(1) DEFAULT '',
#  `ident` varchar(20) DEFAULT NULL,
#  PRIMARY KEY (`ID`),
#  KEY `IP` (`ip`(7)),
#  KEY `Direction` (`direction`),
#  KEY `FTPuser` (`FTPuser`(2)),
#  KEY `Section` (`section`(2)),
#  KEY `Filename` (`filename`(8))
# ) ENGINE=MyISAM DEFAULT CHARSET=latin1;
#
# (KEY parts optional. Depends on your queries.)
#----------------------------------------------------------#

## Path to mysql binary. Leave as "mysql" if in path.
SQLBIN="mysql"

## Hostname of MySQL server. Try localhost if 127.0.0.1 gives you problems.
SQLHOST="localhost"

## MySQL user.
SQLUSER="root"

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

#--[ Script Start ]----------------------------------------------------#

SQL="$SQLBIN -u $SQLUSER -p"$SQLPASS" -h $SQLHOST -D $SQLDB -N -s -e"

if [ "$1" = "debug" -o "$1" = "test" ]; then
  DEBUG="TRUE"
fi
proc_debug() {
  if [ "$DEBUG" = "TRUE" ]; then
    echo "$*"
  fi
}

if [ -e "$lockfile" ]; then
  if [ "`find \"$lockfile\" -type f -mmin -60`" ]; then
    echo "Lockfile $lockfile exists and is not 60 minutes old yet. Quitting."
    exit 0
  else
    echo "Lockfile exists, but its older then 60 minutes. Removing lockfile."
    rm -f "$LOCKFILE"
  fi
fi

if [ ! -r "$xferlog" ]; then
  proc_debug "Cant read xferlog. Quitting."
  exit 1
fi

proc_sqlconnecttest() {
  sqldata="`$SQL "show table status" | tr -s '\t' '^' | cut -d '^' -f1`"
  if [ -z "$sqldata" ]; then
    unset ERRORLEVEL
    echo "Mysql error. Check server"
    exit 0
  fi
}

proc_sqlconnecttest

touch $lockfile

mv -f $xferlog $tmp/xferlog.processing

cat $tmp/xferlog.processing | tr ' ' '\t' | tr -s '\t' | tr '?' ' ' > $tmp/xferlog.processing.sort
$SQL "load data local infile \"$tmp/xferlog.processing.sort\" INTO TABLE $SQLTB fields terminated BY '\t' (@day, @month, @daynum, @time, @year, transfertime, ip, bytes, path, @transfertype, @underscore, direction, @r, FTPuser, FTPgroup, @0or1, ident) set datetime = str_to_date(concat(@month, \"-\",@daynum, \"-\",@year, \" \", @time),'%b-%d-%Y %H:%i:%s')"
$SQL "update $SQLTB set section=(select substring_index(substring_index(path,'/',3) ,'/',-1) path)"
$SQL "delete from $SQLTB where section='PRE'"
$SQL "update $SQLTB set filename=(select substring_index(path,'/',-1) path)"
$SQL "update $SQLTB set relname=(select substring_index(substring_index(path,'/',-2), '/',1) path)"
$SQL "update $SQLTB set relname=(select substring_index(substring_index(path,'/',-3), '/',1) path) where relname='sample' or relname='proof' or relname like 'cd%' or relname like 'disk%' or relname='covers' or relname='subs'"
cat $tmp/xferlog.processing >> $archive

rm -f $tmp/xferlog.processing
rm -f $tmp/xferlog.processing.sort
rm -f $lockfile

exit 0
