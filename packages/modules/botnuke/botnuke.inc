show_botnuke_desc()
{
	echo
	echo "${yellow}Description for Botnuke:${reset}"
	cat "$rootdir/packages/modules/botnuke/description"
	echo
}

ask=$(module_ask botnuke "Install Botnuke ? [Y]es [N]o, default Y : " Y show_botnuke_desc)

case $ask in
	[Nn]) ;;
	[Yy]|*)
		print_status_start "Installing" "Botnuke"
		cp $rootdir/packages/modules/botnuke/botnuke.tcl $glroot/sitebot/scripts
		cp $rootdir/packages/modules/botnuke/botnuke.sh $glroot/bin
		echo "source scripts/botnuke.tcl" >> $glroot/sitebot/eggdrop.conf
		print_status_done
		;;
esac
