show_archiver_desc()
{
	echo
	echo "${yellow}Description for Tur-Archiver:${reset}"
	cat "$rootdir/packages/modules/tur-archiver/description"
	echo
}

ask=$(module_ask archiver "Install Tur-Archiver ? [Y]es [N]o, default Y : " Y show_archiver_desc)

case $ask in
	[Nn]) ;;
	[Yy]|*)
		print_status_start "Installing" "Tur-Archiver"
		cp $rootdir/packages/modules/tur-archiver/tur-archiver.sh $glroot/bin
		[[ ! -f $glroot/bin/file_date ]] && gcc -o $glroot/bin/file_date $rootdir/packages/modules/tur-archiver/file_date.c
		add_cron_job "0 0 * * *" "$glroot/bin/tur-archiver.sh"
		print_status_done
		;;
esac
