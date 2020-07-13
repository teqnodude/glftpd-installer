#!/bin/bash
VER="0.1"

echo ""
echo "This script will redo the tables you select."
echo ""
echo "This should only be needed if there has been a change or update"
echo "that requires this (see changelog)."
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

echo ""
unset go

if [ -z "$pass" ]
then
	SQLDB="$mysql -u $user -h $host -N -e"
	SQL="$mysql -u $user -h $host -D $database -N -e"
else
	SQLDB="$mysql -u $user -p"$pass" -h $host -N -e"
	SQL="$mysql -u $user -p"$pass" -h $host -D $database -N -e"
fi


until [ -n "$go" ]; do
  echo -n "Do you want to clear out the entire database? [Y]es [N]o: "
  read go
  case $go in
    [Nn])
      go="n"
      continue
      ;;
    [Yy])
      $SQLDB "DROP DATABASE $database"
      echo "Finished. If you got no errors, the database is now gone and you should"
      echo "recreate it using setup_database.sh"
      exit 0
      ;;
    *)
     unset go
     continue
     ;;
  esac
done
unset go

echo ""
echo "Specify the table to redo (all info is deleted)"
echo "Default tablenames are excluded, ranking and trial"
until [ -n "$table" ]; do
  echo -n "Table:: "
  read table
  if [ -z "$table" ]; then
    continue
  fi
done
echo ""




echo ""

echo "The $table database will be cleared using:"
echo "$mysql -u $user -p\"$pass\" -h $host -D $database -N -e"
echo ""
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

$SQL "DROP TABLE $table"

echo "Finished. If you got no errors, the table is now gone and you should"
echo "recreate it using setup_database.sh"
echo "Dont worry about 'already exists' errors in it. It wont do anything"
echo "to already existing tables"

exit 0

