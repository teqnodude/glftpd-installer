if has_key "$cache" request
then

    ask=$(get_value "$cache" request)

else

    echo
    echo "${yellow}Description for Tur-Request:${reset}"
    cat $rootdir/packages/modules/tur-request/description
    echo
    read -p "Install Tur-Request ? [Y]es [N]o, default Y : " ask

fi

case $ask in

    [Nn])

        if ! has_key "$cache" request
        then

            echo 'request="n"' >> $cache

        fi
        ;;

    [Yy]|*)

        if ! has_key "$cache" request
        then

            echo 'request="y"' >> $cache

        fi

        print_status_start "Installing" "Tur-Request"

        cp $rootdir/packages/modules/tur-request/tur-request.sh $glroot/bin
        cp $rootdir/packages/modules/tur-request/*.tcl $glroot/sitebot/scripts
	[ ! -f $glroot/bin/file_date ] && gcc -o $glroot/bin/file_date $rootdir/packages/modules/tur-request/file_date.c
        sed "s/changeme/$sitename/" $rootdir/packages/modules/tur-request/tur-request.conf > $glroot/bin/tur-request.conf
        mkdir -m777 $glroot/site/REQUESTS
        touch $glroot/site/REQUESTS/.requests ; chmod 666 $glroot/site/REQUESTS/.requests
	add_cron_job "1 18 * * *" "$glroot/bin/tur-request.sh status auto"
	add_cron_job "1 0 * * *" "$glroot/bin/tur-request.sh checkold"
        touch $glroot/ftp-data/logs/tur-request.log
        echo "source scripts/tur-request.no_auth.tcl" >> $glroot/sitebot/eggdrop.conf
        cat $rootdir/packages/modules/tur-request/gl >> $glroot/etc/glftpd.conf

        print_status_done
        ;;

esac
