#!/bin/bash
VER=1.1
#--[ Info ]-----------------------------------------------------
#
# A script by eur0dance to remove affils from site (makes an existing group
# on the site not to be an affil anymore) via "SITE DELAFFIL" command.
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
		Syntax: SITE DELAFFIL <group> [pre_dir_path]

		Example:
		SITE DELAFFIL MYGROUP
		SITE DELAFFIL MYGROUP /site/CUSTOM/PRE
		SITE DELAFFIL MYGROUP CUSTOM/PRE
	EOF

}

normalize_pre_path()
{
    local p=$1

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

remove_affil_from_conf()
{
    local group=$1
    local pre_path=$2

    echo "Trying to remove $pre_path/$group from $glftpd_conf ..."
    local lines_num
    lines_num=$(wc -l < "$glftpd_conf")
    /bin/delaffil "$glftpd_conf" "$group" "$pre_path" "$lines_num"

}

remove_tur_configs()
{
    local group=$1

    if [[ -e /bin/tur-trial3.conf ]]
    then

        echo "Removing affil from QUOTA_EXCLUDED_GROUPS in /bin/tur-trial3.conf"
        sed -i "/$group/d" /bin/tur-trial3.conf

    fi

    echo "Removing affil from DENYGROUPS in /bin/tur-predircheck.sh"
    if grep -q "^DENYGROUPS" /bin/tur-predircheck.sh | grep -q "$group"
    then

        sed -i "/\/site:/ s/\b$group\b//" /bin/tur-predircheck.sh
        sed -i "/\/site:/ s/|)/)/gI" /bin/tur-predircheck.sh
        sed -i "/\/site:/ s/(|/(/gI" /bin/tur-predircheck.sh
        sed -i "/\/site:/ s/||/|/gI" /bin/tur-predircheck.sh
        sed -i "/\/site:/ s/\/site:\[-]()\\$//" /bin/tur-predircheck.sh

    fi

    echo "Removing affil from hiddengroups in /bin/sitewho.conf"
    sed -i "/$group/d" /bin/sitewho.conf

}

remove_pre_cfg()
{
    local group=$1

    if [[ -e /etc/pre.cfg ]]
    then

        echo "Removing affil from /etc/pre.cfg"
        sed -i "/group.$group.dir/d" /etc/pre.cfg
        sed -i "/group.$group.allow/d" /etc/pre.cfg

    fi

}

remove_pre_dir()
{
    local group=$1
    local pre_path=$2

    if [[ -d "$pre_path/$group" ]]
    then

        rm -rf "$pre_path/$group"
        echo "Success! $pre_path/$group has been removed."
        echo "Group $group is NO LONGER affiled on this site!!!"

    else

        echo "The $group directory doesn't exist, nothing to remove."
        echo "Group $group wasn't fully set or didn't exist, however it got fully removed now!"

    fi

}

main()
{

    if (( $# < 1 ))
    then

        usage
        exit 1

    fi

    local group=$1
    local pre_arg=${2:-$base_pre_path}
    local pre_path
    pre_path=$(normalize_pre_path "$pre_arg")

    echo "Removing $group ..."

    remove_affil_from_conf "$group" "$pre_path"
    remove_tur_configs "$group"
    remove_pre_cfg "$group"
    remove_pre_dir "$group" "$pre_path"

}

main "$@"
