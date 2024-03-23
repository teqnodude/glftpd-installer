if [[ -f "$cache" && "`grep -w "slvprebw" $cache | wc -l`" = 1 ]]
then
    ask=`grep -w "slvprebw" $cache | cut -d "=" -f2 | tr -d "\""`
else
    echo
    echo -e "\e[4mDescription for slv-PreBW:\e[0m"
    cat $rootdir/packages/modules/slv-prebw/description
    echo
    echo -n "Install slv-PreBW ? [Y]es [N]o, default Y : " ; read ask
fi

case $ask in
    [Nn])
        if [[ -f "$cache" && "`grep -w "slvprebw=" $cache | wc -l`" = 0 ]]
        then
            echo 'slvprebw="n"' >> $cache
        fi
        ;;
    [Yy]|*)
        if [[ -f "$cache" && "`grep -w "slvprebw=" $cache | wc -l`" = 0 ]]
        then
            echo 'slvprebw="y"' >> $cache
        fi

        echo -n "Installing slv-PreBW, please wait..." | awk '{printf("%-64s",$0)}'
        cp $rootdir/packages/modules/slv-prebw/slv-prebw.sh $glroot/bin
        cp $rootdir/packages/modules/slv-prebw/PreBW.tcl $glroot/sitebot/scripts/pzs-ng/plugins
        echo "source scripts/pzs-ng/plugins/PreBW.tcl" >> $glroot/sitebot/eggdrop.conf
        echo -e "[\e[32mDone\e[0m]"
        ;;
esac
