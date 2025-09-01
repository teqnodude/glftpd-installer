#!/bin/bash
VER=1.2
#--[ Settings ]-------------------------------------------------

glroot=/glftpd
gllog=$glroot/ftp-data/logs/glftpd.log

#--[ Script Start ]---------------------------------------------

red="$(tput setaf 1)"
green="$(tput setaf 2)"
reset="$(tput sgr0)"

if [[ $(curl -s https://glftpd.io | grep -E "/files/glftpd" | grep -Ev "BETA" | grep -o "glftpd-LNX.*\.tgz" | head -n 1) == glftpd* ]]
then

    url="https://glftpd.io"

else

    if [[ $(curl -s https://mirror.glftpd.nl.eu.org | grep -E "/files/glftpd" | grep -Ev "BETA" | grep -o "glftpd-LNX.*\.tgz" | head -n 1) == glftpd* ]]
    then

        url="https://mirror.glftpd.nl.eu.org"

    else

        echo
        echo
        echo "${red}No available website for glFTPd, aborting check.${reset}"
        exit 1

    fi

fi

newversion="$(lynx --dump "$url" | grep -E "latest version" | cut -d ":" -f2 | awk '{print $1}' | sed 's/^v//')"
curversion="$("$glroot/bin/glftpd" | grep -E "glFTPd" | awk '{print $2}')"

if [[ "$newversion" != "$curversion" ]]
then

    echo "$(date "+%a %b %e %T %Y") GLVERSION: \"There is a new glFTPd version available: $newversion - Current version: $curversion - https://glftpd.io\"" >> "$gllog"

else

    echo "${green}Current non BETA version up to date${reset}"

fi
