show_slvprebw_desc()
{
	echo
	echo "${yellow}Description for slv-PreBW:${reset}"
	cat "$rootdir/packages/modules/slv-prebw/description"
	echo
}

ask=$(module_ask slvprebw "Install slv-PreBW ? [Y]es [N]o, default Y : " Y show_slvprebw_desc)

case $ask in
	[Nn]) ;;
	[Yy]|*)
		print_status_start "Installing" "slv-PreBW"
		cp $rootdir/packages/modules/slv-prebw/slv-prebw.sh $glroot/bin
		cp $rootdir/packages/modules/slv-prebw/PreBW.tcl $glroot/sitebot/scripts/pzs-ng/plugins
		echo "source scripts/pzs-ng/plugins/PreBW.tcl" >> $glroot/sitebot/eggdrop.conf
		print_status_done
		;;
esac
