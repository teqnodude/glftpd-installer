if [[ -f "$cache" && "`grep -w "precheck" $cache | wc -l`" = 1 ]]
then
    ask=`grep -w "precheck" $cache | cut -d "=" -f2 | tr -d "\""`
else
    echo
    echo -e "\e[4mDescription for Precheck:\e[0m"
    cat $rootdir/packages/modules/precheck/description
    echo
    echo -n "Install Precheck ? [Y]es [N]o, default Y : " ; read ask
fi

case $ask in
    [Nn])
        if [[ -f "$cache" && "`grep -w "precheck=" $cache | wc -l`" = 0 ]]
        then
            echo 'precheck="n"' >> $cache
        fi
        ;;
    [Yy]|*)
        if [[ -f "$cache" && "`grep -w "precheck=" $cache | wc -l`" = 0 ]]
        then
            echo 'precheck="y"' >> $cache
        fi

        echo -n "Installing Precheck, please wait...                             "
        cp $rootdir/packages/modules/precheck/precheck*.sh $glroot/bin
        cp $rootdir/packages/modules/precheck/precheck.tcl $glroot/sitebot/scripts
        echo "source scripts/precheck.tcl" >> $glroot/sitebot/eggdrop.conf
        touch $glroot/ftp-data/logs/precheck.log
        echo -e "[\e[32mDone\e[0m]"
        ;;
esac
