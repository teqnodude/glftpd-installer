if has_key "$cache" section_traffic
then

    ask=$(get_value "$cache" section_traffic)

else

    echo
    echo "${yellow}Description for Section-Traffic:${reset}"
    cat $rootdir/packages/modules/section-traffic/description
    echo
    read -p "Install Section-Traffic ? [Y]es [N]o, default Y : " ask

fi

case $ask in

    [Nn])

        if ! has_key "$cache" section_traffic
        then

            echo 'section_traffic="n"' >> $cache

        fi
        ;;

    [Yy]|*)

        if ! has_key "$cache" section_traffic
        then

            echo 'section_traffic="y"' >> $cache

        fi

        print_status_start "Installing" "Section-Traffic"

        if [[ ! -f /usr/sbin/mariadbd ]]
        then

            echo "No MySQL installed, can't install script. Install MySQL and run ./cleanup.sh and this installer again."

        else
	    
	    	if [[ -f /etc/mysql/mariadb-glftpd.cnf ]]
	    	then
		    	# Check and update MySQL config if different
    	        current=$(shasum /etc/mysql/mariadb-glftpd.cnf | cut -d' ' -f1)
        	    new=$(shasum $rootdir/packages/modules/section-traffic/mariadb-glftpd.cnf | cut -d' ' -f1)

           		if [[ "$current" != "$new" ]]
            	then

                	mv /etc/mysql/mariadb-glftpd.cnf /etc/mysql/mariadb-glftpd.cnf.bak
                	cp -f $rootdir/packages/modules/section-traffic/mariadb-glftpd.cnf /etc/mysql

            	fi
            else

            	cp -f $rootdir/packages/modules/section-traffic/mariadb-glftpd.cnf /etc/mysql	

            fi

	    	# Initialize MySQL if backup directory doesn't exist
            if [[ ! -d "$glroot/backup/mysql" ]]
            then

                install -d -m 0750 -o mysql -g mysql "$glroot/backup/mysql"
                mariadb-install-db --user=mysql --datadir="$glroot/backup/mysql" >/dev/null 2>&1
            	
            fi

            [[ ! -f /etc/systemd/system/mariadb-glftpd.service ]] && cp $rootdir/packages/modules/section-traffic/mariadb-glftpd.service /etc/systemd/system/

            systemctl daemon-reload
            systemctl enable --now mariadb-glftpd >/dev/null 2>&1
	    
	    	# Copy and configure scripts
            for script in xferlog-import_3.3.sh section-traffic.sh
	    	do

                if [[ -f "$rootdir/packages/modules/section-traffic/$script" ]]
				then
                
		    		cp "$rootdir/packages/modules/section-traffic/$script" "$glroot/bin/"
                    sed -i "s/changeme/$sitename/; s/SQLPASS=\"\"/SQLPASS=\"$SQLPASSWD\"/" "$glroot/bin/$script"

                fi

            done

            # Configure sitebot
            if [[ -f "$rootdir/packages/modules/section-traffic/section-traffic.tcl" ]]
	    	then

                cp "$rootdir/packages/modules/section-traffic/section-traffic.tcl" "$glroot/sitebot/scripts/"
                echo "source scripts/section-traffic.tcl" >> "$glroot/sitebot/eggdrop.conf"
                sed -i "s/changeme/$channelops/" "$glroot/sitebot/scripts/section-traffic.tcl"

            fi

            # Setup database
            if [[ -f "$rootdir/packages/modules/section-traffic/import.sql" ]]
	    	then

                sed "s/changeme/$sitename/g" "$rootdir/packages/modules/section-traffic/import.sql" | \
                sed "s/SQLPASS=\"\"/SQLPASS=\"$SQLPASSWD\"/" > "$rootdir/packages/modules/section-traffic/import.sql.new"
                
                if [[ -f "$rootdir/packages/modules/section-traffic/setup-section-traffic.sh" ]]
				then

                    cp "$rootdir/packages/modules/section-traffic/setup-section-traffic.sh" \
                       "$rootdir/packages/modules/section-traffic/setup-section-traffic.sh.new"
                    sed -i "s/SQLPASS=\"\"/SQLPASS=\"$SQLPASSWD\"/" \
                       "$rootdir/packages/modules/section-traffic/setup-section-traffic.sh.new"

					# Wait up to 30s for the socket
					if ! timeout 30 bash -c 'until mysqladmin -uroot -S /run/mysqld/mariadb-glftpd.sock ping >/dev/null 2>&1; do sleep 1; done'
					then
						
						echo "mariadb-glftpd failed to become ready" >&2
						journalctl -u mariadb-glftpd -b --no-pager | tail -n 200 >&2
	 				 	exit 1
	 				 	
					fi  
					                  
                    (cd "$rootdir/packages/modules/section-traffic" && \
                     ./setup-section-traffic.sh.new create && \
                     rm -f import.sql.new setup-section-traffic.sh.new)

                fi

            fi

            # Add cron jobs
            add_cron_job "*/30 * * * *" "$glroot/bin/xferlog-import_3.3.sh"
            add_cron_job "30 0 * * *" "$glroot/bin/section-traffic.sh cleanup"

            print_status_done

        fi
        ;;

esac
