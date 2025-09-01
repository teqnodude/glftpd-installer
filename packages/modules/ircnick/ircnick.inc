if has_key "$cache" ircnick
then

    ask=$(get_value "$cache" ircnick)

else

    echo
    echo "${yellow}Description for Ircnick:${reset}"
    cat $rootdir/packages/modules/ircnick/description
    echo
    read -p "Install Ircnick ? [Y]es [N]o, default Y : " ask

fi

case $ask in

    [Nn])

        if ! has_key "$cache" ircnick
        then

            echo 'ircnick="n"' >> $cache

        fi
        ;;

    [Yy]|*)

        if ! has_key "$cache" ircnick
        then

            echo 'ircnick="y"' >> $cache

        fi

        print_status_start "Installing" "Ircnick"

        cp $rootdir/packages/modules/ircnick/*.sh $glroot/bin
        cp $rootdir/packages/modules/ircnick/*.tcl $glroot/sitebot/scripts
        sed -i "s/changeme/$channelops/" $glroot/sitebot/scripts/ircnick.tcl
        echo "source scripts/ircnick.tcl" >> $glroot/sitebot/eggdrop.conf

        print_status_done
        ;;

esac
