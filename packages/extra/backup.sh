#!/bin/bash
VER=1.2
#--[ Info ]-----------------------------------------------------
# 
# A backup/restore script that is specifically tailored to the
# setup made by glftpd-installer and does not work for other
# types of sites. This script takes a backup of all binaries,
# scripts, settings, users and system settings related to
# glFTPd. For this to work as intended you will need to ensure
# that the system meets the requirements listed at:
# https://github.com/teqnodude/glftpd-installer
#
# This script automatically downloads the appropriate 32/64 bit
# version of glftpd so there is no need to manually install
# glftpd before running this script.
#
#--[ Instructions ]---------------------------------------------
#
# Put this in crontab:
# 57 23 * * * /glftpd/backup/backup.sh backup
# if you want an automatic backup. To restore a backup you
# need to put the backup file in the same dir as this script
# and then run:
# ./backup.sh restore
#
# If for any reason it crashes during restoration, run:
# ./backup.sh cleanup
# and try to restore the backup once again.
#
#----[ Settings ]-----------------------------------------------

glroot=/glftpd
site=changeme
dstdir=$glroot/backup/glftpd
today=$(date +%F)
filename="backup-$site-$today.tar.gz"
pass=
db1=trial
db2=transfers

paths="
/etc/inetd.conf
/etc/mysql/mariadb-glftpd.cnf
/etc/rsyslog.d/glftpd.conf
/etc/systemd/system/glftpd.socket
/etc/systemd/system/glftpd@.service
/etc/systemd/system/mariadb-glftpd.service
/etc/services.d
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

#----[ Script Start ]-------------------------------------------

GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
BOLD=$(tput bold)
RESET=$(tput sgr0)

print_status_start()
{

    local prefix="$1"
    local text="$2"
    local status_text="please wait"
    local total_width=$banner_width
    local done_length=6  # Length of "[DONE]" with colors

    # Calculate the full text including prefix
    local full_text="${prefix}: ${text} "
    local full_text_length=${#full_text}
    local status_length=${#status_text}

    # Calculate dots needed
    local dots_needed=$((total_width - full_text_length - status_length - done_length -2))

    # Generate dots
    local dots=""
    if [ $dots_needed -gt 0 ]; then
        dots=$(printf '%*s' $dots_needed | tr ' ' '.')
    fi

    printf "%s%s %s " "$full_text" "$dots" "$status_text"

}

# Complete a status with success
print_status_done()
{

    echo "[${green}DONE${reset}]"

}

curdir=$(pwd)

case "$1" in

	backup)

	    echo
	    print_status_start "Backing up"

	    if [[ -f /usr/sbin/mariadbd ]]
	    then

	        mysqldump -P 3307 -u trial -p"$pass" --databases "$db1" > "$db1.sql"
	        mysqldump -P 3307 -u transfer -p"$pass" --databases "$db2" > "$db2.sql"
	        tar -czf "$db1.tar.gz" "$db1.sql" >/dev/null 2>&1
	        tar -czf "$db2.tar.gz" "$db2.sql" >/dev/null 2>&1

	        paths="$paths $db1.tar.gz $db2.tar.gz"
	    fi

	    if [[ ! -d "$dstdir" ]]
	    then

	        mkdir -p "$dstdir"

	    fi

	    if [[ -f "$dstdir/$filename" ]]
	    then

	        rm -f "$dstdir/$filename"

	    fi

	    tar -czf "$dstdir/$filename" \
	        --exclude ftp-data/logs \
	        --exclude ftp-data/pzs-ng \
	        --exclude ftp-data/backup \
	        $paths >/dev/null 2>&1

	    if [[ -f /usr/sbin/mariadbd ]]
	    then

	        rm -f "$db1.tar.gz" "$db2.tar.gz" "$db1.sql" "$db2.sql"

	    fi

	    print_status_done
	    ;;

	restore)

	    count=$(ls backup-*.gz 2>/dev/null | wc -l)

	    if (( count == 0 ))
	    then

	        echo "No backup file found in current dir, please move it to current dir and try again."
	        exit 0

	    fi

	    if (( count > 1 ))
	    then

	        echo "More than one backup file present, ensure that only the relevant backup is present in current dir."
	        ls backup-*.gz
	        exit 0

	    fi

	    if [[ ! -f /usr/sbin/mariadbd ]]
	    then

	        echo "mariadb-server not installed. If you use section-traffic or tur-trial then you need to install mariadb-server before running this script."
	        echo
	        echo "To install mariadb-server do the command: apt-get install mariadb-server"
	        echo
	        read -p "[A]bort or [C]ontinue? A/C : " abort

	        case "$abort" in
	            [Aa]*)

	                echo "Aborting"
	                exit 1
	                ;;

	        esac

	    fi

	    restore="$dstdir/restore"
		echo
	    print_status_start "Downloading glFTPd"

	    if [[ ! -d "$restore" ]]
	    then

	        mkdir -p "$restore"

	    fi

	    latest=$(curl -s https://glftpd.io | grep "/files/glftpd" | grep -v BETA | grep -o "glftpd-LNX.*.tgz" | head -1)
	    version=$(lscpu | grep Architecture | awk '{print $2}')

	    case "$version" in
	        i686)

	            version="32"
	            latest=$(echo "$latest" | sed 's/x64/x86/')
	            ;;

	        x86_64)

	            version="64"
	            ;;

	    esac

	    wget -P "$restore" -q "https://glftpd.io/files/$latest"
	    PK=$(ls "$restore" | grep glftpd-LNX | grep "x$version")
	    tar -xf "$restore/$PK" -C "$restore"
	    PKDIR=$(echo "$PK" | sed 's|.tgz||')

	    print_status_done

	    print_status_start "Setting up glFTPd"

	    CHKGR=$(grep -w "glftpd" /etc/group | cut -d ":" -f1)
	    CHKUS=$(grep -w "sitebot" /etc/passwd | cut -d ":" -f1)

	    if [[ "$CHKGR" != "glftpd" ]]
	    then

	        groupadd glftpd -g 199

	    fi

	    if [[ "$CHKUS" != "sitebot" ]]
	    then

	        useradd -d "$glroot/sitebot" -m -g glftpd -s /bin/bash sitebot
	        chfn -f 0 -r 0 -w 0 -h 0 sitebot

	    fi

	    cp -fr "$restore/$PKDIR/bin" "$glroot"
	    cp -fr "$restore/$PKDIR/docs" "$glroot"
	    cp -fr "$restore/$PKDIR/etc" "$glroot"
	    cp -fr "$restore/$PKDIR/ftp-data" "$glroot"
	    cp -fr "$restore/$PKDIR/gcp" "$glroot"

	    print_status_done

	    print_status_start "Restoring backup"

	    mkdir -p "$restore/bup"
	    mkdir -p "$glroot/site"
	    tar -xf backup-*.gz -C "$restore/bup"

	    cp "$restore/bup/etc/rsyslog.d/glftpd.conf" /etc/rsyslog.d && service rsyslog restart

	    cp -fr "$restore/bup/glftpd/backup" "$glroot"
	    cp -fr "$restore/bup/glftpd/bin" "$glroot"
	    cp -fr "$restore/bup/glftpd/etc" "$glroot"
	    cp -fr "$restore/bup/glftpd/ftp-data" "$glroot"
	    cp -fr "$restore/bup/glftpd/sitebot" "$glroot"
	    chown -R sitebot:glftpd "$glroot/sitebot"
	    read -p "Do you want me to restore the directories in $glroot/site?, default Y : " restore_site_dirs
	    case $restore_site_dirs in
	    	[nN)
	    		return
	    		;;
	    	*)
	    		sections=$(awk -F\" '/^set sections/ {print $2}' $glroot/sitebot/scripts/pzs-ng/ngBot.conf | xargs)
	    		;;
	    esac
	    cp -fr "$restore/bup/glftpd/usr" "$glroot"

	    cp "$restore/bup/glftpd/libcopy.sh" "$glroot" && "$glroot/libcopy.sh" >/dev/null 2>&1

	    mkdir -p "$glroot/dev"
	    mknod "$glroot/dev/null" c 1 3 ; chmod 666 "$glroot/dev/null"
	    mknod "$glroot/dev/zero" c 1 5 ; chmod 666 "$glroot/dev/zero"
	    mknod "$glroot/dev/full" c 1 7 ; chmod 666 "$glroot/dev/full"
	    mknod "$glroot/dev/urandom" c 1 9 ; chmod 666 "$glroot/dev/urandom"

	    mkdir -m 777 -p "$glroot/tmp"
	    chmod 777 "$glroot/ftp-data/logs"

	    if [[ -f $glroot/bin/psxc-imdb-sanity.sh ]]
	    then

	        "$glroot/bin/psxc-imdb-sanity.sh" >/dev/null 2>&1

	    fi

	    touch "$glroot/ftp-data/logs/psxc-moviedata.log"

	    if [[ -f $glroot/bin/tvmaze-nuker.sh ]]
	    then

	        "$glroot/bin/tvmaze-nuker.sh" sanity >/dev/null 2>&1

	    fi

	    chmod 666 "$glroot/ftp-data/logs/"*

	    if [[ -f /usr/sbin/mariadbd ]]
	    then

	        # Restore MariaDB glFTPd-specific config to /etc/mysql (renamed file)
	        if [[ -f "$restore/bup/etc/mysql/mariadb-glftpd.cnf" ]]
	        then

	            cp -f "$restore/bup/etc/mysql/mariadb-glftpd.cnf" /etc/mysql/

	        fi
	        
	        # Restore custom MariaDB systemd service (if part of backup)
	        if [[ -f "$restore/bup/etc/systemd/system/mariadb-glftpd.service" ]]
	        then

	            cp -f "$restore/bup/etc/systemd/system/mariadb-glftpd.service" /etc/systemd/system/
	            systemctl daemon-reload

	        fi        

	        # Initialize and start MariaDB
	        install -d -m 0750 -o mysql -g mysql "$glroot/backup/mysql"
	        mysql_install_db --user=mysql --datadir="$glroot/backup/mysql" >/dev/null 2>&1 && systemctl enable --now mariadb-glftpd >/dev/null 2>&1

			# Wait up to 30s for the socket
	        if ! timeout 30 bash -c 'until mysqladmin -uroot -S /run/mysqld/mariadb-glftpd.sock ping >/dev/null 2>&1; do sleep 1; done'
	        then

	        	echo "mariadb-glftpd failed to become ready" >&2
	            journalctl -u mariadb-glftpd -b --no-pager | tail -n 200 >&2
	            exit 1

	       	fi

	        # Databases and users
	        mysql -S /run/mysqld/mariadb-glftpd.sock -uroot -e "CREATE DATABASE IF NOT EXISTS $db1"
	        mysql -S /run/mysqld/mariadb-glftpd.sock -uroot -e "CREATE DATABASE IF NOT EXISTS $db2"
	        mysql -S /run/mysqld/mariadb-glftpd.sock -uroot -e "CREATE USER IF NOT EXISTS 'trial'@'localhost' IDENTIFIED BY '$pass';"
	        mysql -S /run/mysqld/mariadb-glftpd.sock -uroot -e "CREATE USER IF NOT EXISTS 'transfer'@'localhost' IDENTIFIED BY '$pass';"
	        mysql -S /run/mysqld/mariadb-glftpd.sock -uroot -e "GRANT ALL PRIVILEGES ON $db1.* TO 'trial'@'localhost';"
	        mysql -S /run/mysqld/mariadb-glftpd.sock -uroot -e "GRANT ALL PRIVILEGES ON $db2.* TO 'transfer'@'localhost';"
	        mysql -S /run/mysqld/mariadb-glftpd.sock -uroot -e "FLUSH PRIVILEGES"

	        # Unpack and import dumps (if present)
	        if [[ -f "$restore/bup/trial.tar.gz" ]]
	        then

	            tar -xf "$restore/bup/trial.tar.gz" -C "$restore/bup"

	        fi

	        if [[ -f "$restore/bup/transfers.tar.gz" ]]
	        then

	            tar -xf "$restore/bup/transfers.tar.gz" -C "$restore/bup"

	        fi

	        if [[ -f "$restore/bup/trial.sql" ]]
	        then

	            mysql -S /run/mysqld/mariadb-glftpd.sock -uroot -D "$db1" < "$restore/bup/trial.sql"

	        fi

	        if [[ -f "$restore/bup/transfers.sql" ]]
	        then

	            mysql -S /run/mysqld/mariadb-glftpd.sock -uroot -D "$db2" < "$restore/bup/transfers.sql"

	        fi

	    fi

		# Restore glftpd services from backup, using services.d if available
		services=$(grep -E "glftpd[[:space:]]" "$restore/bup/etc/services" 2>/dev/null || true)
		[[ -d "$restore/bup/etc/services.d" ]] && \
		    services+=$(find "$restore/bup/etc/services.d" -type f -exec grep -E "glftpd[[:space:]]" {} + 2>/dev/null || true)

		if [[ -n "$services" ]]
		then

		    if [[ -d /etc/services.d ]]
		    then

		        echo "$services" > /etc/services.d/glftpd

		    else

		        echo "$services" >> /etc/services

		    fi

		fi

	    cp -f "$restore/bup/etc/systemd/system/glftpd.socket" /etc/systemd/system
	    cp -f "$restore/bup/etc/systemd/system/glftpd@.service" /etc/systemd/system

	    if [[ -f /etc/inetd.conf ]]
	    then

	        inetd=$(grep glftpd "$restore/bup/etc/inetd" || true)
	        if [[ -n "$inetd" ]]
	        then

	            echo "$inetd" >> /etc/inetd.conf
	            kill -HUP inetd

	        fi

	    fi

	    if [[ -f /etc/glftpd.conf ]]
	    then

	        rm -f /etc/glftpd.conf

	    fi

	    ln -s "$glroot/etc/glftpd.conf" /etc/glftpd.conf

	    cp -f "$restore/bup/var/spool/cron/crontabs/root" /var/spool/cron/crontabs/root
	    cp -f "$restore/bup/var/spool/cron/crontabs/sitebot" /var/spool/cron/crontabs/sitebot

	    cd "$glroot/backup/pzs-ng"
	    make distclean >/dev/null 2>&1
	    ./configure >/dev/null 2>&1
	    make >/dev/null 2>&1
	    make install >/dev/null 2>&1
	    cd "$curdir"

	    # Reload systemd and start services
	    systemctl daemon-reload
	    systemctl restart glftpd.socket
	    systemctl restart mariadb-glftpd
	    service cron restart

	    rm -rf "$restore"

	    print_status_done
	    echo
	    echo "Backup restored, enjoy!"
	    ;;

	cleanup)

	    if (( $(mount | grep "/glftpd" | wc -l) >= 1 ))
	    then

	        echo "You have mounted dirs in the path of /glftpd, unmount all including /glftpd and try again."
	        exit 1

	    fi

	    echo -e "This will remove everything under ${RED}/glftpd${RESET} including ${RED}/glftpd/site${RESET} and undo system changes made by the installer"
	    echo
	    read -p "Are you sure you want to proceed? [Y]es [N]o, default N : " cleanup

	    case "$cleanup" in
	        [Yy])

	            print_status_start "Starting cleanup"

	            rm -rf /glftpd
	            rm -f /etc/glftpd.conf
	            rm -rf /var/spool/mail/sitebot
	            rm -f /etc/rsyslog.d/glftpd.conf

	            killall sitebot >/dev/null 2>&1
	            sleep 3

	            userdel sitebot >/dev/null 2>&1
	            groupdel glftpd >/dev/null 2>&1
				
				rm -f /etc/services.d/glftpd
	            sed -i /glftpd/d /etc/services

	            if [[ -f /etc/inetd.conf ]]
	            then

	                sed -i /glftpd/d /etc/inetd.conf
	                killall -HUP inetd

	            fi

	            sed -i /glftpd/Id /var/spool/cron/crontabs/root
	            rm -f /var/spool/cron/crontabs/sitebot

	            if [[ -f /etc/systemd/system/glftpd.socket ]]
	            then

	                systemctl stop glftpd.socket >/dev/null 2>&1
	                systemctl disable glftpd.socket >/dev/null 2>&1
	                rm -f /etc/systemd/system/glftpd*
	                systemctl daemon-reload
	                systemctl reset-failed

	            fi
            
	            if [[ -f /etc/systemd/system/mariadb-glftpd.service ]]
	            then

	                systemctl stop mariadb-glftpd.service >/dev/null 2>&1
	                systemctl disable mariadb-glftpd.service >/dev/null 2>&1
	                rm -f /etc/systemd/system/mariadb-glftpd.service
	                systemctl daemon-reload
	                systemctl reset-failed

	            fi

	            if [[ -f /etc/mysql/mariadb-glftpd.cnf ]]
	            then

	                rm -f /etc/mysql/mariadb-glftpd.cnf

	            fi

	            print_status_done
	            ;;

	    esac
	    ;;

	*)

    echo "$0 backup  - To create a backup of glFTPd settings, users and sitebot including system settings"
    echo "$0 restore - To restore a backup of glFTPd settings, users and sitebot including system settings"
    echo "$0 cleanup - To cleanup all traces related to glFTPd"
    ;;

esac
