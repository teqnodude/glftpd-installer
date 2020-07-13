#!/bin/bash
# A script by eur0dance to add affils the site (makes an existing group
# on the site to be an affil) via "SITE ADDAFFIL" command.
# Version 1.0

### CONFIG ###

# Location of your glftpd.conf file, the path is CHROOTED to your glftpd dir.
# In other words, if your glftpd dir is /glftpd then this path will probably be
# /etc/glftpd.conf, the actual file will be /glftpd/etc/glftpd.conf and there
# will be a symlink /etc/glftpd.conf pointing to /glftpd/etc/glftpd.conf.
glftpd_conf="/etc/glftpd.conf"

# Locations of the base pre path - if the second parameter ('pre_dir_path') won't
# be specified during exection of this script then this path will be used as
# the default pre path.
base_pre_path="/site/PRE"


### CODE ###

if [ $# -ge 1 ]
then

	if [ $# -eq 2 ]
	then
		pre_path=$2
	else
		pre_path=$base_pre_path
	fi

	if [ `expr substr $pre_path 1 5`  != "/site" ]
	then
		if [ `expr substr $pre_path 1 1`  != "/" ]
		then
			pre_path="/site/$pre_path"
		else
			pre_path="/site$pre_path"
		fi
	fi

	echo "Adding $1 ..."

	if [ `grep "privpath $pre_path" $glftpd_conf | grep -c $1` -gt 0 ]
	then
		echo "The $pre_path/$1 line already exists in $glftpd_conf."
	else
		echo "Trying to add $pre_path/$1 to $glftpd_conf ..."
		/bin/addaffil $glftpd_conf $1 $pre_path
        if [ -e /bin/tur-trial3.conf ]
		then
    		echo "Adding affil to QUOTA_EXCLUDED_GROUPS in /glftpd/bin/tur-trial3.conf"
			sed -i '/^QUOTA_EXCLUDED_GROUPS=/a '"$1" /bin/tur-trial3.conf
        fi
        echo "Adding affil to denygroups in /glftpd/bin/tur-predircheck.sh"
        if [ `cat /bin/tur-predircheck.sh | grep DENYGROUPS=\"` = 'DENYGROUPS=""' ]
		then
    		sed -i -r -e "s/DENYGROUPS=\"\"/DENYGROUPS=\"\/site:\\\-$1\\\$\"/" /bin/tur-predircheck.sh
        else
    		sed -i -r -e "s/DENYGROUPS=\"\/site:/DENYGROUPS=\"\/site:\\\-$1\\\$|/" /bin/tur-predircheck.sh
        fi
        echo "Adding affil to hiddengroups in /glftpd/bin/sitewho.conf"
	sed -i '/^hiddengroups/a '"$1" /bin/sitewho.conf
		if [ -e /etc/pre.cfg ]
		then

			if [ `cat /etc/pre.cfg | grep "# group.dir" | wc -l` = 1 ]
			then
					sed -i '/# group.dir/a group.'"$1"'.dir=/site/PRE/'"$1" /etc/pre.cfg
			else
					echo "group.$1.dir=/site/PRE/$1" >> /etc/pre.cfg
			fi

			if [ `cat /etc/pre.cfg | grep "# group.allow" | wc -l` = 1 ]
			then
					sed -i '/# group.allow/a group.'"$1"'.allow=' /etc/pre.cfg
			else
					echo "group.$1.allow=" >> /etc/pre.cfg
			fi

		fi

	fi

	if [ -d "$pre_path/$1" ]
	then
		echo "The dir $pre_path/$1 already exists, making sure it has permissions set to 777 ..."
		chmod 777 "$pre_path/$1"
		echo "Couldn't create $pre_path/$1 dir since it already existed. permissions got updated to 777."
		echo "Group $1 can start preing now!!!"
	else
		mkdir -m777 "$pre_path/$1" >/dev/null 2>&1
		mkdirres=$?
		if [ $mkdirres -ne 0 ]
		then
			echo "Error! Couldn't create $pre_path/$1."
			echo "Removing the $pre_path/$1 dir from $glftpd_conf ..."
			lines_num=`cat $glftpd_conf | wc -l`
			/bin/delaffil $glftpd_conf $1 $pre_path $lines_num
			echo "Group $1 wasn't set as an affil and it can't pre."
		else
			echo "The $pre_path/$1 dir has been created."
			echo "Group $1 can start preing now!!!"
		fi
	fi
	
else

   echo "Syntax: SITE ADDAFFIL <group> [pre_dir_path]"

fi
