if [[ -f "$cache" && "`grep -w "ircadmin" $cache | wc -l`" = 1 ]]
then
    ask=`grep -w "ircadmin" $cache | cut -d "=" -f2 | tr -d "\""`
else
    echo
    echo -e "\e[4mDescription for Tur-Ircadmin:\e[0m"
    cat $rootdir/packages/modules/tur-ircadmin/description
    echo
    echo -n "Install Tur-Ircadmin ? [Y]es [N]o, default Y : " ; read ask
fi

case $ask in
    [Nn])
        if [[ -f "$cache" && "`grep -w "ircadmin=" $cache | wc -l`" = 0 ]]
        then
            echo 'ircadmin="n"' >> $cache
        fi
        ;;
    [Yy]|*)
        if [[ -f "$cache" && "`grep -w "ircadmin=" $cache | wc -l`" = 0 ]]
        then
            echo 'ircadmin="y"' >> $cache
        fi

        echo -n "Installing Tur-Ircadmin, please wait...                         "
        cp $rootdir/packages/modules/tur-ircadmin/tur-ircadmin.sh $glroot/bin
        cp $rootdir/packages/modules/tur-ircadmin/tur-ircadmin.tcl $glroot/sitebot/scripts
        touch $glroot/ftp-data/logs/tur-ircadmin.log
        echo "source scripts/tur-ircadmin.tcl" >> $glroot/sitebot/eggdrop.conf
        sed -i "s/changeme/$channelops/" $glroot/sitebot/scripts/tur-ircadmin.tcl
        sed -i "s/changeme/$port/" $glroot/bin/tur-ircadmin.sh
        cat $rootdir/packages/modules/tur-ircadmin/gl >> $glroot/etc/glftpd.conf
        echo -e "[\e[32mDone\e[0m]"
        ;;
esac
