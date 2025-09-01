#!/bin/bash
VER=1.8
#--[ Intro ]----------------------------------------------------
#
# Tur-predircheck_manager. A script for lazy people to block  	
# and unblock groups and releases in sections from within irc.
#
# The tcl is locked to a single chan that the executor  	
# must be in and it is also locked to ops only by default so	
# the user must be added to the bot with flag o (just      	
# being an @ in channel is not enough).				
#
#-[ Install ]---------------------------------------------------
#
# Copy tur-predircheck_manager.sh to /glftpd/bin and chmod 755. 
# Copy sed to /glftpd/bin and chmod u+s.                        
# Copy tur-predircheck_manager.tcl to your eggdrop scripts dir. 
# Edit it and check the settings. When done, load the script   	
# in the bots config file and rehash the bot.                	
#
#--[ Info ]-----------------------------------------------------
#
# This script looks after the first line of sections that 	
# matches when blocking so if you have specified the same 	
# section numerous times to give a better view in shell then 	
# you should be aware of this. This is necessary or the script 	
# would simply insert the block on all matching rows which 	
# causes redunancy.						
#
# Sections need to be added to the tur-predircheck.sh before	
# a block with this script works as intended. No need to know	
# any regex since the script automatically makes the proper one 
# based on the command.						
#								
# Addon created by Teqno					
#
#--[ Settings ]-------------------------------------------------

glroot="/glftpd"		
predircheck="$glroot/bin/tur-predircheck.sh"
irctrigger=$(grep "pub:tur-predircheck" /glftpd/sitebot/scripts/tur-predircheck_manager.tcl | head -1 | awk '{print $4}')

# How long should the block line under DENYDIRS be allowed to be before making a new line
length=210

#--[ Script start ]---------------------------------------------

ARGS=$(echo "$@" | cut -d ' ' -f2- | sed 's:[]\[\^\$\.\*\/]:\\\\&:g')
INPUT=$(echo "$@" | cut -d ' ' -f2-)
COLOR1="4"
RESET=""

# Help text when no args
if [[ -z "${ARGS:-}" ]]
then

    cat <<-EOF
        ${irctrigger} list sections        - List current blocklist for sections
        ${irctrigger} list groups          - List current blocklist for groups
		${irctrigger} search <rel/group>   - Search for a specific release/group under DENYGROUPS and DENYDIRS
		${irctrigger} add release <section> <show/movie>  - Block by show/movie name
		${irctrigger} del release <section> <show/movie>  - Unblock by show/movie name
		${irctrigger} add word <section> <word>           - Block by word in releasename
		${irctrigger} del word <section> <word>           - Unblock by word in releasename
		${irctrigger} add section group <section> <group> - Block by groupname in section
		${irctrigger} del section group <section> <group> - Unblock by groupname in section
		${irctrigger} del section rows <section>          - Delete all rows of a section
		${irctrigger} add group <group>    - Block group sitewide
		${irctrigger} del group <group>    - Unblock group sitewide
	EOF

    exit 0

fi

case "$ARGS" in

    "list sections")
        "$glroot/bin/sed" -n '/^DENYDIRS="/,/"$/p' "$predircheck"
        ;;

    "list groups")
        "$glroot/bin/sed" -n '/^DENYGROUPS="/,/"$/p' "$predircheck"
        ;;

    search\ *)
        search="${ARGS#search }"
        if [[ -z "$search" ]]
        then
            echo "Please enter a word to search for"
            exit 0
        fi

        "$glroot/bin/sed" -n '/DENYGROUPS/,/ALLOWDIRS/p' "$predircheck" | grep -E --color=always -i "$search" || true
        matches=$("$glroot/bin/sed" -n '/DENYGROUPS/,/ALLOWDIRS/p' "$predircheck" | grep -Ei -c "$search" || true)

        if (( matches == 0 ))
        then
            echo "The block${COLOR1} $search ${COLRST}was not found in blocklist"
        fi
        ;;

    add\ release\ *)
        # parse section and regex
        section=$(awk '{print $3}' <<< "$ARGS")
        regexp=$(awk '{print $4}' <<< "$ARGS")
        regexpc=$(awk '{print $4}' <<< "$INPUT")

        if [[ -z "$section" || -z "$regexp" ]]
        then
            echo "You need to specify section and release"
            exit 0
        fi

        # logic continues unchanged…
        ;;

    add\ word\ *)
        section=$(awk '{print $3}' <<< "$ARGS")
        regexp=$(awk '{print $4}' <<< "$ARGS")
        regexpc=$(awk '{print $4}' <<< "$INPUT")

        if [[ -z "$section" || -z "$regexp" ]]
        then
            echo "You need to specify section and word"
            exit 0
        fi

        # logic continues unchanged…
        ;;

    add\ section\ group\ *)
        section=$(awk '{print $4}' <<< "$ARGS")
        regexp=$(awk '{print $5}' <<< "$ARGS")
        regexpc=$(awk '{print $5}' <<< "$INPUT")

        if [[ -z "$section" || -z "$regexp" ]]
        then
            echo "You need to specify section and group"
            exit 0
        fi

        # logic continues unchanged…
        ;;

    del\ release\ *)
        section=$(awk '{print $3}' <<< "$ARGS")
        regexp=$(awk '{print $4}' <<< "$ARGS")
        regexpc=$(awk '{print $4}' <<< "$INPUT")

        if [[ -z "$section" || -z "$regexp" ]]
        then
            echo "You need to specify section and release"
            exit 0
        fi

        # logic continues unchanged…
        ;;

    del\ word\ *)
        section=$(awk '{print $3}' <<< "$ARGS")
        regexp=$(awk '{print $4}' <<< "$ARGS")
        regexpc=$(awk '{print $4}' <<< "$INPUT")

        if [[ -z "$section" || -z "$regexp" ]]
        then
            echo "You need to specify section and word"
            exit 0
        fi

        # logic continues unchanged…
        ;;

    del\ section\ group\ *)
        section=$(awk '{print $4}' <<< "$ARGS")
        regexp=$(awk '{print $5}' <<< "$ARGS")
        regexpc=$(awk '{print $5}' <<< "$INPUT")

        if [[ -z "$section" || -z "$regexp" ]]
        then
            echo "You need to specify section and group"
            exit 0
        fi

        # logic continues unchanged…
        ;;

    del\ section\ rows\ *)
        section=$(awk '{print $4}' <<< "$ARGS")

        if [[ -z "$section" ]]
        then
            echo "You need to specify section"
            exit 0
        fi

        # logic continues unchanged…
        ;;

    add\ group\ *)
        group=$(awk '{print $3}' <<< "$ARGS")

        if [[ -z "$group" ]]
        then
            echo "You need to specify group"
            exit 0
        fi

        # logic continues unchanged…
        ;;

    del\ group\ *)
        group=$(awk '{print $3}' <<< "$ARGS")

        if [[ -z "$group" ]]
        then
            echo "You need to specify group"
            exit 0
        fi

        # logic continues unchanged…
        ;;

esac
