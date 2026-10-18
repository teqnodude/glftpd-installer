#!/bin/bash
VER=12.11

# Set debug mode (0=off, 1=on)
DEBUG=0

# Enable debug logging if DEBUG=1
if (( DEBUG == 1 ))
then

    # Create log file with timestamp
    LOG_FILE="debug_$(date +%Y%m%d_%H%M%S).log"
    echo "Debug logging enabled: $LOG_FILE"

    # Redirect all output to both terminal and log file
    exec > >(tee -a "$LOG_FILE") 2>&1
    set -x
    
fi

if [[ $USER != "root" ]]
then 

    echo "The installer should be run as root"
    exit 1

fi

glroot="/glftpd"

# styling
cron_width="23"
banner_width="90"
pzs_width="40"

red="$(tput setaf 1)"
green="$(tput setaf 2)"
yellow="$(tput setaf 3)"
reset="$(tput sgr0)"
underline_start=$(tput smul)
underline_end=$(tput rmul)

# adding cron jobs
add_cron_job() 
{

    local schedule="$1"
    local command="$2"
    local account="${3:-root}"
    printf "%-${cron_width}s %s >/dev/null 2>&1\n" "$schedule" "$command" >> "/var/spool/cron/crontabs/$account"

}

# generate Installing: lines, width set by banner_width at the top
print_status_start() 
{

    local prefix="$1"
    local text="$2"
    local status_text="please wait"
    local total_width=$banner_width
    local done_length=6  # Length of "[DONE]" with colors

    # Calculate the full text including prefix
    local full_text="${prefix}: ${text} "
    local full_text_length=${#full_text}
    local status_length=${#status_text}

    # Calculate dots needed
    local dots_needed=$((total_width - full_text_length - status_length - done_length -2))

    # Generate dots
    local dots=""
    if [ $dots_needed -gt 0 ]; then
        dots=$(printf '%*s' $dots_needed | tr ' ' '.')
    fi

    printf "%s%s %s " "$full_text" "$dots" "$status_text"

}

# generate --[ ]---- lines, width set by banner_width at the top
print_banner() 
{

    local text="$1"
    local prefix="--------[ "
    local suffix=" ]"
    local prefix_length=${#prefix}
    local suffix_length=${#suffix}

    # Calculate available space for dashes
    local text_length=${#text}
    local dash_length=$((banner_width - prefix_length - text_length - suffix_length))

    # Generate dashes
    local dashes=""
    if [ $dash_length -gt 0 ]; then
        dashes=$(printf '%*s' $dash_length | tr ' ' '-')
    else
        # If text is too long, truncate it
        local max_text_length=$((banner_width - prefix_length - suffix_length))
        text="${text:0:$max_text_length}"
        dashes=""
    fi

    echo "${prefix}${text}${suffix}${dashes}"

}

# Complete a status with success
print_status_done() 
{

    echo "[${green}DONE${reset}]"

}

# Complete a status with error  
print_status_error() 
{

    echo "[${red}Error${reset}]"

}

# Complete a status with warning
print_status_warning() 
{

    echo "[${yellow}Warning${reset}]"

}

# --- cache helpers (standardized) ---
has_key()
{
	local file=$1 key=$2
	[[ -f "$1" ]] && grep -Eq "^${key}=" "$file"
}

get_value()
{
	local file=$1 key=$2
	grep -E "^${key}=" "$file" | cut -d '=' -f2- | tr -d '"'
}

## Cached prompt helper: return cached value, else prompt, normalise, store
ask_cached()
{
	local key=$1 prompt=$2 default=${3:-} yn=${4:-} preamble=${5:-} val
	if has_key "$cache" "$key"
	then
		get_value "$cache" "$key"
		return
	fi
	[[ -n $preamble ]] && "$preamble" >&2
	read -rp "$prompt" val
	[[ -z $val ]] && val=$default
	if [[ "$yn" = "y" ]]
	then
		[[ "${val,,}" = "y" ]] && val="y" || val="n"
	fi
	printf '%s="%s"\n' "$key" "$val" >> "$cache"
	printf '%s' "$val"
}

## Module install ask: y/n cached, description printed only on first ask
module_ask()
{
	local key=$1 prompt=$2 default=$3 desc_func=$4
	ask_cached "$key" "$prompt" "$default" y "$desc_func"
}
# --- end helpers ---

if [[ -d "$glroot" ]]
then

    read -p "The path you have chosen already exists, what would you like to do [D]elete it, [A]bort, [T]ry again, [I]gnore? " reply

    case $reply in

	[dD]*) rm -rf "$glroot" ;;
	[tT]*) glroot="./"; continue ;;
	[iI]*) ;;
	*) echo "Aborting."; exit 1 ;;

    esac
fi

mkdir -p "$glroot"
[[ ! -d ".tmp" ]] && mkdir .tmp
clear

echo "Welcome to the glFTPd installer v$VER"

cat << EOF

Disclaimer: ${red}This software is used at your own risk!${reset}

The author of this installer takes no responsibility for any damage done to your system.

EOF

read -p "Have you read and installed the Requirements in README.MD ? [Y]es [N]o, default N : " readme
echo

case $readme in

    [Yy]) ;;
    [Nn]) rm -r /glftpd && rm -r .tmp ; exit 1 ;;
    *) rm -r /glftpd && rm -r .tmp ; exit 1 ;;

esac

requirements() 
{

	print_status_start "Ensuring that all required system packages are installed"
	
    # Check if this is a Debian-based system (Debian, Ubuntu, etc.)
    if [[ ! -f /etc/debian_version ]] && ! grep -q "Ubuntu\|Debian" /etc/os-release 2>/dev/null
    then

        echo "Error: This is not a Debian-based system. Aborting."
        echo "This script is designed for Debian/Ubuntu systems only."
        exit 1

    fi

    local packages=(
        cron cmake gcc systemd autoconf bc curl diffutils ftp gawk git libflac-dev
        iputils-ping libssl-dev lm-sensors lynx make mariadb-server ncftp passwd
        rsync smartmontools tcl tcl-dev tcllib tcl-tls tcpd wget zip
        bsdmainutils rsyslog
    )

    for pkg in "${packages[@]}"
    do
        
        if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"
        then
        
            continue
        
        else
        
            if ! apt-get install -y "$pkg" >/dev/null 2>&1
            then
            
                echo "Error: Failed to install $pkg. Aborting."
                exit 1
                
            fi
        
        fi
        
    done
    
    print_status_done

}


if [[ "$(echo $PATH | grep -c /usr/sbin)" = 0 ]]
then 

    echo "/usr/sbin not found in environmental PATH" 
    echo "Default PATH should be : /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    echo "Current PATH is : $(echo $PATH)"
    echo "Correcting PATH"
    export PATH=$PATH:/usr/sbin
    echo "Done"
    echo

fi

rootdir=$(pwd)
cache="$rootdir/install.cache"

# Clean up comments and trailing spaces in install.cache to avoid problems with unattended installation
if [[ -f "$cache" ]]
then

    sed -i -e 's/" #.*/"/g' -e 's/^#.*//g' -e '/^\s*$/d' -e 's/[ \t]*$//' $cache

fi

# Global variables for section management
pzsbot="$glroot/sitebot/scripts/pzs-ng/ngBot.conf"
pzsng="$glroot/backup/pzs-ng"
incoming="/glftpd/site" 

# Optional configuration files
turautonuke="$glroot/bin/tur-autonuke.conf"
turspace="$glroot/bin/tur-space.conf"
approve="$glroot/bin/approve.sh"
foopre="$glroot/etc/pre.cfg"
turlastul="$glroot/bin/tur-lastul.sh"
psxcimdb="$glroot/etc/psxc-imdb.conf"
dated="$glroot/bin/dated.sh"

# Variables for section workflow
declare -A section_details
deferred_operations_file="$rootdir/.tmp/deferred_sections.sh"

#=============================================================================
# SECTION MANAGEMENT FUNCTIONS
#=============================================================================

## Create section directory with appropriate permissions
create_section_directory()
{
	local section_name=$1
	mkdir -pm 777 "$rootdir/.tmp/site/$section_name"
	[[ -d "$glroot" ]] && mkdir -pm 777 "$glroot/site/$section_name"
}

## Write per-section paths/chanlist lines to the temp bot files
create_temporary_bot_config()
{
	local section_name=$1 section_dated=$2 target_path target_chan
	if [[ "${section_dated,,}" = "y" ]]
	then
		target_path="/site/${section_name}/*/*"
		target_chan="$channelspam"
	else
		target_path="/site/${section_name}/*"
		target_chan="$channelmain"
	fi
	printf "%-${pzs_width}s\"%s\"\n" "set paths($section_name)"    "$target_path" >> "$rootdir/.tmp/dzsrace"
	printf "%-${pzs_width}s\"%s\"\n" "set chanlist($section_name)" "$target_chan" >> "$rootdir/.tmp/dzschan"
	printf "%s " "$section_name" >> "$rootdir/.tmp/.sections"
	awk -F '[" "]+' '{printf $0}' "$rootdir/.tmp/.sections" > "$rootdir/.tmp/.validsections"
}

## Update tur-autonuke
update_tur_autonuke_config()
{
	local section_name=$1 section_dated=$2
	if [[ "${section_dated,,}" = "y" ]]
	then
		sed -i "s/\bDIRS=\"/DIRS=\"\n\/site\/$section_name\/\$today/" packages/modules/tur-autonuke/tur-autonuke.conf
		sed -i "s/\bDIRS=\"/DIRS=\"\n\/site\/$section_name\/\$yesterday/" packages/modules/tur-autonuke/tur-autonuke.conf
		[[ -f "$turautonuke" ]] && sed -i '/^DIRS/a '"/site/$section_name/\$today" "$turautonuke" && sed -i '/^DIRS/a '"/site/$section_name/\$yesterday" "$turautonuke"
	else
		sed -i "s/\bDIRS=\"/DIRS=\"\n\/site\/$section_name/" packages/modules/tur-autonuke/tur-autonuke.conf
		[[ -f "$turautonuke" ]] && sed -i '/^DIRS/a '"/site/$section_name" "$turautonuke"
	fi
}

## Update tur-space
update_tur_space_config()
{
	local section_name=$1
	printf "INC%s=%s:%s/site/%s:\n" "$section_name" "$device" "$glroot" "$section_name" >> packages/scripts/tur-space/tur-space.conf.new
	[[ -f "$turspace" ]] && sed -i '/^\[INCOMING\]/a '"INC$section_name=$incoming:$glroot/site/$section_name:" "$turspace"
}

## Update foo-pre
update_foo_pre_config()
{
	local section_name=$1 section_dated=$2 dir_suffix=""
	[[ "${section_dated,,}" = "y" ]] && dir_suffix="/YYYY-MM-DD"
	update_foo_pre_file()
	{
		local f=$1
		printf "section.%s.name=%s\n"             "$section_name" "$section_name" >> "$f"
		printf "section.%s.dir=/site/%s%s\n"      "$section_name" "$section_name" "$dir_suffix" >> "$f"
		printf "section.%s.gl_credit_section=0\n" "$section_name" >> "$f"
		printf "section.%s.gl_stat_section=0\n"   "$section_name" >> "$f"
	}
	update_foo_pre_file "$rootdir/.tmp/footools"
	if [[ -f "$foopre" ]]
	then
		sed -i "s/.allow=/.allow=$section_name\|/" "$foopre"
		update_foo_pre_file "$foopre"
		sed -i -e "/allow=/s/=|/=/" -e "/allow=/s/||/|/" -e "/allow=/s/|\$//" "$foopre"
	fi
}

## Update approve script
update_approve_script()
{
	local section_name=$1 sections_count daysections_count
	if [[ ${section_name^^} != @(0DAY|MP3|FLAC|EBOOK) ]]
	then
		sed -i '/^SECTIONS="/a '"$section_name" "$approve"
	else
		sed -i '/^DAYSECTIONS="/a '"$section_name" "$approve"
	fi
	sections_count=$(sed -n '/^SECTIONS="/,/"/p' "$approve" | grep -cEv "(DAYSECTIONS|NUMDAYFOLDERS|SECTIONS|\")")
	daysections_count=$(sed -n '/^DAYSECTIONS="/,/"/p' "$approve" | grep -cEv "(DAYSECTIONS|NUMDAYFOLDERS|SECTIONS|\")")
	sed -i -e "s/^NUMFOLDERS=\".*\"/NUMFOLDERS=\"$sections_count\"/" -e "s/^NUMDAYFOLDERS=\".*\"/NUMDAYFOLDERS=\"$daysections_count\"/" "$approve"
}

## Update tur-lastul script
update_tur_lastul_script()
{
	local section_name=$1
	sed -i "/^sections=\"/ { /$section_name/! { s/\"\$/ $section_name\"/; s/  \+/ /g; s/\" /\"/g; s/ \"/\"/g } }" "$turlastul"
}

## Update PSXC-IMDB for movie sections
update_psxc_imdb_config()
{
	local section_name=$1
	sed -i "s/^SCANDIRS=\"/SCANDIRS=\"\/site\/$section_name /" "$psxcimdb"
	sed -i -e '/^SCANDIRS=/s/  / /g' -e '/^SCANDIRS=/s/" /"/g' -e '/^SCANDIRS=/s/ "/"/g' "$psxcimdb"
}

## Update dated script for dated sections
update_dated_script()
{
	sed -i '/^sections="/a '"$1" "$dated"
}

## Update auxiliary scripts for a section
update_auxiliary_scripts()
{
	local section_index=$1
	local section_name="${section_details[${section_index}_name]}"
	local section_dated="${section_details[${section_index}_dated]}"
	local section_movie="${section_details[${section_index}_movie]}"
	update_tur_autonuke_config "$section_name" "$section_dated"
	update_tur_space_config "$section_name"
	update_foo_pre_config "$section_name" "$section_dated"
	[[ -f "$approve" ]] && update_approve_script "$section_name"
	[[ -f "$turlastul" ]] && update_tur_lastul_script "$section_name"
	[[ "${section_movie,,}" = "y" && -f "$psxcimdb" ]] && update_psxc_imdb_config "$section_name"
	[[ "${section_dated,,}" = "y" && -f "$dated" ]] && update_dated_script "$section_name"
}

## Finalize section creation
finalize_section_creation()
{
	local section_index=$1
	local section_name="${section_details[${section_index}_name]}"
	printf "%s/site/%s\n" "$glroot" "$section_name" >> "$rootdir/.tmp/.fullpath"
	if [[ "${section_details[${section_index}_dated]}" = "y" ]]
	then
		printf "/site/%s/%%Y-%%m-%%d/ \n" "$section_name" >> "$rootdir/.tmp/.cleanup_dated"
		[[ "$section_name" != "0DAY" ]] && printf "/site/%s/ \n" "$section_name" >> "$rootdir/.tmp/.tempdated" && awk -F '[" "]+' '{printf $0}' "$rootdir/.tmp/.tempdated" > "$rootdir/.tmp/.path"
	else
		printf "/site/%s/ \n" "$section_name" >> "$rootdir/.tmp/.temp"
		awk -F '[" "]+' '{printf $0}' "$rootdir/.tmp/.temp" > "$rootdir/.tmp/.nodatepath"
	fi
}

## Update site rules
update_site_rules()
{
	local section_index=$1 rule_counter=$2
	local section_name="${section_details[${section_index}_name]}"
	printf "%s :\n" "$section_name" >> site.rules
	printf "%02d.1 Main language: English/Nordic................................................................................[NUKE 5X]\n\n" "$rule_counter" >> site.rules
	sed -i "s/sections=\"/sections=\"\n$section_name:^$(printf '%02d' "$rule_counter")./" packages/scripts/tur-rules/tur-rules.sh
}

## Collect section details (name, dated, zipfiles, movie) into section_details + cache
prompt_section_details()
{
	local section_index=$1 field prompt name
	name=$(ask_cached "section${section_index}" "Section ${section_index} is: ")
	if (( section_index == 1 )) && ! has_key "$cache" "section1"
	then
		printf "Recommended sections:\n0DAY ANIME APPS DOX EBOOKS FLAC GAMES MBLURAY MP3 NSW PS4 PS5 TV-1080 TV-2160\nTV-720 TV-HD TV-NL X264 X264-1080 X264-720 X265-2160 XVID XXX XXX-PAYSITE\n\n"
	fi
	section_details[${section_index}_name]="${name^^}"
	for field in dated zipfiles movie
	do
		case $field in
			dated)    prompt="Is section ${name^^} a dated section? [Y]es [N]o, default N: " ;;
			zipfiles) prompt="Does this section contain ZIP files? [Y]es [N]o, default N: " ;;
			movie)    prompt="Is this a movie section? [Y]es [N]o, default N: " ;;
		esac
		section_details[${section_index}_${field}]=$(ask_cached "section${section_index}${field}" "$prompt" n y)
	done
}

## Main section creation workflow
create_section_workflow()
{
	local sections section_counter=0 rule_counter=2 current_section
	sections=$(ask_cached "sections" "How many sections do you need for your site? : ")
	printf "\n"
	: > "$rootdir/.tmp/.sections"
	: > "$rootdir/.tmp/.validsections"
	: > "$rootdir/.tmp/dzsrace"
	: > "$rootdir/.tmp/dzschan"	
	cp packages/scripts/tur-rules/tur-rules.sh.org packages/scripts/tur-rules/tur-rules.sh
	packages/scripts/tur-rules/rulesgen.sh GENERAL
	cp packages/modules/tur-autonuke/tur-autonuke.conf.org packages/modules/tur-autonuke/tur-autonuke.conf
	cp packages/core/dated.sh.org "$rootdir/.tmp/dated.sh"
	while [[ $section_counter -lt $sections ]]
	do
		current_section=$((section_counter + 1))
		prompt_section_details "$current_section"
		create_section_directory "${section_details[${current_section}_name]}"
		create_temporary_bot_config "${section_details[${current_section}_name]}" "${section_details[${current_section}_dated]}"
		update_auxiliary_scripts "$current_section"
		finalize_section_creation "$current_section"
		update_site_rules "$current_section" "$rule_counter"
		section_counter=$((section_counter + 1))
		rule_counter=$((rule_counter + 1))
	done
}

start()
{
    print_banner "Server configuration"
    echo

    if has_key "$cache" sitename
    then

        sitename=$(get_value "$cache" "sitename")
        return
    fi

    while [[ -z $sitename ]]
    do

        read -p "Please enter the name of the site, without space : " sitename

    done

    sitename=${sitename// /_}

    if ! has_key "$cache" sitename
    then

        echo "sitename=\"$sitename\"" >> "$cache"

    fi

}


port()
{
    if has_key "$cache" port
    then

        port=$(get_value "$cache" port)
        return

    fi

    printf "Please enter the port number for your site, default 2010 : "
    read -r port

    if [[ -z $port ]]
    then

        port="2010"

    fi

   	if ! has_key "$cache" "port"
    then

    	echo "port=\"$port\"" >> "$cache"

    fi
}


version()
{

    print_status_start "Downloading all required script packages"

    url=""

    for mirror in "https://glftpd.io" "https://mirror.glftpd.nl.eu.org"
    do

		if package_name=$(curl -sf --connect-timeout 10 "$mirror" | \
	   		grep -o "glftpd-LNX-[^BETA]*\.tgz" | head -1) && \
	 		[[ "$package_name" == glftpd-LNX* ]]

		then

		    url="$mirror"
	    	break

		fi

    done

    if [[ -z "$url" ]]
    then

		echo
		echo
		echo "${red}No available website for downloading glFTPd, aborting installation.${reset}"
		exit 1

    fi

    latest=$(curl -sf "$url" | grep -o "glftpd-LNX-[^BETA]*\.tgz" | head -1)
    architecture=$(uname -m)

    case $architecture in

		i686|i386)

	    	version="32"
		    latest=${latest/x64/x86}
		    ;;

		x86_64|amd64)

		    version="64"
	    	;;

		*)

		    version="$architecture"
	    	echo "${red}Unsupported architecture: $architecture${reset}"
		    exit 1
		    ;;

    esac
    
    PK1="$latest"
    PK1DIR="${latest%.tgz}"
    PK2DIR="pzs-ng"
    PK3DIR="eggdrop"    

    # Download and extract
    if ! wget -q "$url/files/$latest" -P packages/ || ! tar xf "packages/$latest" -C packages/
    then

		echo "${red}Failed to download or extract glFTPd package${reset}"
		exit 1

    fi
    
    # Clone pzs-ng with error checking
    if ! git clone -q https://github.com/glftpd/pzs-ng "packages/$PK2DIR" >/dev/null 2>&1
    then

        echo "${red}Failed to clone pzs-ng repository${reset}"
        exit 1

    fi

    # Clone eggdrop with error checking
    if ! git clone -q https://github.com/eggheads/eggdrop "packages/$PK3DIR" >/dev/null 2>&1
    then

        echo "${red}Failed to clone eggdrop repository${reset}"
		exit 1
	
    fi    

    # Check and create group/user while generating SQL pass
    BOTU="sitebot"
    SQLPASSWD=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 20; echo)

    [[ $(getent group glftpd) ]] || groupadd glftpd -g 199
    [[ $(getent passwd sitebot) ]] || useradd -d "$glroot/sitebot" -m -g glftpd -s /bin/bash "$BOTU" && chfn -f 0 -r 0 -w 0 -h 0 "$BOTU"
    
    # cleanup
    rm "packages/$latest"    
    mkdir -p packages/source
    cp -R packages/scripts packages/source/
    cp -f "$rootdir/packages/core/cleanup.sh" "$rootdir"

    print_status_done
    echo

}

device_name()
{

    if has_key "$cache" device
    then

    	device=$(get_value "$cache" device)
		cat <<-EOF
			Sitename           = $sitename
			Port               = $port
			glFTPd version     = $version bit
			Device             = $device
		EOF

    else
	
		cat <<-EOF
			Please enter which device you will use for the $glroot/site folder
			e.g. /dev/sda1
			e.g. /dev/mapper/lvm-lvm
			e.g. /dev/md0
			Default: /dev/sda1
		EOF

		read -p "Device : " device
    	echo
    
	[[ -z "$device" ]] && device="/dev/sda1"
	
    fi

    cp packages/scripts/tur-space/tur-space.conf packages/scripts/tur-space/tur-space.conf.new
    echo "[TRIGGER]" >> packages/scripts/tur-space/tur-space.conf.new
    echo "TRIGGER=$device:100000:200000" >> packages/scripts/tur-space/tur-space.conf.new
    echo "" >> packages/scripts/tur-space/tur-space.conf.new
    echo "[INCOMING]" >> packages/scripts/tur-space/tur-space.conf.new
    
    if ! has_key "$cache" device
    then

    	echo device=\"$device\" >> $cache

    fi

}

channel()
{
    if has_key "$cache" ircserver
    then

        ircserver=$(get_value "$cache" ircserver)
        echo "IRC server         = $ircserver"

    fi

    if has_key "$cache" channelnr
    then

        #echo
        channelnr=$(get_value "$cache" channelnr)

    else

        while [[ -z $channelnr || $channelnr -gt 15 ]]
        do

            read -p "How many channels do you require the bot to be in (max 15)? : " channelnr

        done

    fi

    counta=0

	if ! has_key "$cache" channelnr
    then

        echo "channelnr=\"$channelnr\"" >> "$cache"

    fi

    while (( counta < channelnr ))
    do

        chanpassword=""

        if has_key "$cache" "channame$((counta+1))"
        then

            # One read from cache, then split into: name, flag, password
            raw=$(get_value "$cache" "channame$((counta+1))")
            read -r channame chanpasswd chanpassword <<<"$raw"

            echo "Channel $((counta+1))          = $channame"
            echo "Requires password  = $chanpasswd"

        else

            echo "Include # in the name of channel ie #main"
            while [[ -z $channame ]]
            do

                read -p "Channel $((counta+1)) is : " channame

            done

            read -p "Channel password ? [Y]es [N]o, default N : " chanpasswd
            [[ -z $chanpasswd ]] && chanpasswd="N"

        fi

        case "$chanpasswd" in
            [Yy])

                if has_key "$cache" announcechannels
                then

                    echo "Channel mode       = password protected"

                fi

                # If cached tuple didn’t include a password, prompt for it
                while [[ -z $chanpassword ]]
                do

                    read -p "Enter the channel password : " chanpassword

                done

                echo "channel set $channame chanmode {+ntpsk $chanpassword}" >> "$rootdir/.tmp/bot.chan.tmp"

				cat <<-EOF >> "$rootdir/.tmp/eggchan"
					channel add $channame {
					idle-kick 0
					stopnethack-mode 0
					flood-chan 0:0
					flood-join 0:0
					flood-ctcp 0:0
					flood-kick 0:0
					flood-deop 0:0
					flood-nick 0:0
					aop-delay 0:0
					chanmode "+ntsk $chanpassword"
					}
				
				EOF

                echo "$channame" >> "$rootdir/.tmp/channels"

                if ! has_key "$cache" "channame$((counta+1))"
                then

                    echo "channame$((counta+1))=\"$channame $chanpasswd $chanpassword\"" >> "$cache"

                fi
                ;;

            [Nn])

                if has_key "$cache" announcechannels
                then

                    echo "Channel mode       = invite only"

                fi

                echo "channel set $channame chanmode {+ntpsi}" >> "$rootdir/.tmp/bot.chan.tmp"

				cat <<-EOF >> "$rootdir/.tmp/eggchan"
					channel add $channame {
					idle-kick 0
					stopnethack-mode 0
					flood-chan 0:0
					aop-delay 0:0
					chanmode +ntsi
					}
				
				EOF

                echo "$channame" >> "$rootdir/.tmp/channels"

                if ! has_key "$cache" "channame$((counta+1))"
                then

                    echo "channame$((counta+1))=\"$channame n nopass\"" >> "$cache"

                fi
                ;;

            *)

                if has_key "$cache" announcechannels
                then

                    echo "Channel mode       = invite only"

                fi

                echo "channel set $channame chanmode {+ntpsi}" >> "$rootdir/.tmp/bot.chan.tmp"

				cat <<-EOF >> "$rootdir/.tmp/eggchan"
					channel add $channame {
					idle-kick 0
					stopnethack-mode 0
					flood-chan 0:0
					aop-delay 0:0
					chanmode +ntsi
					}
				
				EOF

                echo "$channame" >> "$rootdir/.tmp/channels"

                if ! has_key "$cache" "channame$((counta+1))"
                then

                    echo "channame$((counta+1))=\"$channame n nopass\"" >> "$cache"

                fi
                ;;

        esac

        channame=""
        chanpasswd=""
        ((counta++))


    done

}

announce()
{
    sed -i -e :a -e N -e 's/\n/ /' -e ta "$rootdir/.tmp/channels"

	if has_key "$cache" announcechannels
	then
	
		announcechannels=$(get_value "$cache" announcechannels)
		echo "Announce channels  = $announcechannels"
	
	else
	
		default_channels=$(cat "$rootdir/.tmp/channels")
		echo "Channels: $default_channels"
		while [[ -z $announcechannels ]]
		do

			read -p "Which should be announce channels, default: $default_channels : " announcechannels
			[[ -z $announcechannels ]] && announcechannels="$default_channels"

		done
	
	fi
	
	echo "$announcechannels" > "$rootdir/.tmp/dzchan"
	
	if ! has_key "$cache" announcechannels
	then

		echo "announcechannels=\"$announcechannels\"" >> "$cache"

	fi

    if has_key "$cache" channelmain
    then

        channelmain=$(get_value "$cache" channelmain)
        echo "Main channel       = $channelmain"

    else

        default_channel=$(awk '{print $1}' "$rootdir/.tmp/channels")
        echo "Channels: $(cat "$rootdir/.tmp/channels")"
        while [[ -z $channelmain ]]
        do

            read -p "Which should be the main channel, default: $default_channel : " channelmain
            [[ -z $channelmain ]] && channelmain="$default_channel"

        done

    fi

    echo "$channelmain" > "$rootdir/.tmp/dzmchan"

    if ! has_key "$cache" channelmain
    then

        echo "channelmain=\"$channelmain\"" >> "$cache"

    fi

    if has_key "$cache" channelspam
    then

        channelspam=$(get_value "$cache" channelspam)
        echo "Spam channel       = $channelspam"

    else

        default_channel=$(awk '{print $1}' "$rootdir/.tmp/channels")
        echo "Channels: $(cat "$rootdir/.tmp/channels")"
        while [[ -z $channelspam ]]
        do

            read -p "Which of these channels as spam channel, default: $default_channel : " channelspam
            [[ -z $channelspam ]] && channelspam="$default_channel"

        done

    fi

    echo "$channelspam" > "$rootdir/.tmp/dzspamchan"

    if ! has_key "$cache" channelspam
    then

        echo "channelspam=\"$channelspam\"" >> "$cache"

    fi

    if has_key "$cache" channelops
    then

        channelops=$(get_value "$cache" channelops)
        echo "Ops channel        = $channelops"

    else

        default_channel=$(awk '{print $1}' "$rootdir/.tmp/channels")
        echo "Channels: $(cat "$rootdir/.tmp/channels")"
        while [[ -z $channelops ]]
        do

            read -p "Which of these channels as ops channel, default: $default_channel : " channelops
            [[ -z $channelops ]] && channelops="$default_channel"

        done

    fi

    echo "$channelops" > "$rootdir/.tmp/dzochan"

	if ! has_key "$cache" channelops
    then

        echo "channelops=\"$channelops\"" >> "$cache"

    fi

    rm "$rootdir/.tmp/channels"
}

ircnickname()
{

    if has_key "$cache" ircnickname
    then

		ircnickname=$(get_value "$cache" ircnickname)
		echo "Nickname           = $ircnickname"

    else	

		while [[ -z $ircnickname ]] 
		do

	    	read -p "What is your nickname on irc ? ie l337 : " ircnickname

		done

    fi
	
    if ! has_key "$cache" ircnickname
    then

		echo "ircnickname=\"$ircnickname\"" >> $cache

    fi

}

## how many sections
glftpd()
{
    if has_key "$cache" eur0presystem
    then

		echo "Sections           = $(cat $rootdir/.tmp/.validsections)"

    fi

    if has_key "$cache" router
    then

        echo "Router             = "$(get_value "$cache" router)

    fi

    if has_key "$cache" pasv_addr
    then

		echo "Passive address    = "$(get_value "$cache" pasv_addr)

    fi

    if has_key "$cache" pasv_ports
    then

        echo "Port range         = "$(get_value "$cache" pasv_ports)

    fi

    if has_key "$cache" psxcimdbchan
    then

        echo "IMDB channels      = "$(get_value "$cache" psxcimdbchan)

    fi

    echo
    #echo "--------[ Installation of software and scripts ]----------------------"
    print_banner "Installation of software and scripts"
    packages/scripts/tur-rules/rulesgen.sh MISC
    cd packages
    echo

    print_status_start "Installing" "glftpd"

    echo "####### Here starts glFTPd scripts #######" >> /var/spool/cron/crontabs/root
    cd $PK1DIR && sed "s/changeme/$port/" ../core/installgl.sh.org > installgl.sh && chmod +x installgl.sh && ./installgl.sh >/dev/null 2>&1
    >$glroot/ftp-data/misc/welcome.msg

    print_status_done

    cd ../core
	cat <<-EOF > glftpd.conf
		##########################################################################
		# Server shutdown: 0=server open, 1=deny all but siteops, !*=deny all, etc
		shutdown 1
		#
		sitename_long			$sitename
		sitename_short			$sitename
		email					root@localhost.org
		login_prompt			$sitename[:space:]Ready
		mmap_amount				100
		# SECTION				KEYWORD     DIRECTORY   SEPARATE CREDITS
		stat_section			DEFAULT     *           no
	EOF
    if has_key "$cache" router
    then

		router=$(get_value "$cache" router)

    else

		echo
		read -p "Do you use a router ? [Y]es [N]o, default N : " router

    fi

    case $router in

	[Yy])

	    curlbinary=$(command -v curl)
	    ipcheck="$($curlbinary -4fsS https://ifconfig.me/)"

	    if has_key "$cache" pasv_addr
	    then

			pasv_addr=$(get_value "$cache" pasv_addr)

	    else	

			read -p "Please enter the DNS or IP for the site, default $ipcheck : " pasv_addr

	    fi
			
	    if [[ -z "$pasv_addr" ]] 
	    then

			pasv_addr="$ipcheck"

	    fi
		
	    if has_key "$cache" pasv_ports
	    then

			pasv_ports=$(get_value "$cache" pasv_ports)

	    else

			read -p "Please enter the port range for passive mode, default 6000-7000 : " pasv_ports

	    fi
		
	    echo "pasv_addr               $pasv_addr	1" >> glftpd.conf

	    if [[ -z "$pasv_ports" ]] 
	    then

	    	echo "pasv_ports              6000-7000" >> glftpd.conf
	    	pasv_ports="6000-7000"

	    else

			echo "pasv_ports              $pasv_ports" >> glftpd.conf

	    fi
	    ;;

	[Nn]) router=n ;;
	*) router=n ;;

    esac
	
    if ! has_key "$cache" router
    then

		echo "router=\"$router\"" >> $cache

    fi
	
    if ! has_key "$cache" pasv_addr
    then

    	echo "pasv_addr=\"$pasv_addr\"" >> $cache

    fi
	
    if ! has_key "$cache" pasv_ports
    then

    	echo "pasv_ports=\"$pasv_ports\"" >> $cache

    fi
	
    #cat glstat >> glftpd.conf && rm glstat
    # Configure glftpd.conf
    cat glfoot >> glftpd.conf && mv glftpd.conf "$glroot/etc/"

    # Copy default user file
    cp -f default.user "$glroot/ftp-data/users/"

    # Add cron jobs
    add_cron_job "59 23 * * *" "$(command -v chroot) $glroot /bin/cleanup"
    add_cron_job "29 4 * * *" "$(command -v chroot) $glroot /bin/datacleaner"
    add_cron_job "*/10 * * * *" "$glroot/bin/incomplete-list-nuker.sh"
    add_cron_job "0 1 * * *" "$glroot/bin/olddirclean2 -PD"
    add_cron_job "0 18 * * *" "$glroot/bin/glftpd-version-check.sh"

    # Create log file and move tur-space config
    touch "$glroot/ftp-data/logs/incomplete-list-nuker.log"
    mv ../scripts/tur-space/tur-space.conf.new "$glroot/bin/tur-space.conf"

    # Copy various scripts
    cp ../scripts/tur-space/tur-space.sh \
       ../scripts/tur-precheck/tur-precheck.sh \
       ../scripts/tur-predircheck/tur-predircheck.sh \
       ../scripts/tur-predircheck_manager/tur-predircheck_manager.sh \
       ../scripts/tur-free/tur-free.sh \
       ../scripts/tag-empty-inc/tag-empty-inc.sh \
       "$glroot/bin/"

    # Configure tur-free.sh
    sed -i '/^SECTIONS/a '"TOTAL:$device" "$glroot/bin/tur-free.sh"
    sed -i "s/changeme/$sitename/" "$glroot/bin/tur-free.sh"

    # Compile and install binaries
    gcc ../scripts/tur-predircheck/glftpd2/dirloglist_gl.c -o "$glroot/bin/dirloglist_gl"
    gcc -O2 ../extra/tur-ftpwho/tur-ftpwho.c -o "$glroot/bin/tur-ftpwho"
    gcc ../extra/tuls/tuls.c -o "$glroot/bin/tuls"

    # Cleanup unnecessary files
    rm -f \
        "$glroot/README" \
        "$glroot/README.ALPHA" \
        "$glroot/UPGRADING" \
        "$glroot/changelog" \
        "$glroot/LICENSE" \
        "$glroot/LICENCE" \
        "$glroot/glftpd.conf" \
        "$glroot/installgl.debug" \
        "$glroot/installgl.sh" \
        "$glroot/glftpd.conf.dist" \
        "$glroot/convert_to_2.0.pl" \
        "/etc/glftpd.conf"

    # Move and copy additional files
    mv -f "$glroot/create_server_key.sh" "$glroot/etc/"
    mv -f ../../site.rules "$glroot/ftp-data/misc/"

    # Copy more utility scripts
    cp ../extra/incomplete-list.sh \
       ../extra/incomplete-list-nuker.sh \
       ../extra/incomplete-list-symlinks.sh \
       ../extra/nuke_cache.sh \
       ../extra/lastlogin.sh \
       "$glroot/bin/"

    # Set permissions and create symlink
    chmod 755 "$glroot/site"
    ln -s "$glroot/etc/glftpd.conf" "/etc/glftpd.conf"
    chmod 777 "$glroot/ftp-data/msgs"

    # Copy additional management scripts
    cp ../extra/update_perms.sh \
       ../extra/update_gl.sh \
       ../extra/imdb-scan.sh \
       ../extra/imdb-rescan.sh \
       ../extra/glftpd-version-check.sh \
       "$glroot/bin/"

    # Install and configure section manager
    cp ../scripts/section-manager/section-manager.sh "$glroot/"
    sed -i "s|changeme|$device|" "$glroot/section-manager.sh"

    # Copy IMDb rating script
    cp ../scripts/imdbrating/imdbrating.sh "$glroot/bin/"

    # Update ginfo.body
    sed -i 's/10.10s/10.20s/' "$glroot/ftp-data/text/ginfo.body"

    # Copy essential binaries
    bins="basename bash bc chmod chown date du echo expr find grep mktemp mv pwd sed sort tac touch which xargs"

    for file in $bins
    do

        bin_path=$(which "$file")
        if [[ -n "$bin_path" ]]
        then

            cp "$bin_path" "$glroot/bin/"

        fi

    done

    # Configure systemd socket if present
    if [[ -f /etc/systemd/system/glftpd.socket ]]
    then

		sed -i 's/#MaxConnections=64/MaxConnections=300/' /etc/systemd/system/glftpd.socket
        systemctl daemon-reload && systemctl restart glftpd.socket

    fi
    
}

## EGGDROP
eggdrop()
{
    ! has_key "$cache" eur0presystem && echo

    print_status_start "Installing" "eggdrop"

    cd ../$PK3DIR ; ./configure --prefix="$glroot/sitebot" >/dev/null 2>&1 && make config >/dev/null 2>&1 && make >/dev/null 2>&1 && make install >/dev/null 2>&1
    cd ../core
    # Create eggdrop.conf
    cat egghead > eggdrop.conf
    cat "$rootdir/.tmp/eggchan" >> eggdrop.conf
    echo "set username          \"$sitename\"" >> eggdrop.conf
    echo "set nick              \"$sitename\"" >> eggdrop.conf
    echo "set altnick           \"_$sitename\"" >> eggdrop.conf
    cat eggfoot >> eggdrop.conf
    sed -i "s/changeme/$ircnickname/" eggdrop.conf
    mv eggdrop.conf "$glroot/sitebot/"

    # Create bot.chan file
    cat "$rootdir/.tmp/bot.chan.tmp" > "$glroot/sitebot/logs/bot.chan"

    # Create botchk script
	cat <<-EOF > "$glroot/sitebot/botchk"
		#!/bin/bash
		botdir=$glroot/sitebot
		botscript=sitebot
		botname=$sitename
		userfile=./logs/bot.user
		pidfile=pid.$sitename
		$(cat botchkfoot)
	EOF
	chmod 755 "$glroot/sitebot/botchk"
    
    # Create start and kill script
    cat <<-EOF >> $glroot/sitebot/start.sh
		#!/bin/bash

		su - sitebot -c "./botchk"
	EOF
	
    cat <<-EOF >> $glroot/sitebot/kill.sh
		#!/bin/bash

		site=$sitename
		[[ -f "pid.$sitename" ]] && kill \$(cat pid.$sitename)
	EOF
   
    chmod 755 $glroot/sitebot/start.sh $glroot/sitebot/kill.sh    

    # Setup cron job
    touch "/var/spool/cron/crontabs/$BOTU"
    chmod 600 /var/spool/cron/crontabs/$BOTU
    add_cron_job "*/10 * * * *" "$glroot/sitebot/botchk" "$BOTU"

    # Cleanup files
    rm -f \
        "$glroot/sitebot/BOT.INSTALL" \
        "$glroot/sitebot/README" \
        "$glroot/sitebot/eggdrop1.8" \
        "$glroot/sitebot$glroot-tcl.old-TIMER" \
        "$glroot/sitebot$glroot.tcl-TIMER" \
        "$glroot/sitebot/eggdrop" \
        "$glroot/sitebot/eggdrop-basic.conf" \
        "$glroot/sitebot/scripts/CONTENTS" \
        "$glroot/sitebot/scripts/autobotchk" \
        "$glroot/sitebot/scripts/botchk" \
        "$glroot/sitebot/scripts/weed" 

    rm -f $glroot/sitebot/scripts/*.tcl
    rm -f $glroot/sitebot/scripts/*.py

    # Create symlink and set permissions
    ln -s "$glroot/sitebot/$(ls "$glroot/sitebot" | grep eggdrop-)" "$glroot/sitebot/sitebot"
    chmod 666 "$glroot/etc$glroot.conf"
    chmod 777 "$glroot/sitebot/logs"
    chmod 755 "$glroot/sitebot"
    
    # Create directories and speedtest files
    mkdir -pm 777 "$glroot/site/PRE/SiteOP" "$glroot/site/SPEEDTEST"
    chmod 777 "$glroot/site/PRE"
    dd if=/dev/urandom of="$glroot/site/SPEEDTEST/150MB" bs=1M count=150 status=none
    dd if=/dev/urandom of="$glroot/site/SPEEDTEST/250MB" bs=1M count=250 status=none
    dd if=/dev/urandom of="$glroot/site/SPEEDTEST/500MB" bs=1M count=500 status=none

    # Copy and configure scripts
    cp ../extra/*.tcl "$glroot/sitebot/scripts/"
    sed -i "s/#changeme/$announcechannels/" "$glroot/sitebot/scripts/rud-news.tcl"
    sed -i "s/#personal/$channelops/" "$glroot/sitebot/scripts/rud-news.tcl"
    
    mv -f ../scripts/tur-rules/tur-rules.sh "$glroot/bin/"
    cp ../scripts/tur-rules/*.tcl ../scripts/tur-free/*.tcl "$glroot/sitebot/scripts/"
    cp ../scripts/tur-predircheck_manager/tur-predircheck_manager.tcl "$glroot/sitebot/scripts/"
    sed -i "s/changeme/$channelops/g" "$glroot/sitebot/scripts/tur-predircheck_manager.tcl"
    
    echo "source scripts/tur-free.tcl" >> "$glroot/sitebot/eggdrop.conf"

    print_status_done

}

irc()
{

    if has_key "$cache" ircserver
    then

		sed -i "s/servername/$ircserver/" $glroot/sitebot/eggdrop.conf

    else

		echo
    	read -p "What irc server ? default irc.example.org : " servername

		if [[ -z "$servername" ]]
		then

	    	servername="irc.example.org"

		fi
		
		read -p "What port for irc server ? default 7000 : " serverport

		if [[ -z "$serverport" ]] 
		then
	
		    serverport="7000"

		fi
	
		read -p "Is the port above a SSL port ? [Y]es [N]o, default Y : " serverssl

		case $serverssl in

		    [Yy]) ssl=1	;;
	    	[Nn]) ssl=0	;;
		    *) ssl=1 ;;

		esac
		
		read -p "Does it require a password ? [Y]es [N]o, default N : " serverpassword

		case $serverpassword in

	    	[Yy])

				read -p "Please enter the password for irc server, default ircpassword : " password

				if [[ -z "$password" ]] 
				then

			    	password="ircpassword"

				else
	
				    password="$password"

				fi
				;;

		    [Nn]) password="" ;;
	    	*) password="" ;;

		esac
		
		case $ssl in

	    	1)
		
				sed -i "s/servername/${servername} +${serverport} ${password}/" $glroot/sitebot/eggdrop.conf
		
				if ! has_key "$cache" ircserver
				then

		    		echo "ircserver=\"${servername} +${serverport} ${password}\"" >> $cache

				fi
				;;

	    	0)
		
				sed -i "s/servername/${servername} ${serverport} ${password}/" $glroot/sitebot/eggdrop.conf
		
				if ! has_key "$cache" ircserver
				then

			    	echo "ircserver=\"${servername} ${serverport} ${password}\"" >> $cache

				fi
				;;

		esac

    fi

}

## zsconfig.h
pzshfile()
{
    define_format="%-${leftcol_width}s \"%s\""
    cd ../../
    cat packages/core/pzshead > zsconfig.h
    echo "/site/REQUESTS/" >> $rootdir/.tmp/.nodatepath
    [ -f "$rootdir/.tmp/.path" ] && paths="$(cat $rootdir/.tmp/.path)"
    [ -f "$rootdir/.tmp/.cleanup_dated" ] && cleanup_dated=$(cat $rootdir/.tmp/.cleanup_dated | sed 's/ /\n/g' | sort | xargs)
    nodatepaths="$(cat $rootdir/.tmp/.nodatepath)"
    allsections=$(echo "$paths $nodatepaths" | sed 's/ /\n/g' | sort | xargs | sed 's/^ //')
    leftcol_width=$(
	awk '
	    BEGIN { max=0 }
	    /^#define[ \t]+[A-Za-z_][A-Za-z0-9_]*[ \t]+/ {
		match($0, /^#define[ \t]+[A-Za-z_][A-Za-z0-9_]*[ \t]+/)
		if (RLENGTH > max) max = RLENGTH
	    }
	    END { print (max ? max : 50) }
	' zsconfig.h	
	)
    define_format="%-${leftcol_width}s\"%s\""

    # Left column padded, value column aligned
    printf "$define_format\n" "#define check_for_missing_nfo_dirs" "$allsections"   >> zsconfig.h
    printf "$define_format\n" "#define cleanupdirs"                "$nodatepaths"    >> zsconfig.h
    printf "$define_format\n" "#define cleanupdirs_dated"          "$cleanup_dated"  >> zsconfig.h
    printf "$define_format\n" "#define sfv_dirs"                   "$allsections"    >> zsconfig.h
    printf "$define_format\n" "#define short_sitename"             "$sitename"       >> zsconfig.h
    chmod 755 zsconfig.h
    mv zsconfig.h packages/pzs-ng/zipscript/conf/zsconfig.h

}

## dZSbot.tcl
pzsbotfile()
{
    cat packages/core/dzshead > ngBot.conf
    echo "REQUEST" >> "$rootdir/.tmp/.validsections"

    # --- Fixed alignment from global pzs_width ---
    # Quote should appear at column pzs_width; pad left to (pzs_width - 1)
    local leftcol_width=$((pzs_width))
    local paths_format="%-${leftcol_width}s\"%s\""
    local chanlist_format="%-${leftcol_width}s\"%s\""
    local sections_format="%-${leftcol_width}s\"%s\""

    # Build REQUEST lines already formatted (no later reflow needed)
    local left_side req_paths_line req_chan_line
    left_side="set paths(REQUEST)"
    printf -v req_paths_line "$paths_format" "$left_side" "/site/REQUESTS/*/*"
    echo "$req_paths_line" >> "$rootdir/.tmp/dzsrace"

    left_side="set chanlist(REQUEST)"
    printf -v req_chan_line "$chanlist_format" "$left_side" "$announcechannels"
    echo "$req_chan_line" >> "$rootdir/.tmp/dzschan"

    # --- Alphabetize paths + chanlist by section name (case-insensitive) ---
    awk 'match($0,/set[ \t]+paths\(([^)]+)\)/,m){print m[1] "\t" $0}' "$rootdir/.tmp/dzsrace" \
      | sort -f -k1,1 \
      | cut -f2- > "$rootdir/.tmp/dzsrace.sorted"
    mv "$rootdir/.tmp/dzsrace.sorted" "$rootdir/.tmp/dzsrace"

    awk 'match($0,/set[ \t]+chanlist\(([^)]+)\)/,m){print m[1] "\t" $0}' "$rootdir/.tmp/dzschan" \
      | sort -f -k1,1 \
      | cut -f2- > "$rootdir/.tmp/dzschan.sorted"
    mv "$rootdir/.tmp/dzschan.sorted" "$rootdir/.tmp/dzschan"

    # --- Build the sorted, de-duped sections list and align it with the same width ---
    local sections_value
    sections_value="$(
        tr ' ' '\n' < "$rootdir/.tmp/.validsections" \
        | sed '/^$/d' \
        | sort -fu \
        | xargs
    )"

    local left_side_sections="set sections"
    local sections_line
    printf -v sections_line "$sections_format" "$left_side_sections" "$sections_value"
    echo "$sections_line" >> ngBot.conf
    echo >> ngBot.conf

    # Append blocks and finish
    cat "$rootdir/.tmp/dzsrace" >> ngBot.conf && rm "$rootdir/.tmp/dzsrace"
    cat "$rootdir/.tmp/dzschan" >> ngBot.conf && rm "$rootdir/.tmp/dzschan"
    cat packages/core/dzsfoot >> ngBot.conf
    chmod 644 ngBot.conf
    mkdir -p "$glroot/sitebot/scripts/pzs-ng/themes"
    mv ngBot.conf "$glroot/sitebot/scripts/pzs-ng/ngBot.conf"
}

## PROJECTZS
pzsng()
{

    if ! has_key "$cache" eur0presystem
    then

    	echo

    fi

    print_status_start "Installing" "pzs-ng"

	cd $rootdir/packages/pzs-ng
	pzs_ng_path=$(pwd)
	git clone -q https://github.com/zlib-ng/zlib-ng ${pzs_ng_path}/zlib-ng
	mkdir -p ${pzs_ng_path}/zlib-ng/build && cd ${pzs_ng_path}/zlib-ng/build
	cmake .. -DCMAKE_BUILD_TYPE=Release >/dev/null 2>&1
	make -j$(nproc) >/dev/null 2>&1 && cd ${pzs_ng_path}
	
    ./configure --with-zlib-ng-path=${pzs_ng_path}/zlib-ng/build --with-zlib-ng-include=${pzs_ng_path}/zlib-ng/build >/dev/null 2>&1 ; make >/dev/null 2>&1 ; make install >/dev/null 2>&1
	for lib in $(ldd $glroot/bin/zipscript-c | grep libz | awk '{print $1}'); do
		cp ${pzs_ng_path}/zlib-ng/build/$lib $glroot/lib/x86_64-linux-gnu
	done
	
    cp sitebot/ngB* $glroot/sitebot/scripts/pzs-ng/
    mkdir $glroot/sitebot/scripts/pzs-ng/modules
    cp sitebot/modules/glftpd.tcl $glroot/sitebot/scripts/pzs-ng/modules
    mkdir $glroot/sitebot/scripts/pzs-ng/plugins
    cp ../core/glftpd-installer.theme $glroot/sitebot/scripts/pzs-ng/themes
    cp ../core/ngBot.vars $glroot/sitebot/scripts/pzs-ng
    cp -f ../core/sitewho.conf $glroot/bin
    rm -f $glroot/sitebot/scripts/pzs-ng/ngBot.conf.dist
    cp -f scripts/libcopy/libcopy.sh $glroot
    
    print_status_done
}

modules()
{

    cd $rootdir
    for module in $(ls ./packages/modules)
    do

		. packages/modules/$module/$module.inc

    done

}

## usercreation
usercreation()
{

    if has_key "$cache" username
    then

		username=$(get_value "$cache" username)

    else

		echo
		print_banner "FTP user configuration"
		echo
		read -p "Please enter the username of admin, default admin : " username

    fi
	
    if [[ -z "$username" ]]
    then

    	username="admin"

    fi

    if has_key "$cache" password
    then

    	password=$(get_value "$cache" password)

    else

    	read -p "Please enter the password [$username], default password : " password

    fi
	
    if [[ -z "$password" ]]
    then

    	password="password"

    fi

    localip=$(ip -o -4 addr show | awk '/scope global/ {split($4, a, "."); print a[1]"."a[2]"."a[3]".*"}' | head -1)
    netip=$(curl -4fsS https://ifconfig.me/ | awk -F. '{OFS="."; print $1,$2,$3,"*"}')
	
    if has_key "$cache" ip
    then

		ip=$(get_value "$cache" ip)

    else

		read -rp "IP for [$username] ? Type without *@ or ident@. Minimum xxx.xxx.* default $localip $netip : " ip

    fi
	
    if [[ -z "$ip" ]]
    then

		ip="*@$localip"

        if [[ "$localip" != "$netip" ]]
		then

    	    ip+=" *@$netip"

		fi

    fi

	if ! has_key "$cache" "username"
	then
	
		echo "username=\"$username\"" >> "$cache"
	
	fi
	
	if ! has_key "$cache" "password"
	then
	
		echo "password=\"$password\"" >> "$cache"
	
	fi
	
	if ! has_key "$cache" ip
	then
	
		echo "ip=\"$ip\"" >> "$cache"
	
	fi
	    
    success="230 User glftpd logged in."
    status=$(ftp -nv localhost "$port" <<-EOF
	quote USER glftpd
	quote PASS glftpd
	quit
	EOF
	)

    if echo "$status" | grep -q "$success"
    then

        site_commands=(
            "site change glftpd flags +347ABCDEFGH"
            "site grpadd SiteOP SiteOP"
            "site grpadd Admin Administrators/SYSOP"
            "site grpadd Friends Friends"
            "site grpadd NUKERS NUKERS"
            "site grpadd VACATION VACATION"
            "site grpadd iND Independent Racers"
            "site gadduser Admin $username $password $ip"
            "site chgrp $username SiteOP"
            "site change $username flags +1347ABCDEFGH"
            "site change $username ratio 0"
            "site chgrp glftpd glftpd"
        )
        
        for cmd in "${site_commands[@]}"
        do

            # Execute command and capture both output and exit code
            output=$(ncftpls -u glftpd -p glftpd -P "$port" -Y "$cmd" -E ftp://localhost 2>&1)

            # Check if the command failed based on server response
            # Only show output for actual failures (not empty or success responses)
            if [[ -n "$output" ]] && ! echo "$output" | grep -Eqi "200|success|ok|added|changed"
            then

                echo "${red}FAILED: $cmd${reset}"
                echo "${yellow}Server response: $output${reset}" >&2

            fi

        done
        
        echo
        echo "[$username] created successfully and added to the groups Admin and SiteOP"
        echo "These groups were also created: NUKERS, iND, VACATION & Friends"
    else    

        echo "${yellow}Could not connect to FTP. Attempting to restart services...${reset}" >&2

    fi    

	if [[ -e /etc/systemd/system/glftpd.socket ]]
	then
	
		systemctl stop glftpd.socket >/dev/null 2>&1 && systemctl start glftpd.socket >/dev/null 2>&1
	
	fi
	
	if [[ -e /etc/rc.d/rc.inetd ]]
	then
	
		/etc/rc.d/rc.inetd stop >/dev/null 2>&1 && /etc/rc.d/rc.inetd start >/dev/null 2>&1
	
	fi
        
    sed -i "s/\"changeme\"/\"$username\"/" $glroot/sitebot/eggdrop.conf
    sed -i "s/\"sname\"/\"$sitename\"/" $glroot/sitebot/scripts/pzs-ng/ngBot.conf
    sed -i "s/\"ochan\"/\"$channelops\"/" $glroot/sitebot/scripts/pzs-ng/ngBot.conf
    sed -i "s/(ochan)/($channelops)/" $glroot/sitebot/scripts/pzs-ng/ngBot.conf
    sed -i "s/\"mainname\"/\"$channelmain\"/" $glroot/sitebot/scripts/pzs-ng/ngBot.conf
    sed -i "s/\"spamname\"/\"$channelspam\"/" $glroot/sitebot/scripts/pzs-ng/ngBot.conf
    sed -i "s/\"invitename\"/\"$announcechannels\"/" $glroot/sitebot/scripts/pzs-ng/ngBot.conf

}

## CleanUp / Config
cleanup()
{
    # Change to the root directory or exit if it fails
    cd "$rootdir" || exit
    
    # Create the backup directory (with parents if needed)
    mkdir -p "$glroot/backup"
    
    # Move the three package directories to the source directory
    mv "packages/$PK1DIR" "packages/$PK2DIR" "packages/$PK3DIR" packages/source/

    # Check and move eur0presystem tools if enabled
    if [[ "$(get_value "$cache" eur0presystem)" == "y" ]]
    then

        mv packages/modules/eur0-pre-system/foo-tools packages/source/

    fi

    # Move and copy site files
    mv "$rootdir/.tmp/site/"* "$glroot/site/"
    cp -r packages/source/pzs-ng "$glroot/backup"
    cp packages/extra/pzs-ng-update.sh packages/extra/backup.sh "$glroot/backup"
    sed -i "s/changeme/$sitename/; s/pass=/pass=$SQLPASSWD/" "$glroot/backup/backup.sh"
    cp "$glroot/backup/pzs-ng/sitebot/extra/invite.sh" packages/extra/syscheck.sh "$glroot/bin"
    mv -f "$rootdir/.tmp/dated.sh" "$glroot/bin"

    # Process dated sections
    while IFS= read -r sec
    do

        dated=$(awk -F= -v sec="$sec" '$0 ~ "section"sec"=" {gsub(/"/, "", $2); print $2}' "$cache")
        sed -i '/^sections/a '"${dated^^}" "$glroot/bin/dated.sh"

    done < <(grep 'section.*dated="y"' "$cache" | sed -e 's/section//' -e 's/dated//' -e 's/"//g' | cut -d '=' -f1)

    # Add cron job if dated sections exist
    if grep -q 'section.*dated="y"' "$cache"
    then

        add_cron_job "0 0 * * *" "$glroot/bin/dated.sh"
        "$glroot/bin/dated.sh" >/dev/null 2>&1

    fi

	# Setup TVMaze if TV directories exist
	if find "$glroot/site" -maxdepth 1 -type d -name "TV*" -print -quit | grep -q .
	then

	    cp -f packages/scripts/tvmaze/{TVMaze.tcl,TVMaze.zpt} "$glroot/sitebot/scripts/pzs-ng/plugins"
	    cp packages/scripts/tvmaze/*.sh "$glroot/bin"
	    echo "source scripts/pzs-ng/plugins/TVMaze.tcl" >> "$glroot/sitebot/eggdrop.conf"

	    sections=""

	    for tv in "$glroot/site"/TV*
	    do

	        [[ -d "$tv" ]] || continue
	        sections+=" \"/site/$(basename "$tv")/\""

	    done

	    # Replace only the content inside the braces, preserving indentation
	    # Matches:  ^[spaces/tabs]set[spaces]tvmaze(sections)[spaces]{  ...  }
	    sed -i "s|^\([[:space:]]*set[[:space:]]\{1,\}tvmaze(sections)[[:space:]]*{\).*}|\1$sections }|" \
	        "$glroot/sitebot/scripts/pzs-ng/plugins/TVMaze.tcl"

	    "$glroot/bin/tvmaze-nuker.sh" sanity >/dev/null 2>&1

	fi
	
    # Setup TMDB if MOVIE directories exist
    if find "$glroot/site" -maxdepth 1 -type d -name "X26[45]*" -print -quit | grep -q .
    then

        cp -f packages/scripts/tmdb/{tmdb.tcl,tmdb.zpt} "$glroot/sitebot/scripts/pzs-ng/plugins"
        cp packages/scripts/tmdb/*.sh "$glroot/bin"
        echo "#source scripts/pzs-ng/plugins/tmdb.tcl" >> "$glroot/sitebot/eggdrop.conf"

        sections=""

        for movie in "$glroot/site"/X264* "$glroot/site"/X265*
        do

            [[ -d "$movie" ]] || continue
            sections+=" \"/site/$(basename "$movie")/\""

        done

        # Replace only the content inside the braces, preserving indentation
        # Matches:  ^[spaces/tabs]set[spaces]tvmaze(sections)[spaces]{  ...  }
        sed -i "s|^\([[:space:]]*set[[:space:]]\{1,\}tmdb(sections)[[:space:]]*{\).*}|\1$sections }|" \
            "$glroot/sitebot/scripts/pzs-ng/plugins/tmdb.tcl"

        "$glroot/bin/tmdb-nuker.sh" sanity >/dev/null 2>&1

    fi

    # Add disabled cron job and setup tur-space
    add_cron_job "#*/5 * * * *" "$glroot/bin/tur-space.sh go"
    touch "$glroot/ftp-data/logs/tur-space.log"
    
    # Setup directories and permissions
    mkdir -m777 "$glroot/tmp"
    chown -R "$BOTU:glftpd" "$glroot/sitebot"
    "$glroot/bin/update_perms.sh"
    chmod 777 "$glroot/ftp-data/logs"
    chmod 666 "$glroot/ftp-data/logs/"*
    
    # Clean up and reorganize eggdrop.conf - when no EOF marker exists
    sed -n '/MY SCRIPTS/,$p' "$glroot/sitebot/eggdrop.conf" | sed '1d' | sort > .tmp/myscripts
    sed -i '/MY SCRIPTS/,$d' "$glroot/sitebot/eggdrop.conf"
    echo "# MY SCRIPTS" >> "$glroot/sitebot/eggdrop.conf"
    cat .tmp/myscripts >> "$glroot/sitebot/eggdrop.conf"    
    # Cleanup temporary files and directories
    rm -rf .tmp "$glroot/glftpd-LNX_current" packages/modules/tur-autonuke/tur-autonuke.conf
    
    # Install and configure rsyslog if directory exists
    if [[ -d /etc/rsyslog.d ]]
    then

        cp packages/extra/glftpd.conf /etc/rsyslog.d/
        service rsyslog restart

    fi
    
    # Install rescan fix script and add cron job
    cp packages/extra/rescan_fix.sh "$glroot/bin"
    add_cron_job "*/2 * * * *" "$glroot/bin/rescan_fix.sh"
    
    # Ensuring all relevant libs are copied to $glroot/lib
    $glroot/libcopy.sh >/dev/null 2>&1
    
}

requirements
version
start
port
device_name
channel
announce
ircnickname
create_section_workflow
glftpd
eggdrop
irc
pzshfile
pzsbotfile
pzsng
modules
usercreation
cleanup

cat <<-EOF

If you are planning to uninstall glFTPd then run cleanup.sh

To get the bot running you HAVE to do this ONCE to create the initial userfile
su - sitebot -c "$glroot/sitebot/sitebot -m"

If you want automatic cleanup of site then please review the settings in $glroot/bin/tur-space.conf and enable the line in crontab

All good to go and I recommend people to check the different settings for the different scripts including glFTPd itself.

Enjoy!

Installer script created by Teqno
EOF
