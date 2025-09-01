if has_key "$cache" top
then

    ask=$(get_value "$cache" top)

else

    echo
    echo "${yellow}Description for Top:${reset}"
    cat $rootdir/packages/modules/top/description
    echo
    read -p "Install Top ? [Y]es [N]o, default Y : " ask

fi

case $ask in

    [Nn])

        if ! has_key "$cache" top
        then

            echo 'top="n"' >> $cache

        fi
        ;;

    [Yy]|*)

        if ! has_key "$cache" top
        then

            echo 'top="y"' >> $cache

        fi

        print_status_start "Installing" "Top"

        cp $rootdir/packages/modules/top/top.tcl $glroot/sitebot/scripts
        cp $rootdir/packages/modules/top/top.sh $glroot/bin
        echo "source scripts/top.tcl" >> $glroot/sitebot/eggdrop.conf

        print_status_done
        ;;

esac
