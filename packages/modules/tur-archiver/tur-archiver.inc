if [[ -f "$cache" && "`grep -w "archiver" $cache | wc -l`" = 1 ]]
then
    ask=`grep -w "archiver" $cache | cut -d "=" -f2 | tr -d "\""`
else
    echo
    echo -e "\e[4mDescription for Tur-Archiver:\e[0m"
    cat $rootdir/packages/modules/tur-archiver/description
    echo
    echo -n "Install Tur-Archiver ? [Y]es [N]o, default Y : " ; read ask
fi

case $ask in
    [Nn])
        if [[ -f "$cache" && "`grep -w "archiver=" $cache | wc -l`" = 0 ]]
        then
            echo 'archiver="n"' >> $cache
        fi
        ;;
    [Yy]|*)
        if [[ -f "$cache" && "`grep -w "archiver=" $cache | wc -l`" = 0 ]]
        then
            echo 'archiver="y"' >> $cache
        fi

        echo -n "Installing Tur-Archiver, please wait...                         "
        cp $rootdir/packages/modules/tur-archiver/tur-archiver.sh $glroot/bin
        [ ! -f $glroot/bin/file_date ] && gcc -o $glroot/bin/file_date $rootdir/packages/modules/tur-archiver/file_date.c
        echo "0 0 * * *               $glroot/bin/tur-archiver.sh >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
        echo -e "[\e[32mDone\e[0m]"
        ;;
esac
