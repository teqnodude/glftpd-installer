if [[ -f "$cache" && "`grep -w "trial" $cache | wc -l`" = 1 ]]
then
    ask=`grep -w "trial" $cache | cut -d "=" -f2 | tr -d "\""`
else
    echo
    echo -e "\e[4mDescription for Tur-Trial3:\e[0m"
    cat $rootdir/packages/modules/tur-trial3/description
    echo
    echo -n "Install Tur-Trial3 ? [Y]es [N]o, default Y : " ; read ask
fi

case $ask in
    [Nn])
        if [[ -f "$cache" && "`grep -w "trial=" $cache | wc -l`" = 0 ]]
        then
            echo 'trial="n"' >> $cache
        fi
        ;;
    [Yy]|*)
        if [[ -f "$cache" && "`grep -w "trial=" $cache | wc -l`" = 0 ]]
        then
            echo 'trial="y"' >> $cache
        fi

        echo -n "Installing Tur-Trial3, please wait..." | awk '{printf("%-64s",$0)}'
        if [ ! -f "/usr/sbin/mariadbd" ]
        then
            echo "No MySQL installed, can't install script. Install MySQL and run ./cleanup.sh and this installer again."
        else
            cp $rootdir/packages/modules/tur-trial3/tur-trial3.sh $glroot/bin
            cp $rootdir/packages/modules/tur-trial3/midnight.sh $glroot/bin
            cp $rootdir/packages/modules/tur-trial3/tur-trial3.conf $glroot/bin
	    sed -i "s/SQLPASS=\"\"/SQLPASS=\"$SQLPASSWD\"/" $glroot/bin/tur-trial3.conf
            cp $rootdir/packages/modules/tur-trial3/tur-trial3.theme $glroot/bin
            cp $rootdir/packages/modules/tur-trial3/tur-trial3.tcl $glroot/sitebot/scripts
            cp $rootdir/packages/modules/tur-trial3/import.sql $rootdir/packages/modules/tur-trial3/import.sql.new
            current=`shasum /etc/mysql/mariadb.conf.d/50-server.cnf | cut -d' ' -f1`
            new=`shasum $rootdir/packages/modules/tur-trial3/50-server.cnf | cut -d' ' -f1`
            if [ "$current" != "$new" ]
            then
                mv  /etc/mysql/mariadb.conf.d/50-server.cnf  /etc/mysql/mariadb.conf.d/50-server.cnf.bak
                cp -f $rootdir/packages/modules/tur-trial3/50-server.cnf /etc/mysql/mariadb.conf.d/
            fi
            if [ ! -d $glroot/backup/mysql ]
            then
                service mysql stop && mysql_install_db >/dev/null 2>&1 && service mysql start
            fi
    	cd $rootdir/packages/modules/tur-trial3
	    cp setup-tur-trial3.sh setup-tur-trial3.sh.new
	    sed -i "s/SQLPASS=\"\"/SQLPASS=\"$SQLPASSWD\"/" setup-tur-trial3.sh.new
            ./setup-tur-trial3.sh.new create && rm import.sql.new && rm setup-tur-trial3.sh.new
    	cd $rootdir
            echo "source scripts/tur-trial3.tcl" >> $glroot/sitebot/eggdrop.conf
            echo "*/31 * * * *              $glroot/bin/tur-trial3.sh update >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
            echo "*/30 * * * *              $glroot/bin/tur-trial3.sh tcron >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
            echo "45 23 * * *               $glroot/bin/tur-trial3.sh qcron >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
            echo "0 0 * * *                 $glroot/bin/midnight.sh >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
            sed -i 's|0 0 * * *.*reset -e|#0 0 * * *              /glftpd/bin/reset -e|' /var/spool/cron/crontabs/root
            if [ -f "`which mysql`" ]
            then
                cp `which mysql` $glroot/bin
            fi

            cat $rootdir/packages/modules/tur-trial3/gl >> $glroot/etc/glftpd.conf
            touch $glroot/ftp-data/logs/tur-trial3.log
            echo -e "[\e[32mDone\e[0m]"
        fi
        ;;
esac
