#!/bin/bash
VER=1.04
#--[ Info ]-----------------------------------------------------
#
# pzs-ng updater by Teqno                                       
#                                                               
# It takes a backup of the current zsconfig.h and download the  
# latest version available from github and install it           
#                                                               
#--[ Script Start ]---------------------------------------------

cp pzs-ng/zipscript/conf/zsconfig.h .
rm -rf pzs-ng

git clone https://github.com/glftpd/pzs-ng.git

cp zsconfig.h pzs-ng/zipscript/conf
rm -f zsconfig.h

cd pzs-ng && ./ng-install.sh

chmod u+s "$glroot/bin/cleanup"
chmod u+s "$glroot/bin/sed"


