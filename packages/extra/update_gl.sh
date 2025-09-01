#!/bin/bash
VER=1.2
#--[ Info ]-----------------------------------------------------
#
# glFTPd Upgrader                                               
# - Fetch latest non-BETA build from primary/mirror             
# - Copy binaries + docs, patch sources, recompile, fix perms   
#
#--[ settings ]-------------------------------------------------

glroot=/glftpd
srcdir=$glroot/backup/sources

#--[ colors ]---------------------------------------------------

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
cyan=$(tput setaf 6)
bold=$(tput bold)
reset=$(tput sgr0)

#--[ script start ]---------------------------------------------

if [[ ! -d "$glroot" ]]
then

    echo "${red}glFTPd doesn't seem to be installed in $glroot${reset}"
    exit 0

fi

curversion=$("$glroot/bin/glftpd" 2>/dev/null | grep -Eo 'glFTPd[[:space:]]+[0-9][^ ]*' | awk '{print $2}')

primary=https://glftpd.io
mirror=https://mirror.glftpd.nl.eu.org

html=$(curl -fsSL "$primary" || true)
if [[ -n "$html" ]]
then

    base="$primary"

else

    html=$(curl -fsSL "$mirror" || true)
    base="$mirror"

fi

if [[ -z "$html" ]]
then

    echo
    echo "${red}no available website for downloading glFTPd, aborting upgrade.${reset}"
    exit 1

fi

# determine latest non-BETA package + version
latest=$(printf "%s\n" "$html" | grep -Eo 'glftpd-LNX[^"]+\.tgz' | grep -v BETA | head -1)
newversion=$(printf "%s\n" "$latest" | sed -E 's/^glftpd-LNX-([0-9.]+).*$/\1/')

if [[ -z "$newversion" && -n "$latest" ]]
then

    newversion=$(printf "%s\n" "$latest" | sed -E 's/^glftpd-LNX-([0-9.]+)-.*/\1/')

fi

if [[ -z "$latest" ]]
then

    echo "${red}could not determine the latest package name, aborting.${reset}"
    exit 1

fi

if [[ -n "$curversion" && -n "$newversion" && "$curversion" = "$newversion" ]]
then

    echo "${green}you already have the latest non-BETA version ($curversion).${reset}"
    exit 0

fi

# prep download dir
if [[ ! -d "$srcdir" ]]
then

    mkdir -p "$srcdir"

fi
cd "$srcdir" || exit 1

# arch mapping and package name tweak
arch=$(uname -m)
case "$arch" in
i386|i486|i586|i686)

    latest="${latest/x64/x86}"

    ;;

x86_64)

    :

    ;;

*)

    echo "${red}unsupported architecture: $arch${reset}"
    exit 1

    ;;

esac

pkg_url="$base/files/$latest"
pkg_file="$srcdir/$latest"
changelog="$base/files/docs/UPGRADING"

echo "${cyan}current version:${reset}   ${bold}${curversion:-unknown}${reset}"
echo "${cyan}available version:${reset} ${bold}${newversion:-unknown}${reset}"
echo
echo "${yellow}downloading latest package:${reset} $latest"
echo "from: $pkg_url"

if ! curl -fSLsS "$pkg_url" -o "$pkg_file"
then

    echo "${red}failed to download $pkg_url${reset}"
    exit 1

fi

echo "${green}download complete → $pkg_file${reset}"

# extract and copy new binaries
tar -xf "$pkg_file"

for f in glftpd-LNX*/bin/*
do

    bn=$(basename "$f")
    if [[ "$bn" != "dated.sh" ]]
    then

        cp -rf "$f" "$glroot/bin"

    fi

done

# copy docs
cp -r glftpd-LNX*/docs "$glroot"/ 2>/dev/null

# patch sources safely
if [[ -f "$glroot/bin/sources/olddirclean2.c" ]]
then

    sed -i 's/MAXDIRLOGSIZE 10000/MAXDIRLOGSIZE 1000000/' "$glroot/bin/sources/olddirclean2.c"

fi

if [[ -f "$glroot/bin/sources/compile.sh" ]]
then

    # comment any line starting with: echo "You
    sed -i 's/^echo "You/#&/' "$glroot/bin/sources/compile.sh"

fi

# clean extracted dirs
rm -rf glftpd-LNX* 2>/dev/null

# recompile
if [[ -d "$glroot/bin/sources" ]]
then

    cd "$glroot/bin/sources" && ./compile.sh

fi

# fix perms if helper exists
if [[ -x "$glroot/bin/update_perms.sh" ]]
then

    cd "$glroot/bin" && ./update_perms.sh

fi

# show changelog
echo
echo "${cyan}changelog:${reset} $changelog"
if command -v less >/dev/null
then

    curl -fsSL "$changelog" | ${PAGER:-less}

else

    curl -fsSL "$changelog"

fi

echo
echo "${green}upgrade completed.${reset}"
