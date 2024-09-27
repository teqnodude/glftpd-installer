#!/bin/bash
VER=1.1
#--[ Intro ]----------------------------------------------------#
# 								#
# A backup/restore script that is specifically tailored to the 	#
# setup made by glftpd-installer and does not work for other 	#
# types of sites. This script takes a backup of all binaries, 	#
# scripts, settings, users and system settings related to 	#
# glFTPd. For this to work as intended you will need to ensure 	#
# that the system meets the requirements listed at: 		#
# https://github.com/teqnodude/glftpd-installer 		#
# 								#
# This script automatically downloads the appropiate 32/64 bit 	#
# version of glftpd so there is no need to manually install 	#
# glftpd before running this script. 				#
#								#
#--[ Instructions ]---------------------------------------------#
#								#
# Put this in crontab: 						#
# 57 23 * * * /glftpd/backup/backup.sh backup			#
# if you want an automatic backup. To restore a backup you 	#
# need to put the backup file in the same dir as this script 	#
# and then run:							#
# ./backup.sh restore						#
#								#
# If for any reason it crashes during restoration, run:		#
# ./backup.sh cleanup						#
# and try to restore the backup once again.			#
#								#
#----[ Settings ]------------------------------------------------

glroot=/glftpd
site=changeme
dstdir=$glroot/backup/glftpd
today=`date +%F`
filename="backup-$site-$today.tar.gz"
pass=
db1=trial
db2=transfers
paths="
/etc/inetd.conf
/etc/mysql/mariadb.conf.d/50-server.cnf
/etc/rsyslog.d/glftpd.conf
/etc/systemd/system/glftpd.socket
/etc/systemd/system/glftpd@.service
/etc/services
/glftpd/*.sh
/glftpd/backup/*.sh
/glftpd/backup/pzs-ng
/glftpd/bin
/glftpd/dev
/glftpd/etc
/glftpd/ftp-data
/glftpd/sitebot
/glftpd/usr
/var/spool/cron/crontabs/root
/var/spool/cron/crontabs/sitebot
"

#----[ Script Start ]-------------------

curdir=`pwd`

case $1 in 
    backup)
	echo
	echo "Backing up, please wait..." | awk '{printf("%-50s",$0)}'
	if [ -f "/usr/sbin/mariadbd" ]
	then
	    mysqldump -u trial -p$pass --databases $db1 > $db1.sql
    	    mysqldump -u transfer -p$pass --databases $db2 > $db2.sql
    	    tar -czf $db1.tar.gz $db1.sql >/dev/null 2>&1
    	    tar -czf $db2.tar.gz $db2.sql >/dev/null 2>&1
	    paths="$paths
    	    $db1.tar.gz
    	    $db2.tar.gz
	    "
	fi
	[ ! -d "$dstdir" ] && mkdir $dstdir
	[ -f "$dstdir/$filename" ] && rm -f $dstdir/$filename
	tar -czf $dstdir/$filename --exclude ftp-data/logs --exclude ftp-data/pzs-ng --exclude ftp-data/backup $paths >/dev/null 2>&1
	[ -f "/usr/sbin/mariadbd" ] && rm $db1.tar.gz $db2.tar.gz $db1.sql $db2.sql
	echo -e "[\e[32mDone\e[0m]"
	;;
    restore)
	if [ `ls backup-*.gz | wc -l` -eq 0 ]
	then
	    echo "No backup file found in current dir, please move it to current dir and try again."
	    exit 0
	fi
	if [ `ls backup-*.gz | wc -l` -gt 1 ]
	then
	    echo "More than one backup file present, ensure that only the relevant backup is present in current dir."
	    ls backup-*.gz
	    exit 0 
	fi
	if [ ! -f "/usr/sbin/mariadbd" ]
	then
	    echo "mariadb-server not installed. If you use section-traffic or tur-trial then you need to install mariadb-server before running this script."
	    echo
	    echo "To install mariadb-server do the command: apt-get install mariadb-server"
	    echo
	    echo -n "[A]bort or [C]ontinue? A/C : " ; read abort
	    case $abort in
		[Aa]*) echo "Aborting" ; exit 1 ;;
	    esac
		
	fi
	restore="$dstdir/restore"
	echo "Downloading glFTPd, please wait..." | awk '{printf("%-50s",$0)}'
	[ ! -d "$restore" ] && mkdir -p $restore
        latest=`curl -s https://glftpd.io | grep "/files/glftpd" | grep -v BETA | grep -o "glftpd-LNX.*.tgz" | head -1`
        version=`lscpu | grep Architecture | awk '{print $2}'`
        case $version in
            i686)
                version="32"
                latest=`echo $latest | sed 's/x64/x86/'`
                ;;
            x86_64)
                version="64"
        esac
        wget -P $restore -q https://glftpd.io/files/$latest
        PK="`ls $restore | grep glftpd-LNX | grep x$version`"
        tar -xf $restore/$PK -C $restore
        PKDIR="`echo $PK | sed 's|.tgz||'`"

	echo -e "[\e[32mDone\e[0m]"
	echo "Setting up glFTPd, please wait..." | awk '{printf("%-50s",$0)}'
        CHKGR=`grep -w "glftpd" /etc/group | cut -d ":" -f1`
        CHKUS=`grep -w "sitebot" /etc/passwd | cut -d ":" -f1`
	if [ "$CHKGR" != "glftpd" ]
        then
	    groupadd glftpd -g 199
        fi

	if [ "$CHKUS" != "sitebot" ]
        then
    	    useradd -d $glroot/sitebot -m -g glftpd -s /bin/bash sitebot
    	    chfn -f 0 -r 0 -w 0 -h 0 sitebot
	fi
	cp -fr $restore/$PKDIR/bin $glroot
	cp -fr $restore/$PKDIR/docs $glroot
	cp -fr $restore/$PKDIR/etc $glroot 
	cp -fr $restore/$PKDIR/ftp-data $glroot
	cp -fr $restore/$PKDIR/gcp $glroot

	echo -e "[\e[32mDone\e[0m]"
	echo "Restoring backup, please wait..." | awk '{printf("%-50s",$0)}'
	mkdir $restore/bup
	mkdir $glroot/site
	tar -xf backup-*.gz -C $restore/bup
	cp $restore/bup/etc/rsyslog.d/glftpd.conf /etc/rsyslog.d && service rsyslog restart
	cp -fr $restore/bup/glftpd/backup $glroot
        cp -fr $restore/bup/glftpd/bin $glroot
        cp -fr $restore/bup/glftpd/etc $glroot
        cp -fr $restore/bup/glftpd/ftp-data $glroot
        cp -fr $restore/bup/glftpd/sitebot $glroot
	chown -R sitebot:glftpd $glroot/sitebot
	cp -fr $restore/bup/glftpd/usr $glroot
	cp $restore/bup/glftpd/libcopy.sh $glroot && $glroot/libcopy.sh >/dev/null 2>&1
	mkdir $glroot/dev
        mknod $glroot/dev/null c 1 3 ; chmod 666 $glroot/dev/null
        mknod $glroot/dev/zero c 1 5 ; chmod 666 $glroot/dev/zero
        mknod $glroot/dev/full c 1 7 ; chmod 666 $glroot/dev/full
        mknod $glroot/dev/urandom c 1 9 ; chmod 666 $glroot/dev/urandom
	mkdir -m777 $glroot/tmp
	chmod 777 $glroot/ftp-data/logs
	[ -f $glroot/bin/psxc-imdb-sanity.sh ] && $glroot/bin/psxc-imdb-sanity.sh >/dev/null 2>&1 ; touch $glroot/ftp-data/logs/psxc-moviedata.log
	[ -f $glroot/bin/tvmaze-nuker.sh ] && $glroot/bin/tvmaze-nuker.sh sanity >/dev/null 2>&1
        chmod 666 $glroot/ftp-data/logs/*
	if [ -f "/usr/sbin/mariadbd" ]
	then
	    service mysql stop
	    cp -f $restore/bup/etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/mariadb.conf.d 
	    mysql_install_db >/dev/null 2>&1 && service mysql start
	    mysql -uroot -e "CREATE DATABASE IF NOT EXISTS $db1"
	    mysql -uroot -e "CREATE DATABASE IF NOT EXISTS $db2"	
	    mysql -uroot -e "CREATE USER IF NOT EXISTS 'trial'@'localhost' IDENTIFIED BY '$pass';"
	    mysql -uroot -e "CREATE USER IF NOT EXISTS 'transfer'@'localhost' IDENTIFIED BY '$pass';"
	    mysql -uroot -e "GRANT ALL PRIVILEGES ON $db1 . * TO 'trial'@'localhost';"
	    mysql -uroot -e "GRANT ALL PRIVILEGES ON $db2 . * TO 'transfer'@'localhost';"
	    mysql -uroot -e "FLUSH PRIVILEGES"
	    tar -xf $restore/bup/trial.tar.gz -C $restore/bup
	    tar -xf $restore/bup/transfers.tar.gz -C $restore/bup
	    mysql -uroot -D $db1 < $restore/bup/trial.sql
	    mysql -uroot -D $db2 < $restore/bup/transfers.sql
	fi
	services=`grep glftpd $restore/bup/etc/services`
	echo "$services" >> /etc/services
	cp -f $restore/bup/etc/systemd/system/glftpd.socket /etc/systemd/system
	cp -f $restore/bup/etc/systemd/system/glftpd@.service /etc/systemd/system
	if [ -f "/etc/inetd.conf" ]
	then
	    inetd=`grep glftpd $restore/bup/etc/inetd`
	    echo "$inetd" >> /etc/inetd.conf
	    kill -HUP inetd
	fi
	[ -f "/etc/glftpd.conf" ] && rm /etc/glftpd.conf
	ln -s $glroot/etc/glftpd.conf /etc/glftpd.conf
	cp -f $restore/bup/var/spool/cron/crontabs/root /var/spool/cron/crontabs/root
	cp -f $restore/bup/var/spool/cron/crontabs/sitebot /var/spool/cron/crontabs/sitebot
	cd $glroot/backup/pzs-ng ; make distclean >/dev/null 2>&1 ; ./configure >/dev/null 2>&1 ; make >/dev/null 2>&1 ; make install >/dev/null 2>&1 ; cd $curdir
	systemctl daemon-reload && systemctl restart glftpd.socket
	service cron restart
	rm -rf $restore
	echo -e "[\e[32mDone\e[0m]"
	echo
	echo "Backup restored, enjoy!"
	;;
    cleanup)
	if [ `mount | grep "/glftpd" | wc -l` -ge 1 ]
	then
	    echo "You have mounted dirs in the path of /glftpd, unmount all including /glftpd and try again."
	    exit 1
	fi
	echo -e "This will remove everything under \e[91m/glftpd\e[0m including \e[91m/glftpd/site\e[0m and undo system changes made by the installer"
	echo
	echo -n "Are you sure you want to proceed? [Y]es [N]o, default N : " ; read cleanup

        case $cleanup in
            [Yy])
		echo "Starting cleanup, please wait..." | awk '{printf("%-50s",$0)}'
		rm -rf /glftpd
		rm -f /etc/glftpd.conf
		rm -rf /var/spool/mail/sitebot
		rm -f /etc/rsyslog.d/glftpd.conf
		killall sitebot > /dev/null 2>&1
		sleep 3
		userdel sitebot > /dev/null 2>&1
		groupdel glftpd > /dev/null 2>&1
		sed -i /glftpd/d /etc/services
	
		if [ -f "/etc/inetd.conf" ]
		then
		    sed -i /glftpd/d /etc/inetd.conf
		    killall -HUP inetd
		fi
	
		sed -i /glftpd/Id /var/spool/cron/crontabs/root
		rm -f /var/spool/cron/crontabs/sitebot
	
		if [ -f "/etc/systemd/system/glftpd.socket" ]
		then
		    systemctl stop glftpd.socket >/dev/null 2>&1
		    systemctl disable glftpd.socket >/dev/null 2>&1
		    rm -f /etc/systemd/system/glftpd*
		    systemctl daemon-reload
		    systemctl reset-failed
		fi
		echo -e "[\e[32mDone\e[0m]"
		;;
	esac
	;;
    *)
	echo "./backup.sh backup - To create a backup of glFTPd settings, users and sitebot including system settings"
	echo "./backup.sh restore - To restore a backup of glFTPd settings, users and sitebot including system settings"
	echo "./backup.sh cleanup - To cleanup all traces related to glFTPd"
	;;
esac

exit 0
