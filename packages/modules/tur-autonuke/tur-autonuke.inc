show_autonuke_desc()
{
	echo
	echo "${yellow}Description for Tur-Autonuke:${reset}"
	cat "$rootdir/packages/modules/tur-autonuke/description"
	echo
}

ask=$(module_ask autonuke "Install Tur-Autonuke ? [Y]es [N]o, default N : " N show_autonuke_desc)

case $ask in
	[Yy])
		print_status_start "Installing" "Tur-Autonuke"
		mv $rootdir/packages/modules/tur-autonuke/tur-autonuke.conf $glroot/bin
		cp $rootdir/packages/modules/tur-autonuke/tur-autonuke.sh $glroot/bin
		add_cron_job "*/10 * * * *" "$glroot/bin/tur-autonuke.sh"
		touch $glroot/ftp-data/logs/tur-autonuke.log
		print_status_done
		;;
	[Nn]|*) ;;
esac
