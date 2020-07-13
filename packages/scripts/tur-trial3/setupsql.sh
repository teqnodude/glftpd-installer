#!/bin/bash
VER="0.3"

## 0.3 : Now creates the passed table too.

echo ""
echo "This script will help you set up the database for Tur-Trial 3+"
echo ""
echo "You must have the mysql client/server installed first."
echo "You will also be given the choice for a user who will create"
echo "the database and tables."
echo ""
echo "It is highly recomended to use the default names for the"
echo "database and tables."
echo ""
echo "--------------------------------------------------------------"
echo ""

if [ "`which mysql 2>/dev/null`" ]; then
  mysql="`which mysql`"
  echo "Autodetected mysql client in $mysql"; echo ""
else
  echo "Could not autodetect mysql client location."
  echo "Enter your path to the mysql binary manually."
  until [ -n "$mysql" ]; do
    echo -n "Path: [/usr/bin/mysql]: "
    read mysql
    if [ -z "$mysql" ]; then
      mysql=/usr/bin/mysql
      if [ ! -e "$mysql" ]; then
        echo "mysql does not exist in $mysql."
        unset mysql
      fi
      continue
    fi
  done
  if [ ! -e "$mysql" ]; then
    echo "The mysql client does not exist in $mysql."
    exit 0
  fi
  echo ""
fi
echo "Specify host for the mysql server."
until [ -n "$host" ]; do
  echo -n "Host: [localhost]: "
  read host
  if [ -z "$host" ]; then
    host="localhost"
    continue
  fi
done
echo ""
echo "Specify the database to use."
until [ -n "$database" ]; do
  echo -n "Database: [trial]: "
  read database
  if [ -z "$database" ]; then
    database="trial"
    continue
  fi
done
echo ""
echo "Specify the table to use for trial/special quota into."
until [ -n "$table" ]; do
  echo -n "Table: [trial]: "
  read table
  if [ -z "$table" ]; then
    table="trial"
    continue
  fi
done
echo ""
echo "Specify the table to use for excluded quota info."
until [ -n "$extable" ]; do
  echo -n "Excluded Table: [excluded]: "
  read extable
  if [ -z "$extable" ]; then
    extable="excluded"
    continue
  fi
done
echo ""
echo "Specify the table to use for ranking information."
until [ -n "$ranktable" ]; do
  echo -n "Ranking Table: [ranking]: "
  read ranktable
  if [ -z "$tanktable" ]; then
    ranktable="ranking"
    continue
  fi
done
echo ""
echo "Specify the table to use for passed quota info."
until [ -n "$passtable" ]; do
  echo -n "Excluded Table: [passed]: "
  read passtable
  if [ -z "$passtable" ]; then
    passtable="passed"
    continue
  fi
done
echo ""
echo "Specify the username to use."
until [ -n "$user" ]; do
  echo -n "User: [root]: "
  read user
  if [ -z "$user" ]; then
    user="root"
    continue
  fi
done
echo ""
echo "Specify the password to use."
until [ -n "$pass" ]; do
  echo -n "Pass: []: "
  read pass
  if [ -z "$pass" ]; then
    pass="^^"
    continue
  fi
done
if [ "$pass" = "^^" ]; then
  unset pass
fi

if [ -z "$pass" ]
then
    SQLDB="$mysql -u $user -h $host -N -e"
    SQL="$mysql -u $user -h $host -D $database -N -e"
    echo ""
    echo "The database will created using:"
    echo "$mysql -u $user -h $host -N -e"
    echo ""
    echo "The tables will be created using:"
    echo "$mysql -u $user -h $host -D $database -N -e"
    echo ""

else
    SQLDB="$mysql -u $user -p"$pass" -h $host -N -e"
    SQL="$mysql -u $user -p"$pass" -h $host -D $database -N -e"
    echo ""
    echo "The database will created using:"
    echo "$mysql -u $user -p\"$pass\" -h $host -N -e"
    echo ""
    echo "The tables will be created using:"
    echo "$mysql -u $user -p\"$pass\" -h $host -D $database -N -e"
    echo ""
fi

until [ -n "$go" ]; do
  echo -n "Continue? [Y]es [N]o: "
  read go
  case $go in
    [Nn])
      exit 0
      continue
      ;;
    [Yy])
      echo " "
      go=n
      ;;
    *)
     unset go
     continue
     ;;
  esac
done
unset go

$SQLDB "CREATE DATABASE $database"

$SQL "CREATE TABLE "$table" ( "active" tinyint(1) default NULL, "username" text NOT NULL, "stats" text NOT NULL, "added" text NOT NULL, "extratime" text, "startstats" text NOT NULL, "endtime" text NOT NULL, "tlimit" text NOT NULL ) Engine=MyISAM"

$SQL "CREATE TABLE "$extable" ( "username" text NOT NULL, "excluded" tinyint(1) NOT NULL default '0' ) Engine=MyISAM"

$SQL "CREATE TABLE "$passtable" ( "username" text NOT NULL, "passed" tinyint(1) NOT NULL default '0' ) Engine=MyISAM"

$SQL "CREATE TABLE "$ranktable" ( "username" text NOT NULL, "rank" text NOT NULL ) Engine=MyISAM"

echo "Finished. If you have no errors above, the mysql setup is complete."
echo "Now setup tur-trial3.conf using the same values as you gave here for host/database/tables."
exit 0
