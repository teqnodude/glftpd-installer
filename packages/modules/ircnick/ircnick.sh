#!/bin/bash
VER=1.2
#--[ Script Start ]---------------------------------------------
#                                                               
# Ircnick by Teqno                                              
#                                                               
# Let's you check what ircnick user has on site, only           
# works for sites that require users to invite themselves into  
# channels.                                                     
#                                                               
#--[ Settings ]-------------------------------------------------

glroot=/glftpd
logfile=$glroot/ftp-data/logs/glftpd.log

#--[ Script Start ]---------------------------------------------

trigger=$(grep "bind pub" "$glroot/sitebot/scripts/ircnick.tcl" | awk '{print $4}')

if [[ -z "$1" ]]
then

    echo "Usage: $0 username"

else

    # Find last INVITE line containing the username (case-insensitive)
    last_invite=$(tac "$logfile" | awk -v user="$1" '
        BEGIN { IGNORECASE = 1 }
        /INVITE:/ && tolower($0) ~ tolower(user) { print; exit }
    ')

    if [[ -z "$last_invite" ]]
    then

        # No invite found — get date from line 2 of logfile and convert to YYYY-MM-DD
        raw_date=$(awk 'NR==2 {print $2" "$3" "$5}' "$logfile")
        ts=$(date -d "$raw_date" +%F 2>/dev/null) || \
        ts=$(awk 'NR==2 {
            months["Jan"]="01"; months["Feb"]="02"; months["Mar"]="03"; months["Apr"]="04";
            months["May"]="05"; months["Jun"]="06"; months["Jul"]="07"; months["Aug"]="08";
            months["Sep"]="09"; months["Oct"]="10"; months["Nov"]="11"; months["Dec"]="12";
            mon = substr($2,1,3)
            d = $3 + 0
            y = $5 + 0
            printf "%04d-%s-%02d", y, months[mon], d
        }' "$logfile" )

        echo "User has not been invited into chans since $ts"

    else

        # Print matched invite with ISO date + time and nick/username
        echo "$last_invite" | awk '{
            # fields: $2=MonName, $3=Day, $4=HH:MM:SS, $5=Year, $6=INVITE:, $7="nick", $8="username"
            months["Jan"]="01"; months["Feb"]="02"; months["Mar"]="03"; months["Apr"]="04";
            months["May"]="05"; months["Jun"]="06"; months["Jul"]="07"; months["Aug"]="08";
            months["Sep"]="09"; months["Oct"]="10"; months["Nov"]="11"; months["Dec"]="12";
            mon = substr($2,1,3)
            d = $3 + 0
            y = $5 + 0
            iso = sprintf("%04d-%s-%02d", y, months[mon], d)
            # strip surrounding quotes from nick and username if present
            gsub(/"/, "", $7)
            gsub(/"/, "", $8)
            printf "%s %s ircnick: %s username: %s\n", iso, $4, $7, $8
        }'

    fi

fi
