if [[ -f "$cache" && "`grep -w "whereami" $cache | wc -l`" = 1 ]]
then
    ask=`grep -w "whereami" $cache | cut -d "=" -f2 | tr -d "\""`
else
    echo
    echo -e "\e[4mDescription for Whereami:\e[0m"
    cat $rootdir/packages/modules/whereami/description
    echo
    echo -n "Install Whereami ? [Y]es [N]o, default Y : " ; read ask
fi

case $ask in
    [Nn])
        if [[ -f "$cache" && "`grep -w "whereami=" $cache | wc -l`" = 0 ]]
        then
            echo 'whereami="n"' >> $cache
        fi
        ;;
    [Yy]|*)
        if [[ -f "$cache" && "`grep -w "whereami=" $cache | wc -l`" = 0 ]]
        then
            echo 'whereami="y"' >> $cache
        fi

        echo -n "Installing Whereami, please wait..." | awk '{printf("%-64s",$0)}'
        cp $rootdir/packages/modules/whereami/whereami.sh $glroot/bin
        cp $rootdir/packages/modules/whereami/whereami.tcl $glroot/sitebot/scripts
        echo "source scripts/whereami.tcl" >> $glroot/sitebot/eggdrop.conf
        echo -e "[\e[32mDone\e[0m]"
esac
