if has_key "$cache" whereami
then

    ask=$(get_value "$cache" whereami)

else

    echo
    echo "${yellow}Description for Whereami:${reset}"
    cat $rootdir/packages/modules/whereami/description
    echo
    read -p "Install Whereami ? [Y]es [N]o, default Y : " ask

fi

case $ask in

    [Nn])

        if ! has_key "$cache" whereami
        then

            echo 'whereami="n"' >> $cache

        fi
        ;;

    [Yy]|*)

        if ! has_key "$cache" whereami
        then

            echo 'whereami="y"' >> $cache

        fi

        print_status_start "Installing" "Whereami"

        cp $rootdir/packages/modules/whereami/whereami.sh $glroot/bin
        cp $rootdir/packages/modules/whereami/whereami.tcl $glroot/sitebot/scripts
        echo "source scripts/whereami.tcl" >> $glroot/sitebot/eggdrop.conf

        print_status_done
	;;

esac
