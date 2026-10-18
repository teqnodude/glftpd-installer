show_top_desc()
{
	echo
	echo "${yellow}Description for Top:${reset}"
	cat "$rootdir/packages/modules/top/description"
	echo
}

ask=$(module_ask top "Install Top ? [Y]es [N]o, default Y : " Y show_top_desc)

case $ask in
	[Nn]) ;;
	[Yy]|*)
		print_status_start "Installing" "Top"
		cp $rootdir/packages/modules/top/top.tcl $glroot/sitebot/scripts
		cp $rootdir/packages/modules/top/top.sh $glroot/bin
		echo "source scripts/top.tcl" >> $glroot/sitebot/eggdrop.conf
		print_status_done
		;;
esac
