#!/bin/bash
VER=1.0
#--[ Settings ]-------------------------------------------------#

glroot=/glftpd
sourcedir=$glroot/backup/sources

#--[ Script Start ]---------------------------------------------#

[ ! -d $glroot ] && echo "glFTPd doesn't seem to be installed in $glroot" && exit 0

curversion=`/glftpd/bin/glftpd | grep glFTPd | cut -d ' ' -f2`
newversion=`lynx --dump https://glftpd.io | grep "latest version" | cut -d ":" -f2 | cut -d ' ' -f3 | sed 's/v//'`

[ "$curversion" = "$newversion" ] && echo "You already got the latest non BETA version" && exit 0

latest=`curl -s https://glftpd.io | grep "/files/glftpd" | grep -v BETA | grep -o "glftpd-LNX.*.tgz" | head -1`
changelog=https://glftpd.io/files/docs/UPGRADING

[ ! -d $sourcedir ] && mkdir -p $sourcedir
cd $sourcedir
version=`lscpu | grep Architecture | awk '{print $2}'`
case $version in
    i686)
        version="32"
        latest=`echo $latest | sed 's/x64/x86/'`
        wget -q https://glftpd.io/files/$latest
        ;;
    x86_64)
        version="64"
        wget -q https://glftpd.io/files/$latest
        ;;
esac

tar -xf glftpd-LNX*

for x in `ls glftpd-LNX*/bin`
do
    if [ "$x" != "dated.sh" ]
    then
        cp -rf glftpd-LNX*/bin/$x $glroot/bin
    fi
done

cp -rf glftpd-LNX*/docs $glroot
sed -i 's/MAXDIRLOGSIZE 10000/MAXDIRLOGSIZE 1000000/' $glroot/bin/sources/olddirclean2.c
sed -i 's/echo "You/#echo "You/' $glroot/bin/sources/compile.sh
rm -rf glftpd-LNX*
cd $glroot/bin/sources && ./compile.sh
[ -e "$glroot/bin/update_perms.sh" ] && cd $glroot/bin && ./update_perms.sh
lynx --dump $changelog | less

exit 0
