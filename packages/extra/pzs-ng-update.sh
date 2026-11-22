#!/bin/bash
VER=1.05
#--[ Info ]-----------------------------------------------------
#
# pzs-ng updater by Teqno
#
# It takes a backup of the current zsconfig.h and downloads the
# latest version available from GitHub and installs it
#
#--[ Settings ]-------------------------------------------------

glroot="/glftpd"
pzsdir="$glroot/backup/pzs-ng"
zsconf="zipscript/conf/zsconfig.h"

#--[ Script Start ]---------------------------------------------

cp "$pzsdir/$zsconf" . || exit 1

rm -rf "$pzsdir" || exit 1

git clone https://github.com/glftpd/pzs-ng.git "$pzsdir" || exit 1

mv zsconfig.h "$pzsdir/$zsconf" || exit 1

cd "$pzsdir" && ./ng-install.sh || exit 1

chown root:root "$glroot/bin/cleanup" "$glroot/bin/sed" 2>/dev/null
chmod u+s "$glroot/bin/cleanup" "$glroot/bin/sed" 2>/dev/null