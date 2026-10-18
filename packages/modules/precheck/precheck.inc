show_precheck_desc()
{
	echo
	echo "${yellow}Description for Precheck:${reset}"
	cat "$rootdir/packages/modules/precheck/description"
	echo
}

ask=$(module_ask precheck "Install Precheck ? [Y]es [N]o, default Y : " Y show_precheck_desc)

case $ask in
	[Nn]) ;;
	[Yy]|*)
		print_status_start "Installing" "Precheck"
		cp $rootdir/packages/modules/precheck/precheck*.sh $glroot/bin
		cp $rootdir/packages/modules/precheck/precheck.tcl $glroot/sitebot/scripts
		echo "source scripts/precheck.tcl" >> $glroot/sitebot/eggdrop.conf
		touch $glroot/ftp-data/logs/precheck.log
		print_status_done
		;;
esac
