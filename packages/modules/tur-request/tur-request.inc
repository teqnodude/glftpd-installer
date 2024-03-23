if [[ -f "$cache" && "`grep -w "request" $cache | wc -l`" = 1 ]]
then
    ask=`grep -w "request" $cache | cut -d "=" -f2 | tr -d "\""`
else
    echo
    echo -e "\e[4mDescription for Tur-Request:\e[0m"
    cat $rootdir/packages/modules/tur-request/description
    echo
    echo -n "Install Tur-Request ? [Y]es [N]o, default Y : " ; read ask
fi

case $ask in
    [Nn])
        if [[ -f "$cache" && "`grep -w "request=" $cache | wc -l`" = 0 ]]
        then
            echo 'request="n"' >> $cache
        fi
        ;;
    [Yy]|*)
        if [[ -f "$cache" && "`grep -w "request=" $cache | wc -l`" = 0 ]]
        then
            echo 'request="y"' >> $cache
        fi

        echo -n "Installing Tur-Request, please wait..." | awk '{printf("%-64s",$0)}'
        cp $rootdir/packages/modules/tur-request/tur-request.sh $glroot/bin
        cp $rootdir/packages/modules/tur-request/*.tcl $glroot/sitebot/scripts
	[ ! -f $glroot/bin/file_date ] && gcc -o $glroot/bin/file_date $rootdir/packages/modules/tur-request/file_date.c
        sed "s/changeme/$sitename/" $rootdir/packages/modules/tur-request/tur-request.conf > $glroot/bin/tur-request.conf
        mkdir -m777 $glroot/site/REQUESTS
        touch $glroot/site/REQUESTS/.requests ; chmod 666 $glroot/site/REQUESTS/.requests
        echo "1 18 * * *            $glroot/bin/tur-request.sh status auto >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
        echo "1 0 * * *             $glroot/bin/tur-request.sh checkold >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
        touch $glroot/ftp-data/logs/tur-request.log
        echo "source scripts/tur-request.no_auth.tcl" >> $glroot/sitebot/eggdrop.conf
        cat $rootdir/packages/modules/tur-request/gl >> $glroot/etc/glftpd.conf
        echo -e "[\e[32mDone\e[0m]"
        ;;
esac
