if has_key "$cache" trial
then

    ask=$(get_value "$cache" trial)

else

    echo
    echo "${yellow}Description for Tur-Trial3:${reset}"
    cat $rootdir/packages/modules/tur-trial3/description
    echo
    read -p "Install Tur-Trial3 ? [Y]es [N]o, default Y : " ask

fi

case $ask in

    [Nn])

        if ! has_key "$cache" trial
        then

            echo 'trial="n"' >> $cache

        fi
    ;;

    [Yy]|*)

        if ! has_key "$cache" trial
        then

            echo 'trial="y"' >> $cache

        fi

        print_status_start "Installing" "Tur-Trial3"

        if [[ ! -f /usr/sbin/mariadbd ]]
        then

            echo "No MySQL installed, can't install script. Install MySQL and run ./cleanup.sh and this installer again."

        else

            cp $rootdir/packages/modules/tur-trial3/tur-trial3.sh $glroot/bin
            cp $rootdir/packages/modules/tur-trial3/midnight.sh $glroot/bin
            cp $rootdir/packages/modules/tur-trial3/tur-trial3.conf $glroot/bin
	    	sed -i "s/SQLPASS=\"\"/SQLPASS=\"$SQLPASSWD\"/" $glroot/bin/tur-trial3.conf
            cp $rootdir/packages/modules/tur-trial3/tur-trial3.theme $glroot/bin
            cp $rootdir/packages/modules/tur-trial3/tur-trial3.tcl $glroot/sitebot/scripts
            cp $rootdir/packages/modules/tur-trial3/import.sql $rootdir/packages/modules/tur-trial3/import.sql.new

            if [[ -f /etc/mysql/mariadb-glftpd.cnf ]]
            then

                # Check and update MySQL config if different
                current=$(shasum /etc/mysql/mariadb-glftpd.cnf | cut -d' ' -f1)
                new=$(shasum $rootdir/packages/modules/tur-trial3/mariadb-glftpd.cnf | cut -d' ' -f1)

                if [[ "$current" != "$new" ]]
                then

                    mv /etc/mysql/mariadb-glftpd.cnf /etc/mysql/mariadb-glftpd.cnf.bak
                    cp -f $rootdir/packages/modules/tur-trial3/mariadb-glftpd.cnf /etc/mysql

                fi

            else

                cp -f $rootdir/packages/modules/section-traffic/mariadb-glftpd.cnf /etc/mysql

            fi

	    
	    	if [[ ! -d "$glroot/backup/mysql" ]]
	    	then
	    		
	    		install -d -m 0750 -o mysql -g mysql "$glroot/backup/mysql"
	    		mariadb-install-db --user=mysql --datadir="$glroot/backup/mysql" >/dev/null 2>&1

			fi
			
			[[ ! -f /etc/systemd/system/mariadb-glftpd.service ]] && cp $rootdir/packages/modules/tur-trial3/mariadb-glftpd.service /etc/systemd/system
			
			systemctl daemon-reload
	    	systemctl enable --now mariadb-glftpd >/dev/null 2>&1

			cd $rootdir/packages/modules/tur-trial3
			cp setup-tur-trial3.sh setup-tur-trial3.sh.new
			sed -i "s/SQLPASS=\"\"/SQLPASS=\"$SQLPASSWD\"/" setup-tur-trial3.sh.new


            # Wait up to 30s for the socket
           	if ! timeout 30 bash -c 'until mysqladmin -uroot -S /run/mysqld/mariadb-glftpd.sock ping >/dev/null 2>&1; do sleep 1; done'
            then

            	echo "mariadb-glftpd failed to become ready" >&2
                journalctl -u mariadb-glftpd -b --no-pager | tail -n 200 >&2
                exit 1

            fi
			
			./setup-tur-trial3.sh.new create && rm import.sql.new && rm setup-tur-trial3.sh.new
			cd $rootdir
			echo "source scripts/tur-trial3.tcl" >> $glroot/sitebot/eggdrop.conf
	
			add_cron_job "*/31 * * * *" "$glroot/bin/tur-trial3.sh update"
			add_cron_job "*/30 * * * *" "$glroot/bin/tur-trial3.sh tcron"
			add_cron_job "45 23 * * *" "$glroot/bin/tur-trial3.sh qcron"
			add_cron_job "0 0 * * *" "$glroot/bin/midnight.sh"
	
			crontab -l | sed '/0 0 \* \* \*.*reset -e/ s/^/#/' | crontab -
	
			[[ -f "$(command -v mysql)" ]] && cp $(command -v mysql) $glroot/bin
	
			cat $rootdir/packages/modules/tur-trial3/gl >> $glroot/etc/glftpd.conf
			touch $glroot/ftp-data/logs/tur-trial3.log
			
			print_status_done
    
        fi
        
    ;;

esac
