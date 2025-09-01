#!/bin/bash

red=$(tput setaf 1)
reset=$(tput sgr0)

printf "This will remove everything under ${red}/glftpd${reset} including ${red}/glftpd/site${reset} and undo system changes\n\n"
read -rp "Are you sure? [Y]es [N]o, default N: " cleanup

case $cleanup in

    [Yy])

        rm -rf /glftpd packages/{source,sitewho,eggdrop*,glftpd*,pzs-ng} .tmp \
               /etc/glftpd.conf site.rules /etc/rsyslog.d/glftpd.conf /etc/mysql/mariadb-glftpd.cnf \
               /var/spool/{mail/sitebot,cron/crontabs/sitebot} 2>/dev/null

        { killall sitebot && sleep 3; } 2>/dev/null
        userdel sitebot 2>/dev/null
        groupdel glftpd 2>/dev/null

        rm -f /etc/services.d/glftpd
        sed -i /glftpd/d /etc/services

        [[ -f /etc/inetd.conf ]] && sed -i /glftpd/d /etc/inetd.conf && killall -HUP inetd

        sed -i /glftpd/Id /var/spool/cron/crontabs/root

        [[ -f /etc/systemd/system/glftpd.socket ]] && {
            systemctl disable --now stop glftpd.socket &>/dev/null
            rm -f /etc/systemd/system/glftpd*
            systemctl daemon-reload
            systemctl reset-failed
        }
        
        if [[ -f /etc/systemd/system/mariadb-glftpd.service ]] 
        then
        	
        	systemctl disable --now mariadb-glftpd &>/dev/null
        	rm -f /etc/systemd/system/mariadb-glftpd.service
        	systemctl daemon-reload
        
        fi
		
        [[ -f /usr/sbin/mariadbd ]] && systemctl restart mariadb

        printf '\nCleanup completed\n'
        ;;

    *) printf '\nCleanup aborted\n' ;;

esac
