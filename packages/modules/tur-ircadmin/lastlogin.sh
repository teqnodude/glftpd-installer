#!/bin/bash
VER=1.2
#---------------------------------------------------------------#
# Lastlogin by Teqno                                            #
#                                                               #
# Let's you check what users that been inactive and that are	#
# marked for both deletion and purge based on settings below.	#
#                                                               #
# Add following to glftpd.conf and copy this script to bin 	#
# folder of glftpd						#
#								#
# site_cmd LASTLOGIN      EXEC            /bin/lastlogin.sh	#
# custom-lastlogin        1					#
#								#
# Number of color are taken from irc, press CTRL+K in mIRC 	#
# client to list them   					#
#								#
#--[ Settings ]-------------------------------------------------#

# Path to users dir
USERPATH="/ftp-data/users"
# What users to exclude, case sensitive
EXUSERS="default.user|glftpd"
# What groups to exclude, case sensitive
EXGROUPS="group1|group2"
# How long until users are flagged for deletion
DELETION="1 months ago"
# How long until users are flagged for purge
PURGE="3 months ago"
# Disable colors in announce
skipcolor="no"
# color 4 red
color1=4
# color 9 green
color2=9
 # color code!
color3=

#--[ Script Start ]---------------------------------------------#

if [ ! -f /bin/sort ]
then
    echo "You need to copy sort binary to the bin folder inside glftpd"
    echo "Do the command: cp $(which sort) /glftpd/bin"
    exit 0
fi

if [ ! -f /bin/xargs ]
then
    echo "You need to copy xargs binary to the bin folder inside glftpd"
    echo "Do the command: cp $(which xargs) /glftpd/bin"
    exit 0
fi

if [ ! -d /tmp ]
then
    echo "You need to create folder tmp inside glftpd ie /glftpd/tmp with permission 777"
    echo "Do the command: mkdir -m777 /glftpd/tmp"
    exit 0
fi

cd $USERPATH

if [ "$1" = "" ]
then
    echo "site lastlogin all - to view the last login for all users"
    echo "site lastlogin user username - to view the last login for user"
    echo "site lastlogin inactive -  to view the last login for only users marked for deletion"
    echo "site lastlogin inactive X -  to view the last login for only users marked for deletion longer than X months"
    echo "site lastlogin purge -  to view the last login for only users marked for purge"
    echo "site lastlogin purge X -  to view the last login for only users marked for purge longer than X months"
    echo "site lastlogin notraffic - to view the last login for only users with 0 in upload and download the current month"
fi

if [ "$1" = "all" ]
then
    echo "Listing last login for all users"
    echo
    for user in $(ls -A | egrep -v $EXCLUDES)
    do
        TIME=$(grep -w TIME $user | awk -F " " '{print $3}')
        LL=$(date +"%Y-%m-%d" -d @$TIME)
        FLAGS=$(grep -w FLAGS $user | awk -F " " '{print $2}')
        group=$(cat "$USERPATH/$user" | grep -w GROUP | awk -F " " '{print $2}' | xargs)
        [ ! -z "$EXGROUPS" ] && [ $(echo $group | egrep "$EXGROUPS" | wc -l) -eq 1 ] && continue
        addedby=$(cat "$USERPATH/$user" | grep -w USER | sed 's|^USER ||')
        case $FLAGS in
        *6*)
	    if [ "$skipcolor" = "no" ]
	    then
		deleted=$color2"Deleted$color3"
	    else
		deleted="Deleted"
	    fi
        ;;
        *)
	    if [ "$skipcolor" = "no" ]
	    then
    		deleted=$color1"Not deleted$color3"
	    else
		deleted="Not deleted"
	    fi
        ;;
	esac
        echo "$LL - $user - $deleted - Groups: $group - $addedby" >> /tmp/lastlogin.txt
    done
    cat /tmp/lastlogin.txt | sort -nk1 && rm -f /tmp/lastlogin.txt
fi

if [ "$1" = "user" ]
then
    echo "Listing last login for user $2"
    echo
    for user in $(ls -A | grep $2)
    do
        TIME=$(grep -w TIME $user | awk -F " " '{print $3}')
        LL=$(date +"%Y-%m-%d" -d @$TIME)
        FLAGS=$(grep -w FLAGS $user | awk -F " " '{print $2}')
        group=$(cat "$USERPATH/$user" | grep -w GROUP | awk -F " " '{print $2}' | xargs)
        addedby=$(cat "$USERPATH/$user" | grep -w USER | sed 's|^USER ||')
        case $FLAGS in
        *6*)
            if [ "$skipcolor" = "no" ]
            then
                deleted=$color2"Deleted$color3"
            else
                deleted="Deleted"
            fi
        ;;
        *)
            if [ "$skipcolor" = "no" ]
            then
                deleted=$color1"Not deleted$color3"
            else
                deleted="Not deleted"
            fi
        ;;
	esac
        echo "$LL - $user - $deleted - Groups: $group - $addedby" >> /tmp/lastlogin.txt
    done
    cat /tmp/lastlogin.txt | sort -nk1 && rm -f /tmp/lastlogin.txt
fi

if [ "$1" = "inactive" ]; then
    if [ ! -z "$2" ]
    then
        DELETION="$2 months ago"
        MONTHS="$2"
    else
        MONTHS=$(echo $DELETION | cut -d "=" -f2 | tr -d "\"" | cut -d " " -f1)
    fi

    echo "Listing users that been inactive for longer than $MONTHS months that should be deleted"
    echo
    for i in $(ls -A | egrep -v $EXUSERS)
    do
        TIME=$(grep -w TIME $i | awk -F " " '{print $3}')
        LL=$(date +"%Y-%m-%d" -d @$TIME)
        echo "$i $LL" >> /tmp/lastlogin.txt
    done

    cat /tmp/lastlogin.txt | sort -k5 > /tmp/lastlogin2.txt
    period=$(date +%s --date="$DELETION")
    while IFS= read -r line
    do
	read -r x d <<< "$line"
	if (( $(date +%s --date="${d%<br>}") < $period )); then
	printf '%s\n' "$line"
        fi
    done < /tmp/lastlogin2.txt > /tmp/lastlogin3.txt

    sed -i 's/ /^/g' /tmp/lastlogin3.txt

    for i in $(cat /tmp/lastlogin3.txt)
    do
	user=$(echo "$i" | cut -d "^" -f1)
        logindate=$(echo "$i" | cut -d "^" -f2)
        flags=$(cat "$USERPATH/$user" | grep -w FLAGS | awk -F " " '{print $2}')
    	group=$(cat "$USERPATH/$user" | grep -w GROUP | awk -F " " '{print $2}' | xargs)
        [ ! -z "$EXGROUPS" ] && [ $(echo $group | egrep "$EXGROUPS" | wc -l) -eq 1 ] && continue
    	addedby=$(cat "$USERPATH/$user" | grep -w USER | sed 's|^USER ||')
    	case $flags in
        *6*)
            if [ "$skipcolor" = "no" ]
            then
                deleted=$color2"Deleted$color3"
            else
                deleted="Deleted"
            fi
        ;;
        *)
            if [ "$skipcolor" = "no" ]
            then
                deleted=$color1"Not deleted$color3"
            else
                deleted="Not deleted"
            fi
        ;;
	esac
	echo "$logindate - $user - $deleted - Groups: $group - $addedby" >> /tmp/lastlogin4.txt
    done

    if [ ! -f "/tmp/lastlogin4.txt" ]
    then
	echo "No users marked for deletion"
        rm -f /tmp/lastlogin*
    else
	cat /tmp/lastlogin4.txt | sort -nk1 && rm -f /tmp/lastlogin*
    fi
fi

if [ "$1" = "purge" ]
then
    
    if [ ! -z "$2" ]
    then
        PURGE="$2 months ago"
        MONTHS="$2"
    else
        MONTHS=$(echo $PURGE | cut -d "=" -f2 | tr -d "\"" | cut -d " " -f1)
    fi

    echo "Listing users that been inactive for longer than $MONTHS months that should be purged"
    echo
    for i in $(ls -A | egrep -v $EXUSERS)
    do
        TIME=$(grep -w TIME $i | awk -F " " '{print $3}')
        LL=$(date +"%Y-%m-%d" -d @$TIME)
        echo "$i $LL" >> /tmp/lastlogin.txt
    done

    cat /tmp/lastlogin.txt | sort -k5 > /tmp/lastlogin2.txt
    period=$(date +%s --date="$PURGE")
    while IFS= read -r line
    do
	read -r x d <<< "$line"
        if (( $(date +%s --date="${d%<br>}") < $period ))
        then
    	    printf '%s\n' "$line"
        fi
    done < /tmp/lastlogin2.txt > /tmp/lastlogin3.txt

    sed -i 's/ /^/g' /tmp/lastlogin3.txt

    for i in $(cat /tmp/lastlogin3.txt)
    do
	user=$(echo "$i" | cut -d "^" -f1)
        logindate=$(echo "$i" | cut -d "^" -f2)
	flags=$(cat "$USERPATH/$user" | grep -w FLAGS | awk -F " " '{print $2}')
        group=$(cat "$USERPATH/$user" | grep -w GROUP | awk -F " " '{print $2}' | xargs)
        [ ! -z "$EXGROUPS" ] && [ $(echo $group | egrep "$EXGROUPS" | wc -l) -eq 1 ] && continue
        addedby=$(cat "$USERPATH/$user" | grep -w USER | sed 's|^USER ||')
    	case $flags in
        *6*)
            if [ "$skipcolor" = "no" ]
            then
                deleted=$color2"Deleted$color3"
            else
                deleted="Deleted"
            fi
        ;;
        *)
            if [ "$skipcolor" = "no" ]
            then
                deleted=$color1"Not deleted$color3"
            else
                deleted="Not deleted"
            fi
        ;;
	esac
	echo "$logindate - $user - $deleted - Groups: $group - $addedby" >> /tmp/lastlogin4.txt
    done

    if [ ! -f "/tmp/lastlogin4.txt" ]
    then
	echo "No users marked for purge"
	rm -f /tmp/lastlogin*
    else
        cat /tmp/lastlogin4.txt | sort -nk1 && rm -f /tmp/lastlogin*
    fi
fi

if [ "$1" = "notraffic" ]
then
    echo "Lising users with 0 in upload & download the current month"
    for user in $(ls -A | egrep -v $EXUSERS)
    do
        TIME=$(grep -w TIME $user | awk -F " " '{print $3}')
        LL=$(date +"%Y-%m-%d" -d @$TIME)
        FLAGS=$(grep -w FLAGS $user | awk -F " " '{print $2}')
        group=$(cat "$USERPATH/$user" | grep -w GROUP | awk -F " " '{print $2}' | xargs)
        [ ! -z "$EXGROUPS" ] && [ $(echo $group | egrep "$EXGROUPS" | wc -l) -eq 1 ] && continue
        addedby=$(cat "$USERPATH/$user" | grep -w USER | sed 's|^USER ||')
        monthdn=$(cat "$USERPATH/$user" | grep -w MONTHDN | cut -d " " -f3) 
        #monthdn=$(expr $monthdn / 1024 / 1024)
        monthup=$(cat "$USERPATH/$user" | grep -w MONTHUP | cut -d " " -f3) 
        #monthup=$(expr $monthup / 1024 / 1024)
        case $FLAGS in
        *6*)
            if [ "$skipcolor" = "no" ]
            then
                deleted=$color2"Deleted$color3"
            else
                deleted="Deleted"
            fi
        ;;
        *)
            if [ "$skipcolor" = "no" ]
            then
                deleted=$color1"Not deleted$color3"
            else
                deleted="Not deleted"
            fi
        ;;
        esac
        if [[ "$monthdn" -eq 0 && $monthup -eq 0 ]]
    	then
    	    echo "$LL - $user - $deleted - Groups: $group - $addedby" >> /tmp/lastlogin.txt
    	fi
    done
    cat /tmp/lastlogin.txt | sort -nk1 && rm -f /tmp/lastlogin.txt
fi

exit 0
