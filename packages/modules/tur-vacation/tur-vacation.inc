if has_key "$cache" vacation
then

    ask=$(get_value "$cache" vacation)

else

    echo
    echo "${yellow}Description for Tur-Vacation:${reset}"
    cat $rootdir/packages/modules/tur-vacation/description
    echo
    read -p "Install Tur-Vacation ? [Y]es [N]o, default Y : " ask

fi

case $ask in

    [Nn])

        if ! has_key "$cache" vacation
        then

            echo 'vacation="n"' >> $cache

        fi
        ;;

    [Yy]|*)

        if ! has_key "$cache" vacation
        then

            echo 'vacation="y"' >> $cache

        fi

        print_status_start "Installing" "Tur-Vacation"

        cp $rootdir/packages/modules/tur-vacation/tur-vacation.sh $glroot/bin
        touch $glroot/etc/vacation.index ; chmod 666 $glroot/etc/vacation.index
        touch $glroot/etc/quota_vacation.db ; chmod 666 $glroot/etc/quota_vacation.db
        cat $rootdir/packages/modules/tur-vacation/gl >> $glroot/etc/glftpd.conf

        print_status_done
        ;;

esac
