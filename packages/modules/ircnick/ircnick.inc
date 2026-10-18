show_ircnick_desc()
{
	echo
	echo "${yellow}Description for Ircnick:${reset}"
	cat "$rootdir/packages/modules/ircnick/description"
	echo
}

ask=$(module_ask ircnick "Install Ircnick ? [Y]es [N]o, default Y : " Y show_ircnick_desc)

case $ask in
	[Nn]) ;;
	[Yy]|*)
		print_status_start "Installing" "Ircnick"
		cp $rootdir/packages/modules/ircnick/*.sh $glroot/bin
		cp $rootdir/packages/modules/ircnick/*.tcl $glroot/sitebot/scripts
		sed -i "s/changeme/$channelops/" $glroot/sitebot/scripts/ircnick.tcl
		echo "source scripts/ircnick.tcl" >> $glroot/sitebot/eggdrop.conf
		print_status_done
		;;
esac
