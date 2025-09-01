if has_key "$cache" precheck
then

    ask=$(get_value "$cache" precheck)

else

    echo
    echo "${yellow}Description for Precheck:${reset}"
    cat $rootdir/packages/modules/precheck/description
    echo
    read -p "Install Precheck ? [Y]es [N]o, default Y : " ask

fi

case $ask in

    [Nn])

        if ! has_key "$cache" precheck
        then

            echo 'precheck="n"' >> $cache

        fi
        ;;

    [Yy]|*)

        if ! has_key "$cache" precheck
        then

            echo 'precheck="y"' >> $cache

        fi

        print_status_start "Installing" "Precheck"

        cp $rootdir/packages/modules/precheck/precheck*.sh $glroot/bin
        cp $rootdir/packages/modules/precheck/precheck.tcl $glroot/sitebot/scripts
        echo "source scripts/precheck.tcl" >> $glroot/sitebot/eggdrop.conf
        touch $glroot/ftp-data/logs/precheck.log

        print_status_done
        ;;

esac
