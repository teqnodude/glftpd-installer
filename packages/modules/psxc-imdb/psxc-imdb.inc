if [[ -f "$cache" && "`grep -w "psxcimdb" $cache | wc -l`" = 1 ]]
then
    ask=`grep -w "psxcimdb" $cache | cut -d "=" -f2 | tr -d "\""`
else
    echo
    echo -e "\e[4mDescription for PSXC-IMDB:\e[0m"
    cat $rootdir/packages/modules/psxc-imdb/description
    echo
    echo -n "Install PSXC-IMDB ? [Y]es [N]o, default Y : " ; read ask
fi

case $ask in
    [Nn])
        if [[ -f "$cache" && "`grep -w "psxcimdb=" $cache | wc -l`" = 0 ]]
        then
            echo 'psxcimdb="n"' >> $cache
        fi
        ;;
    [Yy]|*)
        if [[ -f "$cache" && "`grep -w "psxcimdb=" $cache | wc -l`" = 0 ]]
        then
            echo 'psxcimdb="y"' >> $cache
        fi

        if [[ -f "$cache" && "`grep -w "psxcimdbchan" $cache | wc -l`" = 1 ]]
        then
            imdbchan=`grep -w "psxcimdbchan" $cache | cut -d "=" -f2 | tr -d "\""`
        else
            while [[ -z $imdbchan ]]
            do
                echo -n "IMDB announce channels, default $announcechannels : " ; read imdbchan
            done
        fi

        echo -n "Installing PSXC-IMDB, please wait...                            "
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
        echo -e "[\e[32mDone\e[0m]"
        [ -z $imdbchan ] && imdbchan=$announcechannels
        sed -i "s/#changethis/$imdbchan/" $glroot/sitebot/scripts/pzs-ng/plugins/psxc-imdb.tcl

        if [[ -f "$cache" && "`grep -w "psxcimdbchan=" $cache | wc -l`" = 0 ]]
        then
            echo "psxcimdbchan=\"$imdbchan\"" >> $cache
        fi
        ;;
esac
