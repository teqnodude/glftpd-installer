if [[ -f "$cache" && "`grep -w "ircnick" $cache | wc -l`" = 1 ]]
then
    ask=`grep -w "ircnick" $cache | cut -d "=" -f2 | tr -d "\""`
else
    echo
    echo -e "\e[4mDescription for Ircnick:\e[0m"
    cat $rootdir/packages/modules/ircnick/description
    echo
    echo -n "Install Ircnick ? [Y]es [N]o, default Y : " ; read ask
fi

case $ask in
    [Nn])
        if [[ -f "$cache" && "`grep -w "ircnick=" $cache | wc -l`" = 0 ]]
        then
            echo 'ircnick="n"' >> $cache
        fi
        ;;
    [Yy]|*)
        if [[ -f "$cache" && "`grep -w "ircnick=" $cache | wc -l`" = 0 ]]
        then
            echo 'ircnick="y"' >> $cache
        fi

        echo -n "Installing Ircnick, please wait..." | awk '{printf("%-64s",$0)}'
        cp $rootdir/packages/modules/ircnick/*.sh $glroot/bin
        cp $rootdir/packages/modules/ircnick/*.tcl $glroot/sitebot/scripts
        sed -i "s/changeme/$channelops/" $glroot/sitebot/scripts/ircnick.tcl
        echo "source scripts/ircnick.tcl" >> $glroot/sitebot/eggdrop.conf
        echo -e "[\e[32mDone\e[0m]"
        ;;
esac
