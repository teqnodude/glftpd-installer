if [[ -f "$cache" && "`grep -w "top" $cache | wc -l`" = 1 ]]
then
    ask=`grep -w "top" $cache | cut -d "=" -f2 | tr -d "\""`
else
    echo
    echo -e "\e[4mDescription for Top:\e[0m"
    cat $rootdir/packages/modules/top/description
    echo
    echo -n "Install Top ? [Y]es [N]o, default Y : " ; read ask
fi

case $ask in
    [Nn])
        if [[ -f "$cache" && "`grep -w "top=" $cache | wc -l`" = 0 ]]
        then
            echo 'top="n"' >> $cache
        fi
        ;;
    [Yy]|*)
        if [[ -f "$cache" && "`grep -w "top=" $cache | wc -l`" = 0 ]]
        then
            echo 'top="y"' >> $cache
        fi

        echo -n "Installing Top, please wait...                                  "
        cp $rootdir/packages/modules/top/top.tcl $glroot/sitebot/scripts
        cp $rootdir/packages/modules/top/top.sh $glroot/bin
        echo "source scripts/top.tcl" >> $glroot/sitebot/eggdrop.conf
        echo -e "[\e[32mDone\e[0m]"
        ;;
esac
