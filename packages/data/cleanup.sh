#!/bin/bash
rm -rf /glftpd
rm -rf packages/source
rm -rf packages/sitewho
rm -rf packages/sitewho
rm -rf packages/eggdrop-1.8.4
rm -rf packages/glftpd-LNX-*_x86
rm -rf packages/glftpd-LNX-*_x64
rm -rf packages/pzs-ng
rm -f /etc/glftpd.conf
rm -f site.rules
rm -rf /var/spool/mail/sitebot
rm -rf .tmp
killall sitebot > /dev/null 2>&1
sleep 3
userdel sitebot > /dev/null 2>&1
groupdel glftpd > /dev/null 2>&1
sed -i /glftpd/d /etc/services

if [ -f "/etc/inetd.conf" ]
then
	sed -i /glftpd/d /etc/inetd.conf
	killall -HUP inetd
fi

sed -i /glftpd/Id /var/spool/cron/crontabs/root
rm -f /var/spool/cron/crontabs/sitebot

if [ -f "/bin/systemctl" ]
then
	systemctl stop glftpd.socket
	systemctl disable glftpd.socket >/dev/null 2>&1
	rm -f /etc/systemd/system/glftpd*
	systemctl daemon-reload
	systemctl reset-failed
fi

exit 0
