if [[ -f "$cache" && "`grep -w "vacation" $cache | wc -l`" = 1 ]]
then
    ask=`grep -w "vacation" $cache | cut -d "=" -f2 | tr -d "\""`
else
    echo
    echo -e "\e[4mDescription for Tur-Vacation:\e[0m"
    cat $rootdir/packages/modules/tur-vacation/description
    echo
    echo -n "Install Tur-Vacation ? [Y]es [N]o, default Y : " ; read ask
fi

case $ask in
    [Nn])
        if [[ -f "$cache" && "`grep -w "vacation=" $cache | wc -l`" = 0 ]]
        then
            echo 'vacation="n"' >> $cache
        fi
        ;;
    [Yy]|*)
        if [[ -f "$cache" && "`grep -w "vacation=" $cache | wc -l`" = 0 ]]
        then
            echo 'vacation="y"' >> $cache
        fi

        echo -n "Installing Tur-Vacation, please wait..." | awk '{printf("%-64s",$0)}'
        cp $rootdir/packages/modules/tur-vacation/tur-vacation.sh $glroot/bin
        touch $glroot/etc/vacation.index ; chmod 666 $glroot/etc/vacation.index
        touch $glroot/etc/quota_vacation.db ; chmod 666 $glroot/etc/quota_vacation.db
        cat $rootdir/packages/modules/tur-vacation/gl >> $glroot/etc/glftpd.conf
        echo -e "[\e[32mDone\e[0m]"
        ;;
esac
