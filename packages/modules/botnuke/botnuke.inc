if has_key "$cache" botnuke
then

    ask=$(get_value "$cache" botnuke)

else

    echo
    echo "${yellow}Description for Botnuke:${reset}"
    cat $rootdir/packages/modules/botnuke/description
    echo
    read -p "Install Botnuke ? [Y]es [N]o, default Y : " ask

fi

case $ask in

    [Nn])

        if ! has_key "$cache" botnuke
        then

            echo 'botnuke="n"' >> $cache

        fi
        ;;

    [Yy]|*)

        if ! has_key "$cache" botnuke
        then

            echo 'botnuke="y"' >> $cache

        fi

        print_status_start "Installing" "Botnuke"

        cp $rootdir/packages/modules/botnuke/botnuke.tcl $glroot/sitebot/scripts
        cp $rootdir/packages/modules/botnuke/botnuke.sh $glroot/bin
        echo "source scripts/botnuke.tcl" >> $glroot/sitebot/eggdrop.conf

        print_status_done
        ;;

esac
