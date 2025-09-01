if has_key "$cache" psxcimdb
then

    ask=$(get_value "$cache" psxcimdb)

else

    echo
    echo "${yellow}Description for PSXC-IMDB:${reset}"
    cat $rootdir/packages/modules/psxc-imdb/description
    echo
    read -p "Install PSXC-IMDB ? [Y]es [N]o, default Y : " ask

fi

case $ask in

    [Nn])

        if ! has_key "$cache" psxcimdb
        then

            echo 'psxcimdb="n"' >> $cache

        fi
        ;;

    [Yy]|*)

        if ! has_key "$cache" psxcimdb
        then

            echo 'psxcimdb="y"' >> $cache

        fi

        if has_key "$cache" psxcimdbchan
        then

            imdbchan=$(get_value "$cache" psxcimdbchan)

        else

            read -p "IMDB announce channels, default $announcechannels : " imdbchan

        fi

        print_status_start "Installing" "PSXC-IMDB"

        cp $rootdir/packages/modules/psxc-imdb/extras/* $glroot/bin
        cp $rootdir/packages/modules/psxc-imdb/addons/* $glroot/bin
        cp $rootdir/packages/modules/psxc-imdb/main/psxc-imdb.sh $glroot/bin
        cp $rootdir/packages/modules/psxc-imdb/main/psxc-imdb.conf $glroot/etc
        cp $rootdir/packages/modules/psxc-imdb/main/psxc-imdb.tcl $glroot/sitebot/scripts/pzs-ng/plugins
        cp $rootdir/packages/modules/psxc-imdb/main/psxc-imdb.zpt $glroot/sitebot/scripts/pzs-ng/plugins
        $glroot/bin/psxc-imdb-sanity.sh >/dev/null 2>&1
        touch $glroot/ftp-data/logs/psxc-imdb-rescan.tmp
        touch $glroot/ftp-data/logs/psxc-moviedata.log
        echo "source scripts/pzs-ng/plugins/psxc-imdb.tcl" >> $glroot/sitebot/eggdrop.conf
        cat $rootdir/packages/modules/psxc-imdb/gl >> $glroot/etc/glftpd.conf

        [[ -z "$imdbchan" ]] && imdbchan=$announcechannels
        sed -i "s/#changethis/$imdbchan/" $glroot/sitebot/scripts/pzs-ng/plugins/psxc-imdb.tcl

        if ! has_key "$cache" psxcimdbchan
        then

            echo "psxcimdbchan=\"$imdbchan\"" >> $cache

        fi

        print_status_done
        ;;

esac
