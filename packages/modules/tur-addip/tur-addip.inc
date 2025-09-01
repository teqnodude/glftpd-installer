if has_key "$cache" addip
then

    ask=$(get_value "$cache" addip)

else

    echo
    echo "${yellow}Description for Tur-Addip:${reset}"
    cat $rootdir/packages/modules/tur-addip/description
    echo
    read -p "Install Tur-Addip ? [Y]es [N]o, default Y : " ask

fi

case $ask in

    [Nn])

        if ! has_key "$cache" addip
        then

            echo 'addip="n"' >> $cache

        fi
        ;;

    [Yy]|*)

        if ! has_key "$cache" addip
        then

            echo 'addip="y"' >> $cache

        fi

        print_status_start "Installing" "Tur-Addip"

        cp $rootdir/packages/modules/tur-addip/tur-addip.tcl $glroot/sitebot/scripts
        cp $rootdir/packages/modules/tur-addip/tur-addip.sh $glroot/bin
        echo "source scripts/tur-addip.tcl" >> $glroot/sitebot/eggdrop.conf
        touch $glroot/ftp-data/logs/tur-addip.log
        sed -i "s/changeme/$port/" $glroot/bin/tur-addip.sh
        sed -i "s/changeme/$channelops/" $glroot/sitebot/scripts/tur-addip.tcl

        print_status_done
        ;;

esac
