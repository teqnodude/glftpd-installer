if has_key "$cache" autonuke
then

    ask=$(get_value "$cache" autonuke)

else

    echo
    echo "${yellow}Description for Tur-Autonuke:${reset}"
    cat $rootdir/packages/modules/tur-autonuke/description
    echo
    read -p "Install Tur-Autonuke ? [Y]es [N]o, default N : " ask

fi

case $ask in

    [Nn]|*)

        if ! has_key "$cache" autonuke
        then

            echo 'autonuke="n"' >> $cache

        fi
        ;;

    [Yy])

        if ! has_key "$cache" autonuke
        then

            echo 'autonuke="y"' >> $cache

        fi

        print_status_start "Installing" "Tur-Autonuke"

        mv $rootdir/packages/modules/tur-autonuke/tur-autonuke.conf $glroot/bin
        cp $rootdir/packages/modules/tur-autonuke/tur-autonuke.sh $glroot/bin
        add_cron_job "*/10 * * * *" "$glroot/bin/tur-autonuke.sh"
        touch $glroot/ftp-data/logs/tur-autonuke.log

        print_status_done
        ;;

esac
