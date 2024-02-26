if [[ -f "$cache" && "`grep -w "addip" $cache | wc -l`" = 1 ]]
then
    ask=`grep -w "addip" $cache | cut -d "=" -f2 | tr -d "\""`
else
    echo
    echo -e "\e[4mDescription for Tur-Addip:\e[0m"
    cat $rootdir/packages/modules/tur-addip/description
    echo
    echo -n "Install Tur-Addip ? [Y]es [N]o, default Y : " ; read ask
fi

case $ask in
    [Nn])
        if [[ -f "$cache" && "`grep -w "addip=" $cache | wc -l`" = 0 ]]
        then
            echo 'addip="n"' >> $cache
        fi
        ;;
    [Yy]|*)
        if [[ -f "$cache" && "`grep -w "addip=" $cache | wc -l`" = 0 ]]
        then
            echo 'addip="y"' >> $cache
        fi

        echo -n "Installing Tur-Addip, please wait...                            "
        cp $rootdir/packages/modules/tur-addip/tur-addip.tcl $glroot/sitebot/scripts
        cp $rootdir/packages/modules/tur-addip/tur-addip.sh $glroot/bin
	[ ! -f $glroot/bin/passchk ] && gcc -o $glroot/bin/passchk $rootdir/packages/modules/tur-addip/passchk.c
        echo "source scripts/tur-addip.tcl" >> $glroot/sitebot/eggdrop.conf
        touch $glroot/ftp-data/logs/tur-addip.log
        sed -i "s/changeme/$port/" $glroot/bin/tur-addip.sh
        sed -i "s/changeme/$channelops/" $glroot/sitebot/scripts/tur-addip.tcl
        echo -e "[\e[32mDone\e[0m]"
        ;;
esac
