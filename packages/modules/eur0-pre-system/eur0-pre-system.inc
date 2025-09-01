if has_key "$cache" eur0presystem
then

    ask=$(get_value "$cache" eur0presystem)

else

    echo
    echo "${yellow}Description for Eur0-pre-system + foo-pre:${reset}"
    cat $rootdir/packages/modules/eur0-pre-system/description
    echo
    read -p "Install Eur0-pre-system + foo-pre ? [Y]es [N]o, default Y : " ask

fi

case $ask in

    [Nn])

        if ! has_key "$cache" eur0presystem
        then

            echo 'eur0presystem="n"' >> $cache

        fi
        ;;

    [Yy]|*)

        if ! has_key "$cache" eur0presystem
        then

            echo 'eur0presystem="y"' >> $cache

        fi

		print_status_start "Installing" "Eur0-pre-system + foo-pre"

        cd packages/modules/eur0-pre-system
        make  >/dev/null 2>&1
        make install  >/dev/null 2>&1
        make clean >/dev/null 2>&1
        cp *.sh $glroot/bin
        cp *.tcl $glroot/sitebot/scripts
        echo "source scripts/affils.tcl" >> $glroot/sitebot/eggdrop.conf
        cat gl >> $glroot/etc/glftpd.conf

        if [ -d foo-tools ]
        then

            rm -rf foo-tools >/dev/null 2>&1

        fi

        git clone https://github.com/silv3rr/foo-tools >/dev/null 2>&1
        cp -f $rootdir/packages/core/pre.cfg $glroot/etc
        cd foo-tools
        git checkout cdb77c1 >/dev/null 2>&1
        cd src
        ./configure -q && make build >/dev/null 2>&1
        cp pre/foo-pre $glroot/bin
        make -s distclean

        cd ../../
        sections=$(cat $rootdir/.tmp/.validsections | sed "s/REQUEST//g" | sed "s/ /|/g" | sed "s/|$//g")
        cat $rootdir/.tmp/footools >> $glroot/etc/pre.cfg
        rm -f $rootdir/.tmp/footools
        sed -i '/# group.dir/a group.SiteOP.dir=/site/PRE/SiteOP' $glroot/etc/pre.cfg
        sed -i '/# group.allow/a group.SiteOP.allow='"$sections" $glroot/etc/pre.cfg
        touch $glroot/ftp-data/logs/foo-pre.log
        cd $rootdir

		print_status_done    
        ;;

esac
