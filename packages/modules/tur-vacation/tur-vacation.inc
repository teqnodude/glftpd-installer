show_vacation_desc()
{
	echo
	echo "${yellow}Description for Tur-Vacation:${reset}"
	cat "$rootdir/packages/modules/tur-vacation/description"
	echo
}

ask=$(module_ask vacation "Install Tur-Vacation ? [Y]es [N]o, default Y : " Y show_vacation_desc)

case $ask in
	[Nn]) ;;
	[Yy]|*)
		print_status_start "Installing" "Tur-Vacation"
		cp $rootdir/packages/modules/tur-vacation/tur-vacation.sh $glroot/bin
		touch $glroot/etc/vacation.index ; chmod 666 $glroot/etc/vacation.index
		touch $glroot/etc/quota_vacation.db ; chmod 666 $glroot/etc/quota_vacation.db
		cat $rootdir/packages/modules/tur-vacation/gl >> $glroot/etc/glftpd.conf
		print_status_done
		;;
esac
