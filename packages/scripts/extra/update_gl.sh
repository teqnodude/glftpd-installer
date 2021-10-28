#!/bin/bash
VER=1.0
#--[ Settings ]-------------------------------------------------#

glroot=/glftpd
sourcedir=$glroot/backup/sources

#--[ Script Start ]---------------------------------------------#

latest=`lynx --dump https://glftpd.io | grep "latest stable version" | cut -d ":" -f2 | sed -e 's/20[1-9][0-9].*//' -e 's/^  //' -e 's/^v//' | tr "[:space:]" "_" | sed 's/_$//'`
version=`/glftpd/bin/glftpd-full-static | grep -o "[3-6][2-4]BiT" | sed 's/BiT//'`
[ "$version" = "32" ] && version="86"
[ ! -d $sourcedir ] && mkdir $sourcedir
cd $sourcedir
for x in `ls | grep "glftpd-LNX*"`; do rm -rf $x ; done
wget -q https://glftpd.io/files/`wget -q -O - https://glftpd.io/files/ | grep "LNX-$latest.*x$version.*" | grep -o -P '(?=glftpd).*(?=.tgz">)' | head -1`.tgz
tar -xf glftpd-LNX*

for x in `ls glftpd-LNX*/bin`
do
    if [ "$x" != "dated.sh" ]
    then
        cp -rf glftpd-LNX*/bin/$x $glroot/bin
    fi
done

sed -i 's/MAXDIRLOGSIZE 10000/MAXDIRLOGSIZE 1000000/' $glroot/bin/sources/olddirclean2.c
sed -i 's/echo "You/#echo "You/' $glroot/bin/sources/compile.sh
cd $glroot/bin/sources && ./compile.sh 
[ -e "$glroot/bin/update_perms.sh" ] && cd $glroot/bin && ./update_perms.sh

exit 0
