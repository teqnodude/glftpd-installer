#!/bin/bash
VER=1.1
#--[ Info ]-----------------------------------------------------
#
# A script by eur0dance to add affils the site (makes an existing group
# on the site to be an affil) via "SITE ADDAFFIL" command.
#
#--[ Settings ]-------------------------------------------------

# Location of your glftpd.conf file, path is CHROOTED to your glftpd dir.
# If your glftpd dir is /glftpd then this will usually be /etc/glftpd.conf
# (a symlink to /glftpd/etc/glftpd.conf).
glftpd_conf="/etc/glftpd.conf"

# Base PRE path. If the second CLI parameter (pre_dir_path) is omitted,
# this is used as the default.
base_pre_path="/site/PRE"

#--[ Script Start ]---------------------------------------------

usage()
{

	cat <<-EOF
		Syntax: SITE ADDAFFIL <group> [pre_dir_path]

		Example:
		SITE ADDAFFIL MYGROUP
		SITE ADDAFFIL MYGROUP /site/CUSTOM/PRE
		SITE ADDAFFIL MYGROUP CUSTOM/PRE
	EOF

}

need_file()
{
    local path=$1

    if [[ ! -e "$path" ]]
    then

        echo "Error: required file not found: $path" >&2
        exit 1

    fi

}

normalize_pre_path()
{
    local p=$1

    # Ensure path starts with /site...
    if [[ $p != /site* ]]
    then

        if [[ $p != /* ]]
        then

            p="/site/$p"

        else

            p="/site$p"

        fi

    fi

    printf '%s\n' "$p"

}

add_affil_to_conf()
{
    local group=$1
    local pre_path=$2

    if grep -E -q "^[[:space:]]*privpath[[:space:]]+${pre_path}\b.*\b${group}\b" "$glftpd_conf"
    then

        echo "The ${pre_path}/${group} line already exists in $glftpd_conf."
        return 0

    fi

    echo "Trying to add ${pre_path}/${group} to $glftpd_conf ..."
    /bin/addaffil "$glftpd_conf" "$group" "$pre_path"

}

update_tur_configs()
{
    local group=$1

    if [[ -e /bin/tur-trial3.conf ]]
    then

        echo "Adding affil to QUOTA_EXCLUDED_GROUPS in /bin/tur-trial3.conf"
        sed -i '/^QUOTA_EXCLUDED_GROUPS=/a '"$group"'' /bin/tur-trial3.conf

    fi

    echo "Adding affil to DENYGROUPS in /bin/tur-predircheck.sh"
    if [[ "$(grep -E '^DENYGROUPS=""' /bin/tur-predircheck.sh | wc -l)" -eq 1 ]]
    then

        sed -i '/^DENYGROUPS=/ s/"$/\/site:[-]('"$group"')$"/' /bin/tur-predircheck.sh

    else

        # Extract the first alt inside the [-](...) group and prepend our group
        local startword
        startword=$(grep -E '^DENYGROUPS' /bin/tur-predircheck.sh \
            | sed -E 's/.*\[-]\(([^|:)]+).*/\1/' \
            | head -n1)
        sed -i "/DENYGROUPS/ s/${startword}/${group}|${startword}/" /bin/tur-predircheck.sh

    fi

    echo "Adding affil to hiddengroups in /bin/sitewho.conf"
    sed -i '/^hiddengroups/a '"$group"'' /bin/sitewho.conf

}

update_pre_cfg()
{
    local group=$1
    local pre_path=$2

    if [[ -e /etc/pre.cfg ]]
    then

        # Pull sections from ngBot.conf, sanitize, and turn into a | list
        local sections
        sections=$(grep -E 'set sections' /sitebot/scripts/pzs-ng/ngBot.conf \
            | cut -d '"' -f2- \
            | tr -d '"' \
            | tr ' ' '|' \
            | sed -E 's/\bREQUEST\b//g; s/\bARCHIVE\b//g; s/\|+$//; s/^\|+//; s/\|\|+/\|/g')

        echo "Adding affil to /etc/pre.cfg"

        if [[ "$(grep -c -E '^#\s*group\.dir' /etc/pre.cfg)" -eq 1 ]]
        then

            sed -i '/^#\s*group\.dir/a group.'"$group"'.dir='"$pre_path"'/'"$group"'' /etc/pre.cfg

        else

            echo "group.$group.dir=$pre_path/$group" >> /etc/pre.cfg

        fi

        if [[ "$(grep -c -E '^#\s*group\.allow' /etc/pre.cfg)" -eq 1 ]]
        then

            sed -i '/^#\s*group\.allow/a group.'"$group"'.allow='"$sections" /etc/pre.cfg

        else

            echo "group.$group.allow=$sections" >> /etc/pre.cfg

        fi

    fi

}

ensure_pre_dir()
{
    local group=$1
    local pre_path=$2

    if [[ -d "$pre_path/$group" ]]
    then

        echo "The dir $pre_path/$group already exists, ensuring permissions are 0777 ..."
        chmod 0777 "$pre_path/$group"
        echo "Couldn't create $pre_path/$group since it already existed. Permissions updated to 0777."
        echo "Group $group can start preing now!!!"
        return 0

    fi

    mkdir -m 0777 -p "$pre_path/$group" >/dev/null 2>&1
    local mkdirres=$?

    if (( mkdirres != 0 ))
    then

        echo "Error! Couldn't create $pre_path/$group."
        echo "Removing the $pre_path/$group dir from $glftpd_conf ..."
        local lines_num
        lines_num=$(wc -l < "$glftpd_conf")
        /bin/delaffil "$glftpd_conf" "$group" "$pre_path" "$lines_num"
        echo "Group $group wasn't set as an affil and it can't pre."
        return 1

    fi

    echo "The $pre_path/$group dir has been created."
    echo "Group $group can start preing now!!!"

}

main()
{

    if (( $# < 1 ))
    then

        usage
        exit 1

    fi

    need_file "$glftpd_conf"

    local group=$1
    local pre_arg=${2:-$base_pre_path}
    local pre_path
    pre_path=$(normalize_pre_path "$pre_arg")

    echo "Adding $group ..."

    add_affil_to_conf "$group" "$pre_path"
    update_tur_configs "$group"
    update_pre_cfg "$group" "$pre_path"
    ensure_pre_dir "$group" "$pre_path"

}

main "$@"
