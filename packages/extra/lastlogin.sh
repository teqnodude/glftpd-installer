#!/bin/bash
VER=1.3
#--[ Info ]-----------------------------------------------------
#
# Lastlogin by Teqno
#
# Let's you check what users that have been inactive and that are
# marked for both deletion and purge based on the settings below.
#
# Add the following to glftpd.conf and copy this script to bin
# folder of glftpd.
#
# site_cmd LASTLOGIN      EXEC            /bin/lastlogin.sh
# custom-lastlogin        1
#
# Number of color is taken from irc, press CTRL+K in mIRC
# client to list them.
#
#--[ Settings ]-------------------------------------------------

# Path to glftpd
glroot="/glftpd"

# Path to users dir
userpath="/ftp-data/users"

# What users to exclude, case sensitive
exclude_users="default.user|glftpd"

# What groups to exclude, case sensitive
exclude_groups=""

# How long until users are flagged for deletion
deletion="3 months ago"

# How long until users are flagged for purge
purge="6 months ago"

# Disable colors in announce on IRC
skipcolor="no"

# red
color1="4"

# green
color2="9"

# reset
color3=""

#--[ Script Start ]---------------------------------------------

if [[ ! -x $(command -v sort) ]]
then

    echo "You need to copy sort binary to the bin folder inside glftpd"
    echo "Do the command: cp \$(which sort) $glroot/bin"
    exit 1

fi

if [[ ! -x $(command -v xargs) ]]
then

    echo "You need to copy xargs binary to the bin folder inside glftpd"
    echo "Do the command: cp \$(which xargs) $glroot/bin"
    exit 1

fi

if [[ ! -d "/tmp" ]]
then

    echo "You need to create folder tmp inside glftpd ie $glroot/tmp with permission 777"
    echo "Do the command: mkdir -m777 $glroot/tmp"
    exit 1

fi

if [[ -n $userpath ]]
then

    cd "$userpath" || exit 1

fi

if [[ -z $1 ]]
then

	cat <<-EOF
	site lastlogin all        - to view the last login for all users
	site lastlogin user X     - to view the last login for user X
	site lastlogin inactive   - to view the last login for only users marked for deletion
	site lastlogin inactive N - to view users marked for deletion longer than N months
	site lastlogin purge      - to view the last login for only users marked for purge
	site lastlogin purge N    - to view users marked for purge longer than N months
	site lastlogin notraffic  - to view the last login for users with 0 upload/download this month
	EOF

fi


if [[ "$1" = "all" ]]
then

    echo "Listing last login for all users"
    echo

    outfile="$tmp/lastlogin.txt"
    : > "$outfile"

    cd "$userpath" || exit 1

    for user in *
    do

        [[ -f $user ]] || continue

        if [[ -n $exclude_users ]]
        then

            echo "$user" | grep -Eq -- "$exclude_users" && continue

        fi

        time=$(awk '/^TIME[[:space:]]/{print $3; exit}' "$userpath/$user")
        [[ -n $time ]] || time=0

        ll=$(date +"%Y-%m-%d" -d "@$time")

        flags=$(awk '/^FLAGS[[:space:]]/{print $2; exit}' "$userpath/$user")
        group=$(awk '/^GROUP[[:space:]]/{print $2}' "$userpath/$user" | xargs)
        addedby=$(sed -n 's/^USER[[:space:]]\+//p' "$userpath/$user" | xargs)

        if [[ -n $exclude_groups ]]
        then

            echo "$group" | grep -Eq -- "$exclude_groups" && continue

        fi

        case "$flags" in
        *6*)

            if [[ "$skipcolor" = "no" ]]
            then

                deleted="${color2}deleted${color3}"

            else

                deleted="deleted"

            fi
            ;;

        *)

            if [[ "$skipcolor" = "no" ]]
            then

                deleted="${color1}not deleted${color3}"

            else

                deleted="not deleted"

            fi
            ;;

        esac

        echo "$ll - $user - $deleted - groups: $group - $addedby" >> "$outfile"

    done

    LC_ALL=C sort -k1,1 "$outfile"
    rm -f "$outfile"

fi

if [[ "$1" = "user" ]]
then

    echo "Listing last login for user $2"
    echo

    outfile="$tmp/lastlogin.txt"
    : > "$outfile"

    cd "$userpath" || exit 1

    for user in *
    do

        [[ -f $user ]] || continue
        [[ $user == *"$2"* ]] || continue

        time=$(awk '/^TIME[[:space:]]/{print $3; exit}' "$userpath/$user")
        [[ -n $time ]] || time=0

        ll=$(date +"%Y-%m-%d" -d "@$time")

        flags=$(awk '/^FLAGS[[:space:]]/{print $2; exit}' "$userpath/$user")
        group=$(awk '/^GROUP[[:space:]]/{print $2}' "$userpath/$user" | xargs)
        addedby=$(sed -n 's/^USER[[:space:]]\+//p' "$userpath/$user" | xargs)

        case "$flags" in
        *6*)

            if [[ "$skipcolor" = "no" ]]
            then

                deleted="${color2}deleted${color3}"

            else

                deleted="deleted"

            fi
            ;;

        *)

            if [[ "$skipcolor" = "no" ]]
            then

                deleted="${color1}not deleted${color3}"

            else

                deleted="not deleted"

            fi
            ;;

        esac

        echo "$ll - $user - $deleted - groups: $group - $addedby" >> "$outfile"

    done

    LC_ALL=C sort -k1,1 "$outfile"
    rm -f "$outfile"

fi

if [[ "$1" = "inactive" ]]
then

    if [[ -n $2 ]]
    then

        deletion="${2} months ago"
        months="$2"

    else

        months=$(echo "$deletion" | awk '{print $1}')

    fi

    echo "Listing users that been inactive for longer than $months months that should be deleted"
    echo

    tmp1="$tmp/lastlogin.txt"
    tmp2="$tmp/lastlogin2.txt"
    tmp3="$tmp/lastlogin3.txt"
    tmp4="$tmp/lastlogin4.txt"

    : > "$tmp1"
    : > "$tmp2"
    : > "$tmp3"
    : > "$tmp4"

    cd "$userpath" || exit 1

    for user in *
    do

        [[ -f $user ]] || continue

        if [[ -n $exclude_users ]]
        then

            echo "$user" | grep -E -q -- "$exclude_users" && continue

        fi

        time=$(awk '/^TIME[[:space:]]/{print $3; exit}' "$userpath/$user")
        [[ -n $time ]] || time=0

        ll=$(date +"%Y-%m-%d" -d "@$time")
        echo "$user $ll" >> "$tmp1"

    done

    LC_ALL=C sort -k2,2 "$tmp1" > "$tmp2"

    period=$(date +%s --date="$deletion")

    while IFS= read -r line
    do

        user=$(echo "$line" | awk '{print $1}')
        d=$(echo "$line" | awk '{print $2}')

        if (( $(date +%s --date="$d") < period ))
        then

            printf '%s %s\n' "$user" "$d" >> "$tmp3"

        fi

    done < "$tmp2"

    while IFS= read -r line
    do

        user=$(echo "$line" | awk '{print $1}')
        logindate=$(echo "$line" | awk '{print $2}')

        flags=$(awk '/^FLAGS[[:space:]]/{print $2; exit}' "$userpath/$user")
        group=$(awk '/^GROUP[[:space:]]/{print $2}' "$userpath/$user" | xargs)
        addedby=$(sed -n 's/^USER[[:space:]]\+//p' "$userpath/$user" | xargs)

        if [[ -n $exclude_groups ]]
        then

            echo "$group" | grep -E -q -- "$exclude_groups" && continue

        fi

        case "$flags" in
        *6*)

            if [[ "$skipcolor" = "no" ]]
            then

                deleted="${color2}deleted${color3}"

            else

                deleted="deleted"

            fi
            ;;

        *)

            if [[ "$skipcolor" = "no" ]]
            then

                deleted="${color1}not deleted${color3}"

            else

                deleted="not deleted"

            fi
            ;;

        esac

        echo "$logindate - $user - $deleted - groups: $group - $addedby" >> "$tmp4"

    done < "$tmp3"

    if [[ ! -s "$tmp4" ]]
    then

        echo "No users marked for deletion"
        rm -f "$tmp1" "$tmp2" "$tmp3" "$tmp4"

    else

        LC_ALL=C sort -k1,1 "$tmp4"
        rm -f "$tmp1" "$tmp2" "$tmp3" "$tmp4"

    fi

fi

if [[ "$1" = "purge" ]]
then

    if [[ -n $2 ]]
    then

        purge="${2} months ago"
        months="$2"

    else

        months=$(echo "$purge" | awk '{print $1}')

    fi

    echo "Listing users that been inactive for longer than $months months that should be purged"
    echo

    tmp1="$tmp/lastlogin.txt"
    tmp2="$tmp/lastlogin2.txt"
    tmp3="$tmp/lastlogin3.txt"
    tmp4="$tmp/lastlogin4.txt"

    : > "$tmp1"
    : > "$tmp2"
    : > "$tmp3"
    : > "$tmp4"

    cd "$userpath" || exit 1

    for user in *
    do

        [[ -f $user ]] || continue

        if [[ -n $exclude_users ]]
        then

            echo "$user" | grep -E -q -- "$exclude_users" && continue

        fi

        time=$(awk '/^TIME[[:space:]]/{print $3; exit}' "$userpath/$user")
        [[ -n $time ]] || time=0

        ll=$(date +"%Y-%m-%d" -d "@$time")
        echo "$user $ll" >> "$tmp1"

    done

    LC_ALL=C sort -k2,2 "$tmp1" > "$tmp2"

    period=$(date +%s --date="$purge")

    while IFS= read -r line
    do

        user=$(echo "$line" | awk '{print $1}')
        d=$(echo "$line" | awk '{print $2}')

        if (( $(date +%s --date="$d") < period ))
        then

            printf '%s %s\n' "$user" "$d" >> "$tmp3"

        fi

    done < "$tmp2"

    while IFS= read -r line
    do

        user=$(echo "$line" | awk '{print $1}')
        logindate=$(echo "$line" | awk '{print $2}')

        flags=$(awk '/^FLAGS[[:space:]]/{print $2; exit}' "$userpath/$user")
        group=$(awk '/^GROUP[[:space:]]/{print $2}' "$userpath/$user" | xargs)
        addedby=$(sed -n 's/^USER[[:space:]]\+//p' "$userpath/$user" | xargs)

        if [[ -n $exclude_groups ]]
        then

            echo "$group" | grep -E -q -- "$exclude_groups" && continue

        fi

        case "$flags" in
        *6*)

            if [[ "$skipcolor" = "no" ]]
            then

                deleted="${color2}deleted${color3}"

            else

                deleted="deleted"

            fi
            ;;

        *)

            if [[ "$skipcolor" = "no" ]]
            then

                deleted="${color1}not deleted${color3}"

            else

                deleted="not deleted"

            fi
            ;;

        esac

        echo "$logindate - $user - $deleted - groups: $group - $addedby" >> "$tmp4"

    done < "$tmp3"

    if [[ ! -s "$tmp4" ]]
    then

        echo "No users marked for purge"
        rm -f "$tmp1" "$tmp2" "$tmp3" "$tmp4"

    else

        LC_ALL=C sort -k1,1 "$tmp4"
        rm -f "$tmp1" "$tmp2" "$tmp3" "$tmp4"

    fi

fi

if [[ "$1" = "notraffic" ]]
then

    echo "Listing users with 0 in upload & download the current month"
    echo

    outfile="$tmp/lastlogin.txt"
    : > "$outfile"

    cd "$userpath" || exit 1

    for user in *
    do

        [[ -f $user ]] || continue

        if [[ -n $exclude_users ]]
        then

            echo "$user" | grep -E -q -- "$exclude_users" && continue

        fi

        time=$(awk '/^TIME[[:space:]]/{print $3; exit}' "$userpath/$user")
        [[ -n $time ]] || time=0

        ll=$(date +"%Y-%m-%d" -d "@$time")

        flags=$(awk '/^FLAGS[[:space:]]/{print $2; exit}' "$userpath/$user")
        group=$(awk '/^GROUP[[:space:]]/{print $2}' "$userpath/$user" | xargs)
        addedby=$(sed -n 's/^USER[[:space:]]\+//p' "$userpath/$user" | xargs)

        if [[ -n $exclude_groups ]]
        then

            echo "$group" | grep -E -q -- "$exclude_groups" && continue

        fi

        monthdn=$(awk '/^MONTHDN[[:space:]]/{print $3; exit}' "$userpath/$user")
        monthup=$(awk '/^MONTHUP[[:space:]]/{print $3; exit}' "$userpath/$user")
        [[ -n $monthdn ]] || monthdn=0
        [[ -n $monthup ]] || monthup=0

        case "$flags" in
        *6*)

            if [[ "$skipcolor" = "no" ]]
            then

                deleted="${color2}deleted${color3}"

            else

                deleted="deleted"

            fi
            ;;

        *)

            if [[ "$skipcolor" = "no" ]]
            then

                deleted="${color1}not deleted${color3}"

            else

                deleted="not deleted"

            fi
            ;;

        esac

        if [[ $monthdn -eq 0 && $monthup -eq 0 ]]
        then

            echo "$ll - $user - $deleted - groups: $group - $addedby" >> "$outfile"

        fi

    done

    if [[ -s "$outfile" ]]
    then

        LC_ALL=C sort -k1,1 "$outfile"

    else

        echo "No users with zero traffic this month"

    fi

    rm -f "$outfile"

fi
