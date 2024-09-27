if [[ -f "$cache" && "`grep -w "section_traffic" $cache | wc -l`" = 1 ]]
then
    ask=`grep -w "section_traffic" $cache | cut -d "=" -f2 | tr -d "\""`
else
    echo
    echo -e "\e[4mDescription for Section-Traffic:\e[0m"
    cat $rootdir/packages/modules/section-traffic/description
    echo
    echo -n "Install Section-Traffic ? [Y]es [N]o, default Y : " ; read ask
fi

case $ask in
    [Nn])
        if [[ -f "$cache" && "`grep -w "section_traffic=" $cache | wc -l`" = 0 ]]
        then
            echo 'section_traffic="n"' >> $cache
        fi
        ;;
    [Yy]|*)
        if [[ -f "$cache" && "`grep -w "section_traffic=" $cache | wc -l`" = 0 ]]
        then
            echo 'section_traffic="y"' >> $cache
        fi

        echo -n "Installing Section-Traffic, please wait..." | awk '{printf("%-64s",$0)}'
        if [ ! -f "/usr/sbin/mariadbd" ]
        then
            echo "No MySQL installed, can't install script. Install MySQL and run ./cleanup.sh and this installer again."
        else
            current=`shasum /etc/mysql/mariadb.conf.d/50-server.cnf | cut -d' ' -f1`
            new=`shasum $rootdir/packages/modules/section-traffic/50-server.cnf | cut -d' ' -f1`
            if [ "$current" != "$new" ]
            then
                mv  /etc/mysql/mariadb.conf.d/50-server.cnf  /etc/mysql/mariadb.conf.d/50-server.cnf.bak
                cp -f $rootdir/packages/modules/section-traffic/50-server.cnf /etc/mysql/mariadb.conf.d/
            fi
            if [ ! -d $glroot/backup/mysql ]
            then
                service mysql stop && mysql_install_db >/dev/null 2>&1 && service mysql start
            fi
            cp $rootdir/packages/modules/section-traffic/xferlog-import_3.3.sh $glroot/bin && sed -i "s/changeme/$sitename/" $glroot/bin/xferlog-import_3.3.sh
            cp $rootdir/packages/modules/section-traffic/section-traffic.sh $glroot/bin && sed -i "s/changeme/$sitename/" $glroot/bin/section-traffic.sh
	    sed -i "s/SQLPASS=\"\"/SQLPASS=\"$SQLPASSWD\"/" $glroot/bin/section-traffic.sh
	    sed -i "s/SQLPASS=\"\"/SQLPASS=\"$SQLPASSWD\"/" $glroot/bin/xferlog-import_3.3.sh
            cp $rootdir/packages/modules/section-traffic/section-traffic.tcl $glroot/sitebot/scripts
            echo "source scripts/section-traffic.tcl" >> $glroot/sitebot/eggdrop.conf
            sed -i "s/changeme/$channelops/" $glroot/sitebot/scripts/section-traffic.tcl
            sed "s/changeme/$sitename/" $rootdir/packages/modules/section-traffic/import.sql > $rootdir/packages/modules/section-traffic/import.sql.new
            cp $rootdir/packages/modules/section-traffic/setup-section-traffic.sh $rootdir/packages/modules/section-traffic/setup-section-traffic.sh.new 
	    sed -i "s/SQLPASS=\"\"/SQLPASS=\"$SQLPASSWD\"/" $rootdir/packages/modules/section-traffic/setup-section-traffic.sh.new 
	    cd $rootdir/packages/modules/section-traffic && ./setup-section-traffic.sh.new create && rm import.sql.new && rm setup-section-traffic.sh.new && cd $rootdir
            echo "*/30 * * * *            $glroot/bin/xferlog-import_3.3.sh >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
            echo "30 0 * * *              $glroot/bin/section-traffic.sh cleanup >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
            echo -e "[\e[32mDone\e[0m]"
        fi
        ;;
esac
