#!/bin/bash

SQLBIN="mysql"
SQLHOST="localhost"
SQLUSER="trial"
SQLPASS=""
SQLDB="trial"

if [ -z "$1" ]
then
    echo "Run './setup-tur-trial3.sh create' to create database, table and user"
    echo "Run './setup-tur-trial3.sh remove to remove database, table and user"
fi

if [ "$1" = "create" ]
then
    mysql -uroot -e "CREATE DATABASE IF NOT EXISTS $SQLDB"
    mysql -uroot -e "CREATE USER IF NOT EXISTS '$SQLUSER'@'$SQLHOST' IDENTIFIED BY '$SQLPASS';"
    mysql -uroot -e "GRANT ALL PRIVILEGES ON $SQLDB . * TO '$SQLUSER'@'$SQLHOST';"
    mysql -uroot -e "FLUSH PRIVILEGES"
    mysql -uroot -D $SQLDB < import.sql

elif [ "$1" = "remove" ]
then
    mysql -uroot -e "DROP DATABASE IF EXISTS $SQLDB"
    mysql -uroot -e "DROP USER IF EXISTS 'transfer'@'localhost';"
fi

exit 0
