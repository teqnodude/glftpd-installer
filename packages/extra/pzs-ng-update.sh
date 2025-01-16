#!/bin/bash
VER=1.01
#---------------------------------------------------------------#
# pzs-ng updater by Teqno                                       #
#                                                               #
# It takes a backup of the current zsconfig.h and download the  #
# latest version available from github and install it           #
#                                                               #
#--[ Script Start ]---------------------------------------------#

cp pzs-ng/zipscript/conf/zsconfig.h .
rm -r pzs-ng
git clone https://github.com/glftpd/pzs-ng.git
cp zsconfig.h pzs-ng/zipscript/conf && rm zsconfig.h
cd pzs-ng && ./configure -q && make -s && make -s install
chmod u+s /glftpd/bin/cleanup
chmod u+s /glftpd/bin/sed
sed -i 's|$glpath/bin/libcopy.sh|# $glpath/bin/libcopy.sh|' ng-install.sh

exit 0
