if [[ -f "$cache" && "`grep -w "autonuke" $cache | wc -l`" = 1 ]]
then
    ask=`grep -w "autonuke" $cache | cut -d "=" -f2 | tr -d "\""`
else
    echo
    echo -e "\e[4mDescription for Tur-Autonuke:\e[0m"
    cat $rootdir/packages/modules/tur-autonuke/description
    echo
    echo -n "Install Tur-Autonuke ? [Y]es [N]o, default Y : " ; read ask
fi

case $ask in
    [Nn])
        if [[ -f "$cache" && "`grep -w "autonuke=" $cache | wc -l`" = 0 ]]
        then
            echo 'autonuke="n"' >> $cache
        fi
        ;;
    [Yy]|*)
        if [[ -f "$cache" && "`grep -w "autonuke=" $cache | wc -l`" = 0 ]]
        then
            echo 'autonuke="y"' >> $cache
        fi

        echo -n "Installing Tur-Autonuke, please wait...                         "
        mv $rootdir/packages/modules/tur-autonuke/tur-autonuke.conf $glroot/bin
        cp $rootdir/packages/modules/tur-autonuke/tur-autonuke.sh $glroot/bin
        echo "*/10 * * * *          $glroot/bin/tur-autonuke.sh >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
        touch $glroot/ftp-data/logs/tur-autonuke.log
        echo -e "[\e[32mDone\e[0m]"
        ;;
esac
