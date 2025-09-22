#!/bin/bash
VER=1.2
#--[ Info ]----------------------------------------------------
#
# Precheck by Teqno                                             
#                                                               
# Adds !precheck cmd to irc, to search for a group's pre's      
# on site. Just copy the precheck.sh in to /glftpd/bin and put  
# the tcl in your sitebot/scripts dir. Then put this line in to 
# your eggdrop.conf                                             
#                                                               
# source scripts/precheck.tcl                                   
#                                                               
# Rehash the bot and your good to go                            
#                                                               
# Do !precheck <GROUPNAME> to check for their pre's             
#                                                               
#--[ Settings ]-------------------------------------------------

glroot=/glftpd
glftpd=$glroot/ftp-data/logs/glftpd.log
precheck=$glroot/ftp-data/logs/precheck.log

#--[ Script Start ]---------------------------------------------

trigger=$(grep "::pub_precheck" $glroot/sitebot/scripts/precheck.tcl | awk '{print $4}')

if [[ -z "$1" ]]
then

    echo "Syntax: $trigger groupname"

else

    if [[ ! -e "$precheck" ]]
    then

	touch $precheck && chmod 666 $precheck

    fi

    if [[ ! -w "$precheck" ]]
    then

    	chmod 666 $precheck

    fi

    grep "PRE:" $glftpd | grep -n -i "\-$1\"" > $precheck

    if [[ -s "$precheck" ]]
    then
    
	# grab "since" date (2nd line of $glftpd)
	since=$(
	awk 'NR==2{ split($0,a,/[ :]+/); print a[2], a[3], a[7]; exit }' "$glftpd"
	)
	
	# read last line of precheck (for counts/date/time/path)
	read total last_date last_time pre <<<"$(
		awk 'END{print $2, $0}' "$precheck" \
		| while read total rest; do
			# rest starts with "Aug 29 2025 12:34:56 ..."
			d=$(echo "$rest" | awk '{print $1,$2,$3,$4}')    # "Aug 29 2025 12:34:56"
			last_date=$(date -d "$d" +%F)                     # YYYY-MM-DD
			last_time=$(date -d "$d" +%T)                     # HH:MM:SS
			pre=$(echo "$rest" | awk '{print $NF}' | sed 's/^\/site\///')
			echo "$total $last_date $last_time $pre"
		done
	)"

	# grab last 5 releases (reverse order, normalize to YYYY-MM-DD HH:MM:SS)
	last5=$(
		tail -5 "$precheck" \
		| tac \
		| awk -F'[ :\t]+' '{
			# Input tokens (by your current split):
			# $3=Mon  $4=Day  $5=HH  $6=MM  $7=SS  $8=Year  $10=Path
			d = $3 " " $4 " " $8 " " $5 ":" $6 ":" $7
	
			# Normalize date/time via GNU date
			cmd = "date -d \"" d "\" +\"%F %T\""
			cmd | getline norm
			close(cmd)
	
			pre = $10
			sub(/^\/site\//, "", pre)
	
			print norm " " pre
		}'
	)
	
	# now print everything in one heredoc
	cat <<-EOF
	    The group $1 have preed a total of $total times since $since
	
	    Last Pre : $last_date
	    Time     : $last_time
	    Pre      : $pre
	
	    Last 5 Releases are :
	    $last5
	EOF
	
	# truncate precheck at the end
	: > "$precheck"
    
    else

		echo "The group $1 have not preed since logfile date $(
			sed -n '2p' "$glftpd" \
			| grep -oE '([0-9]{4}-[0-9]{2}-[0-9]{2}|[A-Z][a-z]{2} [0-9]{1,2} [0-9]{4})' \
			| head -1 \
			| xargs -I{} date -d "{}" +%F
		)"

    fi

fi
