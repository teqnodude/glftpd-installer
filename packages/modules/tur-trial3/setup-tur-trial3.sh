#!/bin/bash

SQLBIN="mysql"
SQLHOST="localhost"
SQLUSER="trial"
SQLPASS=""
SQLDB="trial"

case "$1" in

    "create")

        mysql -S /run/mysqld/mariadb-glftpd.sock -uroot -e "CREATE DATABASE IF NOT EXISTS $SQLDB CHARACTER SET utf8mb4"
        mysql -S /run/mysqld/mariadb-glftpd.sock -uroot -e "CREATE USER IF NOT EXISTS '$SQLUSER'@'$SQLHOST' IDENTIFIED BY '$SQLPASS';"
        mysql -S /run/mysqld/mariadb-glftpd.sock -uroot -e "GRANT ALL PRIVILEGES ON $SQLDB . * TO '$SQLUSER'@'$SQLHOST';"
        mysql -S /run/mysqld/mariadb-glftpd.sock -uroot -D $SQLDB < import.sql.new
        ;;

    "remove")

        mysql -S /run/mysqld/mariadb-glftpd.sock -uroot -e "DROP DATABASE IF EXISTS $SQLDB"
        mysql -S /run/mysqld/mariadb-glftpd.sock -uroot -e "DROP USER IF EXISTS 'transfer'@'localhost';"
        ;;

    *)

        echo "Run '$0 create' to create database, table and user"
        echo "Run '$0 remove' to remove database, table and user"
        ;;

esac
