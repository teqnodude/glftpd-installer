if has_key "$cache" ircadmin
then

    ask=$(get_value "$cache" ircadmin)

else

    echo
    echo "${yellow}Description for Tur-Ircadmin:${reset}"
    cat $rootdir/packages/modules/tur-ircadmin/description
    echo
    read -p "Install Tur-Ircadmin ? [Y]es [N]o, default Y : " ask

fi

case $ask in

    [Nn])

        if ! has_key "$cache" ircadmin
        then

            echo 'ircadmin="n"' >> $cache

        fi
        ;;

    [Yy]|*)

        if ! has_key "$cache" ircadmin
        then

            echo 'ircadmin="y"' >> $cache

        fi

        print_status_start "Installing" "Tur-Ircadmin"

        cp $rootdir/packages/modules/tur-ircadmin/tur-ircadmin.sh $glroot/bin
        cp $rootdir/packages/modules/tur-ircadmin/tur-ircadmin.tcl $glroot/sitebot/scripts
        touch $glroot/ftp-data/logs/tur-ircadmin.log
        echo "source scripts/tur-ircadmin.tcl" >> $glroot/sitebot/eggdrop.conf
        sed -i "s/changeme/$channelops/" $glroot/sitebot/scripts/tur-ircadmin.tcl
        sed -i "s/changeme/$port/" $glroot/bin/tur-ircadmin.sh
        cat $rootdir/packages/modules/tur-ircadmin/gl >> $glroot/etc/glftpd.conf

        print_status_done
        ;;

esac
