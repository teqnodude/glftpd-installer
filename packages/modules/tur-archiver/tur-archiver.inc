if has_key "$cache" archiver
then

    ask=$(get_value "$cache" archiver)

else

    echo
    echo "${yellow}Description for Tur-Archiver:${reset}"
    cat $rootdir/packages/modules/tur-archiver/description
    echo
    read -p "Install Tur-Archiver ? [Y]es [N]o, default Y : " ask

fi

case $ask in

    [Nn])

        if ! has_key "$cache" archiver
        then

            echo 'archiver="n"' >> $cache

        fi
        ;;

    [Yy]|*)

        if ! has_key "$cache" archiver
        then

            echo 'archiver="y"' >> $cache

        fi

        print_status_start "Installing" "Tur-Archiver"

        cp $rootdir/packages/modules/tur-archiver/tur-archiver.sh $glroot/bin
        [ ! -f $glroot/bin/file_date ] && gcc -o $glroot/bin/file_date $rootdir/packages/modules/tur-archiver/file_date.c
        add_cron_job "0 0 * * *" "$glroot/bin/tur-archiver.sh"

        print_status_done
        ;;

esac
