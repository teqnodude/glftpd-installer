if has_key "$cache" slvprebw
then

    ask=$(get_value "$cache" slvprebw)

else

    echo
    echo "${yellow}Description for slv-PreBW:${reset}"
    cat $rootdir/packages/modules/slv-prebw/description
    echo
    read -p "Install slv-PreBW ? [Y]es [N]o, default Y : " ask

fi

case $ask in

    [Nn])

        if ! has_key "$cache" slvprebw
        then

            echo 'slvprebw="n"' >> $cache

        fi
        ;;

    [Yy]|*)

        if ! has_key "$cache" slvprebw
        then

            echo 'slvprebw="y"' >> $cache

        fi

        print_status_start "Installing" "slv-PreBW"

        cp $rootdir/packages/modules/slv-prebw/slv-prebw.sh $glroot/bin
        cp $rootdir/packages/modules/slv-prebw/PreBW.tcl $glroot/sitebot/scripts/pzs-ng/plugins
        echo "source scripts/pzs-ng/plugins/PreBW.tcl" >> $glroot/sitebot/eggdrop.conf

        print_status_done
        ;;

esac
