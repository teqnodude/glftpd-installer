#!/bin/bash
VER=1.22
#--[ Info ]-----------------------------------------------------
#
# glFTPd Upgrader
# - Fetch latest non-preview release from GitHub releases
# - Copy binaries + docs, patch sources, recompile, fix perms
# - Clean up stale extracted glftpd-* dirs under $srcdir
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

if ! command -v jq >/dev/null 2>&1
then

    echo "${red}'jq' is required but not installed.${reset}"
    echo "Please install it (e.g. 'apt install jq' or 'pkg install jq') and re-run this script."
    exit 1

fi

curversion=$("$glroot/bin/glftpd" 2>/dev/null | grep -Eo 'glFTPd[[:space:]]+[0-9][^ ]*' | awk '{print $2}')

api=https://api.github.com/repos/glftpd/glftpd/releases

# Fetch releases (JSON). Unauthenticated: 60 req/h per IP.
json=$(curl -fsSL -H 'Accept: application/vnd.github+json' "$api" || true)
if [[ -z "$json" ]]
then

    echo
    echo "${red}no available release data from GitHub, aborting upgrade.${reset}"
    exit 1

fi

# Pick the newest non-preview release.
#  - skip drafts and prereleases (dev/preview builds are flagged prerelease:true)
#  - belt-and-suspenders: also skip any tag/name containing dev/preview
# Releases come back newest-first, so the first match wins.
release_tag=$(printf "%s" "$json" | jq -r '
    .[]
    | select(.draft == false and .prerelease == false)
    | select((.tag_name + " " + .name) | test("dev|preview"; "i") | not)
    | .tag_name
' | head -1)

if [[ -z "$release_tag" || "$release_tag" == "null" ]]
then

    echo "${red}could not determine the latest non-preview release, aborting.${reset}"
    exit 1

fi

# Stable tag is bare (e.g. "2.17a"), so use it verbatim for comparison.
newversion="$release_tag"

if [[ -z "$newversion" ]]
then

    echo "${red}could not determine version from tag '$release_tag', aborting.${reset}"
    exit 1

fi

# Select the architecture-specific tarball asset.
# Actual asset names look like:
#   glftpd-2.17a-2.17a-df4a994-linux-x64-binaries.tgz
#   glftpd-2.17a-2.17a-df4a994-fbsd-x64-binaries.tgz
arch=$(uname -m)
case "$arch" in

x86_64)

    asset_pattern="-linux-x64-binaries\\.tgz$"

    ;;

i386|i486|i586|i686)

    echo "${red}no 32-bit binaries are published on GitHub (only linux-x64 / fbsd-x64); aborting.${reset}"
    exit 1

    ;;

*)

    echo "${red}unsupported architecture: $arch${reset}"
    exit 1

    ;;

esac

asset_url=$(printf "%s" "$json" | jq -r --arg tag "$release_tag" --arg pat "$asset_pattern" '
    .[]
    | select(.tag_name == $tag)
    | .assets[]
    | select(.name | test($pat; "i"))
    | .browser_download_url
' | head -1)

if [[ -z "$asset_url" || "$asset_url" == "null" ]]
then

    echo "${red}no Linux x64 tarball asset found for release $release_tag, aborting.${reset}"
    exit 1

fi

if [[ -n "$curversion" && -n "$newversion" && "$curversion" = "$newversion" ]]
then

    echo "${green}you already have the latest non-preview version ($curversion).${reset}"
    exit 0

fi

# prep download dir
if [[ ! -d "$srcdir" ]]
then

    mkdir -p "$srcdir"

fi
cd "$srcdir" || exit 1

# Clean up stale extracted glftpd-* dirs left over from previous runs.
# Only directories (not the .tgz packages) are removed, and only ones
# matching the glftpd- prefix; anything else is left untouched.
shopt -s nullglob
stale_dirs=("$srcdir"/glftpd-*/)
shopt -u nullglob
if (( ${#stale_dirs[@]} > 0 ))
then

    echo "${yellow}cleaning up stale extracted dirs:${reset}"
    for d in "${stale_dirs[@]}"
    do
        echo "  removing $d"
        rm -rf "$d"
    done

fi

latest=$(basename "$asset_url")
pkg_file="$srcdir/$latest"

# UPGRADING notes are published as the UPGRADING.txt asset.
changelog=$(printf "%s" "$json" | jq -r --arg tag "$release_tag" '
    .[]
    | select(.tag_name == $tag)
    | .assets[]
    | select(.name == "UPGRADING.txt")
    | .browser_download_url
' | head -1)
if [[ -z "$changelog" || "$changelog" == "null" ]]
then
    changelog="https://raw.githubusercontent.com/glftpd/glftpd/$release_tag/UPGRADING.txt"
fi

echo "${cyan}current version:${reset}   ${bold}${curversion:-unknown}${reset}"
echo "${cyan}available version:${reset} ${bold}${newversion:-unknown}${reset}"
echo
echo "${yellow}downloading latest package:${reset} $latest"
echo "from: $asset_url"

if ! curl -fSLsS "$asset_url" -o "$pkg_file"
then

    echo "${red}failed to download $asset_url${reset}"
    exit 1

fi

echo "${green}download complete → $pkg_file${reset}"

# extract
tar -xf "$pkg_file"

# determine the actual top-level directory (upstream may rename it)
first=$(tar -tzf "$pkg_file" | head -1)
PK1DIR="${first%%/*}"
PK1DIR="${PK1DIR#./}"
if [[ -z "$PK1DIR" || "$PK1DIR" == "." || ! -d "$PK1DIR" ]]
then
    echo "${red}could not determine top-level directory in $pkg_file${reset}"
    exit 1
fi

# sanity check: it must look like a glftpd tree
if [[ ! -d "$PK1DIR/bin" ]]
then
    echo "${red}$PK1DIR/bin not found after extraction; aborting${reset}"
    exit 1
fi

# copy new binaries
shopt -s nullglob
bins=("$PK1DIR"/bin/*)
shopt -u nullglob
if (( ${#bins[@]} == 0 ))
then
    echo "${red}no binaries found in $PK1DIR/bin; aborting${reset}"
    exit 1
fi
for f in "${bins[@]}"
do
    bn=$(basename "$f")
    if [[ "$bn" != "dated.sh" ]]
    then
        cp -rf "$f" "$glroot/bin"
    fi
done

# copy docs if the tarball ships them
cp -r "$PK1DIR"/docs "$glroot"/ 2>/dev/null

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

# clean extracted dirs (the one we just used)
rm -rf "$PK1DIR"

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