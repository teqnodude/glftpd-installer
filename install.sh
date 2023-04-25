#!/bin/bash
VER=10.4
clear

if [ ! `whoami` = "root" ] 
then 
    echo "The installer should be run as root"
    exit 0
fi

glroot="/glftpd"

if [ -d "$glroot" ]
then
    echo -n "The path you have chosen already exists, what would you like to do [D]elete it, [A]bort, [T]ry again, [I]gnore? " ; read reply
    case $reply in
	[dD]*) rm -rf "$glroot" ;;
	[tT]*) glroot="./"; continue ;;
	[iI]*) ;;
	*) echo "Aborting."; exit 1 ;;
    esac
fi

mkdir -p "$glroot"
if [ ! -d ".tmp" ]
then
    mkdir .tmp
fi
clear

echo "Welcome to the glFTPD installer v$VER"
echo
echo "Disclaimer:" 
echo "This software is used at your own risk!"
echo "The author of this installer takes no responsibility for any damage done to your system."
echo
echo -n "Have you read and installed the Requirements in README.MD ? [Y]es [N]o, default N : " ; read requirement
echo
case $requirement in
    [Yy]) ;;
    [Nn]) rm -r /glftpd && rm -r .tmp ; exit 1 ;;
    *) rm -r /glftpd && rm -r .tmp ; exit 1 ;;
esac

if [ "`echo $PATH | grep /usr/sbin | wc -l`" = 0 ]
then 
    echo "/usr/sbin not found in environmental PATH" 
    echo "Default PATH should be : /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    echo "Current PATH is : `echo $PATH`"
    echo "Correcting PATH"
    export PATH=$PATH:/usr/sbin
    echo "Done"
    echo
fi

rootdir=`pwd`
cache="$rootdir/install.cache"

# clean up comments and trailing spaces in install.cache to avoid problems with unattended installation
if [ -f "$cache" ]
then
    sed -i -e 's/" #.*/"/g' -e 's/^#.*//g' -e '/^\s*$/d' -e 's/[ \t]*$//' $cache
fi

function start
{
    echo "--------[ Server configuration ]--------------------------------------"
    echo
    if [[ -f "$cache" && "`grep -w "sitename" $cache | wc -l`" = 1 ]]
    then
	sitename=`grep -w "sitename" $cache | cut -d "=" -f2 | tr -d "\""`
	return
    fi
	
    while [[ -z $sitename ]]
    do
	echo -n "Please enter the name of the site, without space : " ; read sitename
    done
	
    sitename="`echo $sitename | sed 's/ /_/g'`"
	
    if [ ! -f "$cache" ]
    then
	echo sitename=\"$sitename\" > $cache
    fi
}

function port
{
    if [[ -f "$cache" && "`grep -w "port" $cache | wc -l`" = 1 ]]
    then
	port=`grep -w "port" $cache | cut -d "=" -f2 | tr -d "\""`
    else
	echo -n "Please enter the port number for your site, default 2010 : " ; read port
	
	if [ "$port" = "" ] 
	then
	    port="2010"
	fi
		
	if [[ -f "$cache" && "`grep -w "port=" $cache | wc -l`" = 0 ]]
	then
	    echo port=\"$port\" >> $cache
	fi
    fi
}

function version
{
    echo -n "Downloading relevant packages, please wait...                   "
    latest=`lynx --dump https://glftpd.io | grep "latest stable version" | cut -d ":" -f2 | sed -e 's/20[1-9][0-9].*//' -e 's/^  //' -e 's/^v//' | tr -d "[:space:]"`
    version=`lscpu | grep Architecture | tr -s ' ' | cut -d ' ' -f2`
    case $version in
	i686)
	    version="86"
	    cd packages && wget -q https://glftpd.io/files/`wget -q -O - https://glftpd.io/files/ | grep -v "BETA" | grep "LNX-$latest.*x$version.*" | grep -o -P '(?=glftpd).*(?=.tgz">)' | head -1`.tgz && cd ..
	    PK1="`ls packages| grep glftpd-LNX | grep x$version`"
	    PK1DIR="`ls packages | grep glftpd-LNX | grep x$version | sed 's|.tgz||'`"
	    ;;
	x86_64)
	    version="64"
	    cd packages && wget -q https://glftpd.io/files/`wget -q -O - https://glftpd.io/files/ | grep -v "BETA" | grep "LNX-$latest.*x$version.*" | grep -o -P '(?=glftpd).*(?=.tgz">)' | head -1`.tgz && cd ..
	    PK1="`ls packages | grep glftpd-LNX | grep x$version`"
	    PK1DIR="`ls packages | grep glftpd-LNX | grep x$version | sed 's|.tgz||'`"
	    ;;
    esac
	
    PK2DIR="pzs-ng"
    PK3DIR="eggdrop"
    UP="tar xf"
    BOTU="sitebot"
    CHKGR=`grep -w "glftpd" /etc/group | cut -d ":" -f1`
    CHKUS=`grep -w "sitebot" /etc/passwd | cut -d ":" -f1`
	
    if [ "$CHKGR" != "glftpd" ] 
    then
        #echo "Group glftpd added"
        groupadd glftpd -g 199
    fi
	
    if [ "$CHKUS" != "sitebot" ] 
    then
    	#echo "User $BOTU added"
	useradd -d $glroot/sitebot -m -g glftpd -s /bin/bash $BOTU
	chfn -f 0 -r 0 -w 0 -h 0 $BOTU
    fi 
	
    cd packages
    #echo -n "Extracting the Source files, please wait...                     "
    $UP $PK1 && rm $PK1
    git clone https://github.com/glftpd/pzs-ng >/dev/null 2>&1
    git clone https://github.com/eggheads/eggdrop >/dev/null 2>&1
    echo -e "[\e[32mDone\e[0m]"
    echo
    mkdir source
    cp -R scripts source
    cd ..
    
    if [[ -f "$cache" && "`grep -w "version=" $cache | wc -l`" = 0 ]]
    then
    	echo version=\"$version\" >> $cache
    fi
    cp -f $rootdir/packages/data/cleanup.sh $rootdir
}

function device_name
{
    if [[ -f "$cache" && "`grep -w "device" $cache | wc -l`" = 1 ]]
    then
    	device=`grep -w "device" $cache | cut -d "=" -f2 | tr -d "\""`
    	echo "Sitename           = $sitename"
    	echo "Port               = $port"
    	echo "glFTPD version     = $version" 
    	echo "Device             = $device"
    else
    	echo "Please enter which device you will use for the $glroot/site folder"
    	echo "eg /dev/sda1"
    	echo "eg /dev/mapper/lvm-lvm"
    	echo "eg /dev/md0"
    	echo "Default: /dev/sda1"
    	echo -n "Device : " ; read device
    	echo
    
    	if [ "$device" = "" ] 
    	then
	    device="/dev/sda1"
	fi
	
    fi
    cp packages/scripts/tur-space/tur-space.conf packages/scripts/tur-space/tur-space.conf.new
    echo "[TRIGGER]\n" >> packages/scripts/tur-space/tur-space.conf.new
    echo "TRIGGER=$device:100000:200000" >> packages/scripts/tur-space/tur-space.conf.new
    echo "" >> packages/scripts/tur-space/tur-space.conf.new
    echo "[INCOMING]" >> packages/scripts/tur-space/tur-space.conf.new
    
    if [[ -f "$cache" && "`grep -w "device=" $cache | wc -l`" = 0 ]]
    then
    	echo device=\"$device\" >> $cache
    fi
}

function channel
{
    if [[ -f "$cache" && "`grep -w "ircserver" $cache | wc -l`" = 1 ]]
    then
        ircserver=`grep -w ircserver $cache | cut -d "=" -f2 | tr -d "\""`
        echo -n "IRC server         = $ircserver"
    fi
	
    if [[ -f "$cache" && "`grep -w "channelnr" $cache | wc -l`" = 1 ]]
    then
	echo
	channelnr=`grep -w channelnr $cache | cut -d "=" -f2 | tr -d "\""`
    else
	while [[ -z $channelnr || $channelnr -gt 15 ]]
	do
	    echo -n "How many channels do you require the bot to be in (max 15)? : " ; read channelnr
	done
    fi
	
    counta=0
	
    if [[ -f "$cache" && "`grep -w "channelnr=" $cache | wc -l`" = 0 ]]
    then
	echo channelnr=\"$channelnr\" >> $cache
    fi
	
    while [ $counta -lt $channelnr ] 
    do
	chanpassword=""
	if [[ -f "$cache" && "`grep -w "channame$((counta+1))" $cache | wc -l`" = 1 ]]
	then
	    channame=`grep -w "channame$((counta+1))" $cache | cut -d "=" -f2 | tr -d "\"" | cut -d " " -f1`
	    echo "Channel $((counta+1))          = $channame"
	else	
	    echo "Include # in the name of channel ie #main"
	    while [[ -z $channame ]] 
	    do
		echo -n "Channel $((counta+1)) is : " ; read channame
	    done
	fi
		
	if [[ -f "$cache" && "`grep -w "channame$((counta+1))" $cache | wc -l`" = 1 ]]
	then
	    chanpasswd=`grep -w "channame$((counta+1))" $cache | cut -d "=" -f2 | tr -d "\"" | cut -d " " -f2`
	    echo "Requires password  = $chanpasswd"
	else
	    echo -n "Channel password ? [Y]es [N]o, default N : " ; read chanpasswd
	fi
		
	case $chanpasswd in
	    [Yy])
                if [[ -f "$cache" && "`grep -w "announcechannels" $cache | wc -l`" = 1 ]]
                then
        	    echo "Channel mode       = password protected"
                fi
		
		if [[ -f "$cache" && "`grep -w "channame$((counta+1))" $cache | wc -l`" = 1 ]]
		then
		    chanpassword=`grep -w "channame$((counta+1))" $cache | cut -d "=" -f2 | tr -d "\"" | cut -d " " -f3`
		    echo "Channel password   = $chanpassword"
		else
		    while [[ -z $chanpassword ]]
		    do
			echo -n "Enter the channel password : " ; read chanpassword
		    done
		fi
		echo "channel set $channame chanmode {+ntpsk $chanpassword}" >> $rootdir/.tmp/bot.chan.tmp
		echo "channel add $channame {" >> $rootdir/.tmp/eggchan
		echo "idle-kick 0" >> $rootdir/.tmp/eggchan
		echo "stopnethack-mode 0" >> $rootdir/.tmp/eggchan
		echo "flood-chan 0:0" >> $rootdir/.tmp/eggchan
		echo "flood-join 0:0" >> $rootdir/.tmp/eggchan
		echo "flood-ctcp 0:0" >> $rootdir/.tmp/eggchan
		echo "flood-kick 0:0" >> $rootdir/.tmp/eggchan
		echo "flood-deop 0:0" >> $rootdir/.tmp/eggchan
		echo "flood-nick 0:0" >> $rootdir/.tmp/eggchan
		echo "aop-delay 0:0" >> $rootdir/.tmp/eggchan
		echo "chanmode \"+ntsk $chanpassword\"" >> $rootdir/.tmp/eggchan
		echo "}" >> $rootdir/.tmp/eggchan
		echo "" >> $rootdir/.tmp/eggchan
		echo $channame >> $rootdir/.tmp/channels
		
		if [[ -f "$cache" && "`grep -w "channame$((counta+1))=" $cache | wc -l`" = 0 ]]
		then
		    echo "channame$((counta+1))=\"$channame $chanpasswd $chanpassword\"" >> $cache
		fi
		;;
	    [Nn])
		if [[ -f "$cache" && "`grep -w "announcechannels" $cache | wc -l`" = 1 ]]
		then
		    echo "Channel mode       = invite only"
		fi

		echo "channel set $channame chanmode {+ntpsi}" >> $rootdir/.tmp/bot.chan.tmp
		echo "channel add $channame {" >> $rootdir/.tmp/eggchan
		echo "idle-kick 0" >> $rootdir/.tmp/eggchan
		echo "stopnethack-mode 0" >> $rootdir/.tmp/eggchan
		echo "flood-chan 0:0" >> $rootdir/.tmp/eggchan
		echo "aop-delay 0:0" >> $rootdir/.tmp/eggchan
		echo "chanmode +ntsi" >> $rootdir/.tmp/eggchan
		echo "}" >> $rootdir/.tmp/eggchan
		echo "" >> $rootdir/.tmp/eggchan
		echo $channame >> $rootdir/.tmp/channels
			
		if [[ -f "$cache" && "`grep -w "channame$((counta+1))=" $cache | wc -l`" = 0 ]]
		then
		    echo "channame$((counta+1))=\"$channame n nopass\"" $cache
		fi
		;;
	    *)
                if [[ -f "$cache" && "`grep -w "announcechannels" $cache | wc -l`" = 1 ]]
                then
                    echo "Channel mode       = invite only"
                fi
		echo "channel set $channame chanmode {+ntpsi}" >> $rootdir/.tmp/bot.chan.tmp
		echo "channel add $channame {" >> $rootdir/.tmp/eggchan
		echo "idle-kick 0" >> $rootdir/.tmp/eggchan
		echo "stopnethack-mode 0" >> $rootdir/.tmp/eggchan
		echo "flood-chan 0:0" >> $rootdir/.tmp/eggchan
		echo "aop-delay 0:0" >> $rootdir/.tmp/eggchan
		echo "chanmode +ntsi" >> $rootdir/.tmp/eggchan
		echo "}" >> $rootdir/.tmp/eggchan
		echo "" >> $rootdir/.tmp/eggchan
		echo $channame >> $rootdir/.tmp/channels
			
		if [[ -f "$cache" && "`grep -w "channame$((counta+1))=" $cache | wc -l`" = 0 ]]
		then
		    echo "channame$((counta+1))=\"$channame n nopass\"" >> $cache
		fi
		;;
	esac
	channame=""
	chanpasswd=""
	let counta=counta+1
    done

}

function announce
{
    sed -i -e :a -e N -e 's/\n/ /' -e ta $rootdir/.tmp/channels
    if [[ -f "$cache" && "`grep -w "announcechannels" $cache | wc -l`" = 1 ]]
    then
    	announcechannels=`grep -w "announcechannels" $cache | cut -d "=" -f2 | tr -d "\""`
	echo "Announce channels  = $announcechannels"
    else
	echo -n "Which should be announce channels,  default: `cat $rootdir/.tmp/channels` : " ; read announcechannels
    fi
	
    if [ "$announcechannels" = "" ] 
    then
    	announcechannels=`cat $rootdir/.tmp/channels`
	cat $rootdir/.tmp/channels > $rootdir/.tmp/dzchan

	if [[ -f "$cache" && "`grep -w "announcechannels=" $cache | wc -l`" = 0 ]]
	then
	    echo "announcechannels=\"`cat $rootdir/.tmp/channels`\"" >> $cache
	fi
		
    else 
    	echo "$announcechannels" > $rootdir/.tmp/dzchan
	
	if [[ -f "$cache" && "`grep -w "announcechannels=" $cache | wc -l`" = 0 ]]
	then
	    echo "announcechannels=\"$announcechannels\"" >> $cache
	fi
	
    fi
}

function opschan
{
    if [[ -f "$cache" && "`grep -w "channelops" $cache | wc -l`" = 1 ]]
    then
    	channelops=`grep -w "channelops" $cache | cut -d "=" -f2 | tr -d "\""`
	echo "Ops channel        = $channelops"
    else
	echo "Channels: `cat $rootdir/.tmp/channels`"
	while [[ -z $channelops ]]
	do
	    echo -n "Which of these channels as ops channel ? : " ; read channelops
	done
    fi
	
    echo "$channelops" > $rootdir/.tmp/dzochan
	
    if [[ -f "$cache" && "`grep -w "channelops=" $cache | wc -l`" = 0 ]]
    then
	echo "channelops=\"$channelops\"" >> $cache
    fi
	
    rm $rootdir/.tmp/channels
}

function ircnickname
{
    if [[ -f "$cache" && "`grep -w "ircnickname" $cache | wc -l`" = 1 ]]
    then
	ircnickname=`grep -w "ircnickname" $cache | cut -d "=" -f2 | tr -d "\""`
	echo "Nickname           = $ircnickname"
    else	
	while [[ -z $ircnickname ]] 
	do
	    echo -n "What is your nickname on irc ? ie l337 : " ; read ircnickname
	done
    fi
	
    if [[ -f "$cache" && "`grep -w "ircnickname=" $cache | wc -l`" = 0 ]]
    then
	echo "ircnickname=\"$ircnickname\"" >> $cache
    fi
}

## how many sections
function section_names
{
    if [[ -f "$cache" && "`grep -w "sections" $cache | wc -l`" = 1 ]]
    then
	sections=`grep -w "sections" $cache | cut -d "=" -f2 | tr -d "\""`
    else
	echo
	while [[ ! $sections =~ ^[0-9]+$ ]]
	do
	    echo -n "How many sections do you require for your site? : " ; read sections
	done
	echo
    fi
	
    cp packages/scripts/tur-rules/tur-rules.sh.org packages/scripts/tur-rules/tur-rules.sh
    packages/scripts/tur-rules/rulesgen.sh GENERAL
    cp packages/scripts/tur-autonuke/tur-autonuke.conf.org packages/scripts/tur-autonuke/tur-autonuke.conf
    cp packages/data/dated.sh.org $rootdir/.tmp/dated.sh
    counta=0
    rulecount=2	
    if [[ -f "$cache" && "`grep -w "sections=" $cache | wc -l`" = 0 ]]
    then
	echo sections=\"$sections\" >> $cache
    fi
	
    while [ $counta -lt $sections ] 
    do
	section_generate
	let counta=counta+1
    done
}

## which Sections
function section_generate
{
    if [[ -f "$cache" && "`grep -w "section$((counta+1))" $cache | wc -l`" = 1 ]]
    then
	section=`grep -w "section$((counta+1))" $cache | cut -d "=" -f2 | tr -d "\""`
    else
	if [ `echo $((counta+1))` = 1 ]
	then
	    echo "Recommended section names:"
	    echo "0DAY ANIME APPS DOX EBOOKS FLAC GAMES MBLURAY MP3 NSW PS4 PS5 TV-1080 TV-2160"
	    echo "TV-720 TV-HD TV-NL X264 X264-1080 X264-720 X265-2160 XVID XXX XXX-PAYSITE"
	    echo
	fi
        echo -n "Section $((counta+1)) is : " ; read section
    fi

    while [[ -z "$section" ]]
    do
        echo -n "Section $((counta+1)) is : " ; read section
    done

    if [[ -f "$cache" && "`grep -w "section$((counta+1))dated" $cache | wc -l`" = 1 ]]
    then
	sectiondated=`grep -w "section$((counta+1))dated" $cache | cut -d "=" -f2 | tr -d "\""`
    else
        echo -n "Is section ${section^^} a dated section, [Y]es [N]o, default N : " ; read sectiondated
    fi
    writ
}

## TMP_dZSbot.tcl_Config
function writ
{
    section=${section^^}
    if [ "$sectiondated" = "y" ]
    then
	mkdir -pm 777 $rootdir/.tmp/site/$section
	echo "$section " > $rootdir/.tmp/.section && cat $rootdir/.tmp/.section >> $rootdir/.tmp/.sections
	cat $rootdir/.tmp/.sections | awk -F '[" "]+' '{printf $0}' > $rootdir/.tmp/.validsections
	#echo "set statsection($counta) \"$section\"" >> $rootdir/.tmp/dzsstats
	echo "set paths($section)				\"/site/$section/*/*\"" >> $rootdir/.tmp/dzsrace
	echo "set chanlist($section) 			\"$announcechannels\"" >> $rootdir/.tmp/dzschan
	#echo "#stat_section 	$section	/site/$section/* no" >> $rootdir/.tmp/glstat
	echo "section.$section.name=$section" >> $rootdir/.tmp/footools
	echo "section.$section.dir=/site/$section/YYYY-MM-DD" >> $rootdir/.tmp/footools
	echo "section.$section.gl_credit_section=0" >> $rootdir/.tmp/footools
	echo "section.$section.gl_stat_section=0" >> $rootdir/.tmp/footools
	sed -i "s/\bDIRS=\"/DIRS=\"\n\/site\/$section\/\$today/" packages/scripts/tur-autonuke/tur-autonuke.conf
	sed -i "s/\bDIRS=\"/DIRS=\"\n\/site\/$section\/\$yesterday/" packages/scripts/tur-autonuke/tur-autonuke.conf
	echo "INC$section=$device:$glroot/site/$section:" >> packages/scripts/tur-space/tur-space.conf.new
	echo "$glroot/site/$section" >> $rootdir/.tmp/.fullpath
	echo "/site/$section/%Y-%m-%d/ " >> $rootdir/.tmp/.cleanup_dated
	if [ "$section" != "0DAY" ] 
	then
	    echo "/site/$section/ " > $rootdir/.tmp/.section && cat $rootdir/.tmp/.section >> $rootdir/.tmp/.tempdated
	    cat $rootdir/.tmp/.tempdated | awk -F '[" "]+' '{printf $0}' > $rootdir/.tmp/.path
	fi

	if [[ -f "$cache" && "`grep -w "section$((counta+1))=" $cache | wc -l`" = 0 ]]
	then
	    echo "section$((counta+1))=\"$section\"" >> $cache
	fi

        if [[ -f "$cache" && "`grep -w "section$((counta+1))dated=" $cache | wc -l`" = 0 ]]
        then
            echo "section$((counta+1))dated=\"y\"" >> $cache
        fi

	
    else
	
	mkdir -pm 777 $rootdir/.tmp/site/$section
	echo "$section " > $rootdir/.tmp/.section && cat $rootdir/.tmp/.section >> $rootdir/.tmp/.sections
	cat $rootdir/.tmp/.sections | awk -F '[" "]+' '{printf $0}' > $rootdir/.tmp/.validsections
	#echo "set statsection($counta) \"$section\"" >> $rootdir/.tmp/dzsstats
	echo "set paths($section) 			\"/site/$section/*\"" >> $rootdir/.tmp/dzsrace
	echo "set chanlist($section) 			\"$announcechannels\"" >> $rootdir/.tmp/dzschan
	echo "/site/$section/ " > $rootdir/.tmp/.section && cat $rootdir/.tmp/.section >> $rootdir/.tmp/.temp
	cat $rootdir/.tmp/.temp | awk -F '[" "]+' '{printf $0}' > $rootdir/.tmp/.nodatepath
	#echo "#stat_section 	$section /site/$section/* no" >> $rootdir/.tmp/glstat
	echo "section.$section.name=$section" >> $rootdir/.tmp/footools
	echo "section.$section.dir=/site/$section" >> $rootdir/.tmp/footools
	echo "section.$section.gl_credit_section=0" >> $rootdir/.tmp/footools
	echo "section.$section.gl_stat_section=0" >> $rootdir/.tmp/footools
	sed -i "s/\bDIRS=\"/DIRS=\"\n\/site\/$section/" packages/scripts/tur-autonuke/tur-autonuke.conf
	echo "INC$section=$device:$glroot/site/$section:" >> packages/scripts/tur-space/tur-space.conf.new
	echo "$glroot/site/$section" >> $rootdir/.tmp/.fullpath
		
	if [[ -f "$cache" && "`grep -w "section$((counta+1))=" $cache | wc -l`" = 0 ]]
	then
	    echo "section$((counta+1))=\"$section\"" >> $cache
	fi

        if [[ -f "$cache" && "`grep -w "section$((counta+1))dated=" $cache | wc -l`" = 0 ]]
        then
            echo "section$((counta+1))dated=\"n\"" >> $cache
        fi
	
    fi
    echo "$section :" >> site.rules
    if [ "$rulecount" -ge 10 ]
    then
	echo "$rulecount.1 Main language: English/Nordic................................................................................[NUKE 5X]" >> site.rules
	echo >> site.rules
	sed -i "s/sections=\"/sections=\"\n$section:^$rulecount./" packages/scripts/tur-rules/tur-rules.sh
    else
	echo "0$rulecount.1 Main language: English/Nordic................................................................................[NUKE 5X]" >> site.rules
	echo >> site.rules
	sed -i "s/sections=\"/sections=\"\n$section:^0$rulecount./" packages/scripts/tur-rules/tur-rules.sh
    fi
    rulecount=$((rulecount+1))
    echo "/site/REQUESTS/" >> $rootdir/.tmp/.nodatepath
}

## GLFTPD
function glftpd
{
    if [[ -f "$cache" && "`grep -w "eur0presystem" $cache | wc -l`" = 1 ]]
    then
	echo "Sections           = `cat $rootdir/.tmp/.validsections`"
    fi
    if [[ -f "$cache" && "`grep -w "router" $cache | wc -l`" = 1 ]]
    then
        echo "Router             = "`grep -w "router" $cache | cut -d "=" -f2 | tr -d "\""`
    fi
    if [[ -f "$cache" && "`grep -w "pasv_addr" $cache | wc -l`" = 1 ]]
    then
	echo "Passive address    = "`grep -w "pasv_addr" $cache | cut -d "=" -f2 | tr -d "\""`
    fi
    if [[ -f "$cache" && "`grep -w "pasv_ports" $cache | wc -l`" = 1 ]]
    then
        echo "Port range         = "`grep -w "pasv_ports" $cache | cut -d "=" -f2 | tr -d "\""`
    fi
    if [[ -f "$cache" && "`grep -w "psxcimdbchan" $cache | wc -l`" = 1 ]]
    then
        echo "IMDB trigger chan  = "`grep -w "psxcimdbchan" $cache | cut -d "=" -f2 | tr -d "\""`
    fi

    echo
    echo "--------[ Installation of software and scripts ]----------------------"
    packages/scripts/tur-rules/rulesgen.sh MISC
    cd packages
    echo
    echo -n "Installing glftpd, please wait...                               "
    echo "####### Here starts glFTPD scripts #######" >> /var/spool/cron/crontabs/root
    #cd $PK1DIR ; mv -f ../data/installgl.sh ./ ; ./installgl.sh >/dev/null 2>&1
    cd $PK1DIR && sed "s/changeme/$port/" ../data/installgl.sh.org > installgl.sh && chmod +x installgl.sh && ./installgl.sh >/dev/null 2>&1
    >$glroot/ftp-data/misc/welcome.msg
    echo -e "[\e[32mDone\e[0m]"
    cd ../data
    echo "##########################################################################" > glftpd.conf
    echo "# Server shutdown: 0=server open, 1=deny all but siteops, !*=deny all, etc" >> glftpd.conf
    echo "shutdown 1" >> glftpd.conf
    echo "#" >> glftpd.conf
    echo "sitename_long		$sitename" >> glftpd.conf
    echo "sitename_short		$sitename" >> glftpd.conf
    echo "email			root@localhost.org" >> glftpd.conf
    echo "login_prompt 		$sitename[:space:]Ready" >> glftpd.conf
    echo "mmap_amount     	100"  >> glftpd.conf
    echo "# SECTION		KEYWORD		DIRECTORY	SEPARATE CREDITS" >> glftpd.conf
    echo "stat_section		DEFAULT 	* 		no" >> glftpd.conf
    if [[ -f "$cache" && "`grep -w "router" $cache | wc -l`" = 1 ]]
    then
	router=`grep -w "router" $cache | cut -d "=" -f2 | tr -d "\""`
    else
	echo -n "Do you use a router ? [Y]es [N]o, default N : " ; read router
    fi
    case $router in
	[Yy])
	    wgetbinary=`which wget`
	    ipcheck="`$wgetbinary -qO- http://ipecho.net/plain ; echo`"
	    if [[ -f "$cache" && "`grep -w "pasv_addr" $cache | wc -l`" = 1 ]]
	    then
		pasv_addr=`grep -w "pasv_addr" $cache | cut -d "=" -f2 | tr -d "\""`
	    else	
		echo -n "Please enter the DNS or IP for the site, default $ipcheck : " ; read pasv_addr
	    fi
			
	    if [ "$pasv_addr" = "" ] 
	    then
		pasv_addr="$ipcheck"
	    fi
		
	    if [[ -f "$cache" && "`grep -w "pasv_ports" $cache | wc -l`" = 1 ]]
	    then
		pasv_ports=`grep -w "pasv_ports" $cache | cut -d "=" -f2 | tr -d "\""`
	    else
		echo -n "Please enter the port range for passive mode, default 6000-7000 : " ; read pasv_ports
	    fi
		
	    echo "pasv_addr		$pasv_addr	1" >> glftpd.conf
	    if [ "$pasv_ports" = "" ] 
	    then
	    	echo "pasv_ports		6000-7000" >> glftpd.conf
	    	pasv_ports="6000-7000"
	    else
		echo "pasv_ports		$pasv_ports" >> glftpd.conf
	    fi
	    ;;
	[Nn]) router=n ;;
	*) router=n ;;
    esac
	
    if [[ -f "$cache" && "`grep -w "router=" $cache | wc -l`" = 0 ]]
    then
	echo "router=\"$router\"" >> $cache
    fi
	
    if [[ -f "$cache" && "`grep -w "pasv_addr=" $cache | wc -l`" = 0 && "$pasv_addr" != "" ]]
    then
    	echo "pasv_addr=\"$pasv_addr\"" >> $cache
    fi
	
    if [[ -f "$cache" && "`grep -w "pasv_ports=" $cache | wc -l`" = 0 && "$pasv_addr" != "" ]]
    then
    	echo "pasv_ports=\"$pasv_ports\"" >> $cache
    fi
	
    #cat glstat >> glftpd.conf && rm glstat
    cat glfoot >> glftpd.conf && mv glftpd.conf $glroot/etc
    cp -f default.user $glroot/ftp-data/users
    echo "59 23 * * * 		`which chroot` $glroot /bin/cleanup >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
    echo "29 4 * * * 		`which chroot` $glroot /bin/datacleaner >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
    echo "*/10 * * * * 		$glroot/bin/incomplete-list-nuker.sh >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
    touch $glroot/ftp-data/logs/incomplete-list-nuker.log
    echo "0 1 * * *       	$glroot/bin/olddirclean2 -PD >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
    mv ../scripts/tur-space/tur-space.conf.new $glroot/bin/tur-space.conf
    cp ../scripts/tur-space/tur-space.sh $glroot/bin
    cp ../scripts/tur-precheck/tur-precheck.sh $glroot/bin
    cp ../scripts/tur-predircheck/tur-predircheck.sh $glroot/bin
    cp ../scripts/tur-predircheck_manager/tur-predircheck_manager.sh $glroot/bin
    cp ../scripts/tur-free/tur-free.sh $glroot/bin
    sed -i '/^SECTIONS/a '"TOTAL:$device" $glroot/bin/tur-free.sh
    sed -i "s/changeme/$sitename/" $glroot/bin/tur-free.sh
    gcc ../scripts/tur-predircheck/glftpd2/dirloglist_gl.c -o $glroot/bin/dirloglist_gl
    gcc -O2 ../scripts/tur-ftpwho/tur-ftpwho.c -o $glroot/bin/tur-ftpwho
    gcc ../scripts/tuls/tuls.c -o $glroot/bin/tuls
    rm -f $glroot/README
    rm -f $glroot/README.ALPHA
    rm -f $glroot/UPGRADING
    rm -f $glroot/changelog
    rm -f $glroot/LICENSE
    rm -f $glroot/LICENCE
    rm -f $glroot/glftpd.conf
    rm -f $glroot/installgl.debug
    rm -f $glroot/installgl.sh
    rm -f $glroot/glftpd.conf.dist
    rm -f $glroot/convert_to_2.0.pl
    rm -f /etc/glftpd.conf
    mv -f $glroot/create_server_key.sh $glroot/etc
    mv -f ../../site.rules $glroot/ftp-data/misc
    cp ../scripts/extra/incomplete-list.sh $glroot/bin
    cp ../scripts/extra/incomplete-list-nuker.sh $glroot/bin
    cp ../scripts/extra/incomplete-list-symlinks.sh $glroot/bin
    cp ../scripts/extra/lastlogin.sh $glroot/bin
    chmod 755 $glroot/site
    ln -s $glroot/etc/glftpd.conf /etc/glftpd.conf
    chmod 777 $glroot/ftp-data/msgs
    cp ../scripts/extra/update_perms.sh $glroot/bin
    cp ../scripts/extra/update_gl.sh $glroot/bin
    cp ../scripts/extra/imdb-scan.sh $glroot/bin
    cp ../scripts/extra/imdb-rescan.sh $glroot/bin
    cp ../scripts/extra/glftpd-version_check.sh $glroot/bin
    echo "0 18 * * *              $glroot/bin/glftpd-version_check.sh >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
    cp ../scripts/section-manager/section-manager.sh $glroot
    sed -i "s|changeme|$device|" $glroot/section-manager.sh
    cp ../scripts/imdbrating/imdbrating.sh $glroot/bin
    bins="bc du expr echo sed touch chmod chown pwd grep basename date mv bash find sort which xargs"
    for file in $bins
    do
        cp `which $file` $glroot/bin
    done
    if [ -f /etc/systemd/system/glftpd.socket ]
    then
        sed -i 's/#MaxConnections=64/MaxConnections=300/' /etc/systemd/system/glftpd.socket
        systemctl daemon-reload && systemctl restart glftpd.socket
    fi
}

## EGGDROP
function eggdrop
{
    if [[ -f "$cache" && "`grep -w "eur0presystem" $cache | wc -l`" = 0 ]]
    then
    	echo
    fi
    echo -n "Installing eggdrop, please wait...                              "
    cd ../$PK3DIR ; ./configure --prefix="$glroot/sitebot" >/dev/null 2>&1 && make config >/dev/null 2>&1  && make >/dev/null 2>&1 && make install >/dev/null 2>&1
    cd ../data
    cat egghead > eggdrop.conf
    cat $rootdir/.tmp/eggchan >> eggdrop.conf
    cat bot.chan | sed "s/changeme/$sitename/" > $glroot/sitebot/logs/bot.chan
    cat $rootdir/.tmp/bot.chan.tmp >> $glroot/sitebot/logs/bot.chan
    echo "set username 		\"$sitename\"" >> eggdrop.conf
    echo "set nick 		\"$sitename\"" >> eggdrop.conf
    echo "set altnick 		\"_$sitename\"" >> eggdrop.conf
    cat eggfoot >> eggdrop.conf
    sed -i "s/changeme/$ircnickname/" eggdrop.conf
    mv eggdrop.conf $glroot/sitebot
    cp botchkhead .botchkhead
    echo "botdir=$glroot/sitebot" >> .botchkhead
    echo "botscript=sitebot" >> .botchkhead
    echo "botname=$sitename" >> .botchkhead
    echo "userfile=./logs/bot.user" >> .botchkhead
    echo "pidfile=pid.$sitename" >> .botchkhead
    chmod 755 .botchkhead
    mv .botchkhead $glroot/sitebot/botchk
    cat botchkfoot >> $glroot/sitebot/botchk
    touch /var/spool/cron/crontabs/$BOTU
    echo "*/10 * * * *	$glroot/sitebot/botchk >/dev/null 2>&1" >> /var/spool/cron/crontabs/$BOTU
    chmod 777 $glroot/sitebot/logs
    rm -f $glroot/sitebot/BOT.INSTALL
    rm -f $glroot/sitebot/README
    rm -f $glroot/sitebot/eggdrop1.8
    rm -f $glroot/sitebot$glroot-tcl.old-TIMER
    rm -f $glroot/sitebot$glroot.tcl-TIMER
    rm -f $glroot/sitebot/eggdrop
    rm -f $glroot/sitebot/eggdrop-basic.conf
    rm -f $glroot/sitebot/scripts/CONTENTS
    rm -f $glroot/sitebot/scripts/autobotchk
    rm -f $glroot/sitebot/scripts/botchk
    rm -f $glroot/sitebot/scripts/weed
    ln -s $glroot/sitebot/`ls $glroot/sitebot | grep eggdrop-` $glroot/sitebot/sitebot
    chmod 666 $glroot/etc$glroot.conf
    mkdir -pm 777 $glroot/site/PRE/SiteOP $glroot/site/SPEEDTEST
    chmod 777 $glroot/site/PRE
    dd if=/dev/urandom of=$glroot/site/SPEEDTEST/150MB bs=1M count=150 >/dev/null 2>&1
    dd if=/dev/urandom of=$glroot/site/SPEEDTEST/250MB bs=1M count=250 >/dev/null 2>&1
    dd if=/dev/urandom of=$glroot/site/SPEEDTEST/500MB bs=1M count=500 >/dev/null 2>&1
    rm -f $glroot/sitebot/scripts/*.tcl
    cp ../scripts/extra/*.tcl $glroot/sitebot/scripts
    sed -i "s/#changeme/$announcechannels/" $glroot/sitebot/scripts/rud-news.tcl
    sed -i "s/#personal/$channelops/" $glroot/sitebot/scripts/rud-news.tcl
    mv -f ../scripts/tur-rules/tur-rules.sh $glroot/bin
    cp ../scripts/tur-rules/*.tcl $glroot/sitebot/scripts
    cp ../scripts/tur-free/*.tcl $glroot/sitebot/scripts
    cp ../scripts/tur-predircheck_manager/tur-predircheck_manager.tcl $glroot/sitebot/scripts
    sed -i "s/changeme/$channelops/g" $glroot/sitebot/scripts/tur-predircheck_manager.tcl
    cp ../scripts/extra/kill.sh $glroot/sitebot
    sed -i "s/changeme/$sitename/g" $glroot/sitebot/kill.sh
    echo "source scripts/tur-free.tcl" >> $glroot/sitebot/eggdrop.conf
    echo -e "[\e[32mDone\e[0m]"
}

function irc
{
    if [[ -f "$cache" && "`grep -w "ircserver" $cache | wc -l`" = 1 ]]
    then
	sed -i "s/servername/$ircserver/" $glroot/sitebot/eggdrop.conf
    else
	echo
    	echo -n "What irc server ? default irc.example.org : " ; read servername

	if [ "$servername" = "" ] 
	then
	    servername="irc.example.org"
	fi
		
	echo -n "What port for irc server ? default 7000 : " ; read serverport
	if [ "$serverport" = "" ] 
	then
	    serverport="7000"
	fi
		
	echo -n "Is the port above a SSL port ? [Y]es [N]o, default Y : " ; read serverssl
	case $serverssl in
	    [Yy]) ssl=1	;;
	    [Nn]) ssl=0	;;
	    *) ssl=1 ;;
	esac
		
	echo -n "Does it require a password ? [Y]es [N]o, default N : " ; read serverpassword
	case $serverpassword in
	    [Yy])
		echo -n "Please enter the password for irc server, default ircpassword : " ; read password
		if [ "$password" = "" ] 
		then
		    password=":ircpassword"
		else
		    password=":$password"
		fi
		;;
	    [Nn]) password="" ;;
	    *) password="" ;;
	esac
		
	case $ssl in
	    1)
		sed -i "s/servername/${servername} +${serverport} ${password}/" $glroot/sitebot/eggdrop.conf
		
		if [[ -f "$cache" && "`grep -w "ircserver=" $cache | wc -l`" = 0 ]]
		then
		    echo "ircserver=\"${servername} +${serverport} ${password}\"" >> $cache
		fi
		;;
	    0)
		sed -i "s/servername/${servername} ${serverport} ${password}/" $glroot/sitebot/eggdrop.conf
		
		if [[ -f "$cache" && "`grep -w "ircserver=" $cache | wc -l`" = 0 ]]
		then
		    echo "ircserver=\"${servername} ${serverport} ${password}\"" >> $cache
		fi
		;;
	esac
    fi
}

## zsconfig.h
function pzshfile
{
    cd ../../
    cat packages/data/pzshead > zsconfig.h
    [ -f "$rootdir/.tmp/.path" ] && paths="`cat $rootdir/.tmp/.path`"
    [ -f "$rootdir/.tmp/.cleanup_dated" ] && cleanup_dated=`cat $rootdir/.tmp/.cleanup_dated | sed 's/ /\n/g' | sort | xargs`
    nodatepaths="`cat $rootdir/.tmp/.nodatepath`"
    allsections=`echo "$paths $nodatepaths" | sed 's/ /\n/g' | sort | xargs | sed 's/^ //'`
    echo "#define check_for_missing_nfo_dirs		\"$allsections\"" >> zsconfig.h
    echo "#define cleanupdirs				\"$nodatepaths\"" >> zsconfig.h
    echo "#define cleanupdirs_dated			\"$cleanup_dated\"" >> zsconfig.h
    echo "#define sfv_dirs				\"$allsections\"" >> zsconfig.h
    echo "#define short_sitename				\"$sitename\"" >> zsconfig.h
    chmod 755 zsconfig.h
    mv zsconfig.h packages/pzs-ng/zipscript/conf/zsconfig.h
}

## dZSbot.tcl
function pzsbotfile
{
    cat packages/data/dzshead > ngBot.conf
    echo "set device(0)"				'"'$device SITE'"' >> ngBot.conf
    cat packages/data/dzsbnc >> ngBot.conf
    echo "REQUEST" >> $rootdir/.tmp/.validsections
    echo "set paths(REQUEST)			\"/site/REQUESTS/*/*\"" >> $rootdir/.tmp/dzsrace
    echo "set chanlist(REQUEST)			\"$announcechannels\"" >> $rootdir/.tmp/dzschan
    cat packages/data/dzsmidl  >> ngBot.conf
    echo "set sections				\"`cat $rootdir/.tmp/.validsections`\"" >> ngBot.conf
    echo "" >> ngBot.conf
    #cat $rootdir/.tmp/dzsstats >> ngBot.conf
    cat $rootdir/.tmp/dzsrace >> ngBot.conf && rm $rootdir/.tmp/dzsrace
    cat $rootdir/.tmp/dzschan >> ngBot.conf && rm $rootdir/.tmp/dzschan
    cat packages/data/dzsfoot >> ngBot.conf
    chmod 644 ngBot.conf
    mkdir -p $glroot/sitebot/scripts/pzs-ng/themes
    mv ngBot.conf $glroot/sitebot/scripts/pzs-ng/ngBot.conf
}

## PROJECTZS
function pzsng
{
    if [[ -f "$cache" && "`grep -w "eur0presystem" $cache | wc -l`" = 0 ]]
    then
    	echo
    fi
    echo -n "Installing pzs-ng, please wait...                               "
    cd packages/pzs-ng
    ./configure >/dev/null 2>&1 ; make >/dev/null 2>&1 ; make install >/dev/null 2>&1
    $glroot/libcopy.sh >/dev/null 2>&1
    echo -e "[\e[32mDone\e[0m]"
    cp sitebot/ngB* $glroot/sitebot/scripts/pzs-ng/
    cp -r sitebot/modules $glroot/sitebot/scripts/pzs-ng/
    cp -r sitebot/plugins $glroot/sitebot/scripts/pzs-ng/
    cp -r sitebot/themes $glroot/sitebot/scripts/pzs-ng/
    cp ../data/glftpd.installer.theme $glroot/sitebot/scripts/pzs-ng/themes
    cp ../data/ngBot.vars $glroot/sitebot/scripts/pzs-ng
    cp -f ../data/sitewho.conf $glroot/bin
    cd ../scripts
    rm -f $glroot/sitebot/scripts/pzs-ng/ngBot.conf.dist
}

## eur0-pre-system
function presystem
{
    if [[ -f "$cache" && "`grep -w "eur0presystem" $cache | wc -l`" = 1 ]]
    then
    	ask=`grep -w "eur0presystem" $cache | cut -d "=" -f2 | tr -d "\""`
    else
	echo
	echo -e "\e[4mDescription for Eur0-pre-system + foo-pre:\e[0m"
	cat $rootdir/packages/scripts/eur0-pre-system/description
	echo
	echo -n "Install Eur0-pre-system + foo-pre ? [Y]es [N]o, default Y : " ; read ask
    fi
	
    case $ask in
	[Nn])
	    if [[ -f "$cache" && "`grep -w "eur0presystem=" $cache | wc -l`" = 0 ]]
	    then
		echo "eur0presystem=\"n\"" >> $cache
	    fi
	    ;;
	[Yy]|*)
	    if [[ -f "$cache" && "`grep -w "eur0presystem=" $cache | wc -l`" = 0 ]]
	    then
	    	echo "eur0presystem=\"y\"" >> $cache
	    fi

	    echo -n "Installing Eur0-pre-system + foo-pre, please wait...            "
	    cd eur0-pre-system
	    make  >/dev/null 2>&1
	    make install  >/dev/null 2>&1
	    make clean >/dev/null 2>&1
	    cp *.sh $glroot/bin
	    cp *.tcl $glroot/sitebot/scripts
	    echo "source scripts/affils.tcl" >> $glroot/sitebot/eggdrop.conf
	    cat gl >> $glroot/etc/glftpd.conf
	
	    if [ -d foo-tools ]
	    then
	    	rm -rf foo-tools >/dev/null 2>&1
	    fi
	
	    git clone https://github.com/silv3rr/foo-tools >/dev/null 2>&1
	    cp -f ../../data/pre.cfg $glroot/etc
	    cd foo-tools
	    git checkout cdb77c1 >/dev/null 2>&1
	    cd src
	    ./configure -q && make build >/dev/null 2>&1
	    cp pre/foo-pre $glroot/bin
	    make -s distclean
	    echo -e "[\e[32mDone\e[0m]"
	    cd ../../
	    sections=`cat $rootdir/.tmp/.validsections | sed "s/REQUEST//g" | sed "s/ /|/g" | sed "s/|$//g"`
	    cat $rootdir/.tmp/footools >> $glroot/etc/pre.cfg
	    rm -f $rootdir/.tmp/footools
	    sed -i '/# group.dir/a group.SiteOP.dir=/site/PRE/SiteOP' $glroot/etc/pre.cfg
	    sed -i '/# group.allow/a group.SiteOP.allow='"$sections" $glroot/etc/pre.cfg
	    touch $glroot/ftp-data/logs/foo-pre.log
	    mknod $glroot/dev/full c 1 7 && chmod 666 $glroot/dev/full
	    mknod $glroot/dev/urandom c 1 9 && chmod 666 $glroot/dev/urandom
	    cd ..
	    ;;
    esac
}

## slv-prebw
function slvprebw
{
    if [[ -f "$cache" && "`grep -w "slvprebw" $cache | wc -l`" = 1 ]]
    then
    	ask=`grep -w "slvprebw" $cache | cut -d "=" -f2 | tr -d "\""`
    else
	echo
        echo -e "\e[4mDescription for slv-PreBW:\e[0m"
        cat $rootdir/packages/scripts/slv-prebw/description
	echo
	echo -n "Install slv-PreBW ? [Y]es [N]o, default Y : " ; read ask
    fi
	
    case $ask in
	[Nn])
    	    if [[ -f "$cache" && "`grep -w "slvprebw=" $cache | wc -l`" = 0 ]]
	    then
		echo "slvprebw=\"n\"" >> $cache
	    fi
	    ;;
	[Yy]|*)
	    if [[ -f "$cache" && "`grep -w "slvprebw=" $cache | wc -l`" = 0 ]]
	    then
		echo "slvprebw=\"y\"" >> $cache
	    fi
		
	    echo -n "Installing slv-PreBW, please wait...                            "
	    cp slv-prebw/*.sh $glroot/bin 
	    cp slv-prebw/*.tcl $glroot/sitebot/scripts/pzs-ng/plugins
	    echo "source scripts/pzs-ng/plugins/PreBW.tcl" >> $glroot/sitebot/eggdrop.conf
	    echo -e "[\e[32mDone\e[0m]"
	    ;;
    esac
}

## tur-ircadmin
function ircadmin
{
    if [[ -f "$cache" && "`grep -w "ircadmin" $cache | wc -l`" = 1 ]]
    then
    	ask=`grep -w "ircadmin" $cache | cut -d "=" -f2 | tr -d "\""`
    else
    	echo
	echo -e "\e[4mDescription for Tur-Ircadmin:\e[0m"
        cat $rootdir/packages/scripts/tur-ircadmin/description
	echo
	echo -n "Install Tur-Ircadmin ? [Y]es [N]o, default Y : " ; read ask
    fi
	
    case $ask in
	[Nn])
	    if [[ -f "$cache" && "`grep -w "ircadmin=" $cache | wc -l`" = 0 ]]
	    then
		echo "ircadmin=\"n\"" >> $cache
	    fi
	    ;;
	[Yy]|*)
	    if [[ -f "$cache" && "`grep -w "ircadmin=" $cache | wc -l`" = 0 ]]
	    then
	    	echo "ircadmin=\"y\"" >> $cache
	    fi
		
	    echo -n "Installing Tur-Ircadmin, please wait...                       	"
	    cd tur-ircadmin
	    cp *.sh $glroot/bin
	    cp tur-ircadmin.tcl $glroot/sitebot/scripts
	    touch $glroot/ftp-data/logs/tur-ircadmin.log
	    echo "source scripts/tur-ircadmin.tcl" >> $glroot/sitebot/eggdrop.conf
	    sed -i "s/changeme/$channelops/" $glroot/sitebot/scripts/tur-ircadmin.tcl
	    sed -i "s/changeme/$port/" $glroot/bin/tur-ircadmin.sh
	    cat gl >> $glroot/etc/glftpd.conf
	    cd ..
	    echo -e "[\e[32mDone\e[0m]"
	    ;;
    esac
}

## tur-request
function request
{
    if [[ -f "$cache" && "`grep -w "request" $cache | wc -l`" = 1 ]]
    then
    	ask=`grep -w "request" $cache | cut -d "=" -f2 | tr -d "\""`
    else
    	echo
	echo -e "\e[4mDescription for Tur-Request:\e[0m"
        cat $rootdir/packages/scripts/tur-request/description
	echo
	echo -n "Install Tur-Request ? [Y]es [N]o, default Y : " ; read ask
    fi
	
    case $ask in
	[Nn])
	    if [[ -f "$cache" && "`grep -w "request=" $cache | wc -l`" = 0 ]]
	    then
	    	echo "request=\"n\"" >> $cache
	    fi
	    ;;
	[Yy]|*)
	    if [[ -f "$cache" && "`grep -w "request=" $cache | wc -l`" = 0 ]]
	    then
	    	echo "request=\"y\"" >> $cache
	    fi
		
	    echo -n "Installing Tur-Request, please wait...                       	"
	    cd tur-request
	    cp tur-request.sh $glroot/bin
	    cp *.tcl $glroot/sitebot/scripts
	    cp file_date $glroot/bin
	    sed "s/changeme/$sitename/" tur-request.conf > $glroot/bin/tur-request.conf
	    mkdir -m777 $glroot/site/REQUESTS
	    touch $glroot/site/REQUESTS/.requests ; chmod 666 $glroot/site/REQUESTS/.requests
	    echo "1 18 * * * 		$glroot/bin/tur-request.sh status auto >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
	    echo "1 0 * * * 		$glroot/bin/tur-request.sh checkold >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
	    touch $glroot/ftp-data/logs/tur-request.log
	    echo "source scripts/tur-request.no_auth.tcl" >> $glroot/sitebot/eggdrop.conf
	    cat gl >> $glroot/etc/glftpd.conf
	    cd ..
	    echo -e "[\e[32mDone\e[0m]"
	    ;;
    esac
}

## tur-trial
function trial
{
    if [[ -f "$cache" && "`grep -w "trial" $cache | wc -l`" = 1 ]]
    then
    	ask=`grep -w "trial" $cache | cut -d "=" -f2 | tr -d "\""`
    else
    	echo
	echo -e "\e[4mDescription for Tur-Trial3:\e[0m"
        cat $rootdir/packages/scripts/tur-trial3/description
	echo
	echo -n "Install Tur-Trial3 ? [Y]es [N]o, default Y : " ; read ask
    fi
	
    case $ask in
	[Nn])
	    if [[ -f "$cache" && "`grep -w "trial=" $cache | wc -l`" = 0 ]]
	    then
		echo "trial=\"n\"" >> $cache
	    fi
	    ;;
	[Yy]|*)
	    if [[ -f "$cache" && "`grep -w "trial=" $cache | wc -l`" = 0 ]]
	    then
		echo "trial=\"y\"" >> $cache
	    fi
		
	    echo -n "Installing Tur-Trial3, please wait...                       	"
            if [ ! -f "/usr/sbin/mariadbd" ]
            then
                echo "No MySQL installed, can't install script. Install MySQL and run ./cleanup.sh and this installer again."
            else
	    	cd tur-trial3 
		cp tur-trial3.sh $glroot/bin
		cp midnight.sh $glroot/bin
		cp tur-trial3.conf $glroot/bin
		cp tur-trial3.theme $glroot/bin
		cp tur-trial3.tcl $glroot/sitebot/scripts
		cp import.sql import.sql.new
        	current=`shasum /etc/mysql/mariadb.conf.d/50-server.cnf | cut -d' ' -f1`
            	new=`shasum 50-server.cnf | cut -d' ' -f1`
	        if [ "$current" != "$new" ]
    		then
            	    mv  /etc/mysql/mariadb.conf.d/50-server.cnf  /etc/mysql/mariadb.conf.d/50-server.cnf.bak
            	    cp -f 50-server.cnf /etc/mysql/mariadb.conf.d/
	        fi
    		if [ ! -d $glroot/backup/mysql ]
            	then
            	    service mysql stop && mysql_install_db >/dev/null 2>&1 && service mysql start
	        fi
    		./setup-tur-trial3.sh create && rm import.sql.new

		echo "source scripts/tur-trial3.tcl" >> $glroot/sitebot/eggdrop.conf
	    	echo "*/31 * * * * 		$glroot/bin/tur-trial3.sh update >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
		echo "*/30 * * * * 		$glroot/bin/tur-trial3.sh tcron >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
	    	echo "45 23 * * * 		$glroot/bin/tur-trial3.sh qcron >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
		echo "0 0 * * * 		$glroot/bin/midnight.sh >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
		sed -i 's/0 0 * * *.*reset -e/#0 0 * * *              \/glftpd\/bin\/reset -e/' /var/spool/cron/crontabs/root
	    	if [ -f "`which mysql`" ]
		then
		    cp `which mysql` $glroot/bin
		fi
		
		cat gl >> $glroot/etc/glftpd.conf
		cd ..
		touch $glroot/ftp-data/logs/tur-trial3.log
		echo -e "[\e[32mDone\e[0m]"
	    fi
	    ;;
    esac
}

## tur-vacation
function vacation
{
    if [[ -f "$cache" && "`grep -w "vacation" $cache | wc -l`" = 1 ]]
    then
    	ask=`grep -w "vacation" $cache | cut -d "=" -f2 | tr -d "\""`
    else
    	echo
        echo -e "\e[4mDescription for Tur-Vacation:\e[0m"
        cat $rootdir/packages/scripts/tur-vacation/description
	echo
	echo -n "Install Tur-Vacation ? [Y]es [N]o, default Y : " ; read ask
    fi
	
    case $ask in
	[Nn])
	    if [[ -f "$cache" && "`grep -w "vacation=" $cache | wc -l`" = 0 ]]
	    then
		echo "vacation=\"n\"" >> $cache
	    fi
	    ;;
	[Yy]|*)
	    if [[ -f "$cache" && "`grep -w "vacation=" $cache | wc -l`" = 0 ]]
	    then
		echo "vacation=\"y\"" >> $cache
	    fi
		
	    echo -n "Installing Tur-Vacation, please wait...                       	"
	    cp tur-vacation/tur-vacation.sh $glroot/bin
	    touch $glroot/etc/vacation.index ; chmod 666 $glroot/etc/vacation.index
	    touch $glroot/etc/quota_vacation.db ; chmod 666 $glroot/etc/quota_vacation.db
	    cat tur-vacation/gl >> $glroot/etc/glftpd.conf
	    echo -e "[\e[32mDone\e[0m]"
	    ;;
    esac
}

## whereami
function whereami
{
    if [[ -f "$cache" && "`grep -w "whereami" $cache | wc -l`" = 1 ]]
    then
    	ask=`grep -w "whereami" $cache | cut -d "=" -f2 | tr -d "\""`
    else
    	echo
	echo -e "\e[4mDescription for Whereami:\e[0m"
        cat $rootdir/packages/scripts/whereami/description
	echo
	echo -n "Install Whereami ? [Y]es [N]o, default Y : " ; read ask
    fi
	
    case $ask in
    	[Nn])
	    if [[ -f "$cache" && "`grep -w "whereami=" $cache | wc -l`" = 0 ]]
	    then
		echo "whereami=\"n\"" >> $cache
	    fi
	    ;;
	[Yy]|*)
	    if [[ -f "$cache" && "`grep -w "whereami=" $cache | wc -l`" = 0 ]]
	    then
	    	echo "whereami=\"y\"" >> $cache
	    fi

	    echo -n "Installing Whereami, please wait...                             "
	    cp whereami/whereami.sh $glroot/bin
	    cp whereami/whereami.tcl $glroot/sitebot/scripts
	    echo "source scripts/whereami.tcl" >> $glroot/sitebot/eggdrop.conf
	    echo -e "[\e[32mDone\e[0m]"
    esac
}

## precheck
function precheck
{
    if [[ -f "$cache" && "`grep -w "precheck" $cache | wc -l`" = 1 ]]
    then
    	ask=`grep -w "precheck" $cache | cut -d "=" -f2 | tr -d "\""`
    else
	echo
	echo -e "\e[4mDescription for Precheck:\e[0m"
	cat $rootdir/packages/scripts/precheck/description
	echo
	echo -n "Install Precheck ? [Y]es [N]o, default Y : " ; read ask
    fi
	
    case $ask in
	[Nn])
	    if [[ -f "$cache" && "`grep -w "precheck=" $cache | wc -l`" = 0 ]]
	    then
	    	echo "precheck=\"n\"" >> $cache
	    fi
	    ;;
	[Yy]|*)
	    if [[ -f "$cache" && "`grep -w "precheck=" $cache | wc -l`" = 0 ]]
	    then
		echo "precheck=\"y\"" >> $cache
	    fi
		
	    echo -n "Installing Precheck, please wait...                             "
	    cp precheck/precheck*.sh $glroot/bin
	    cp precheck/precheck.tcl $glroot/sitebot/scripts
	    echo "source scripts/precheck.tcl" >> $glroot/sitebot/eggdrop.conf
	    touch $glroot/ftp-data/logs/precheck.log
	    echo -e "[\e[32mDone\e[0m]"
	    ;;
    esac
}

## tur-autonuke
function autonuke
{
    if [[ -f "$cache" && "`grep -w "autonuke" $cache | wc -l`" = 1 ]]
    then
	ask=`grep -w "autonuke" $cache | cut -d "=" -f2 | tr -d "\""`
    else
	echo
        echo -e "\e[4mDescription for Tur-Autonuke:\e[0m"
        cat $rootdir/packages/scripts/tur-autonuke/description
	echo
	echo -n "Install Tur-Autonuke ? [Y]es [N]o, default Y : " ; read ask
    fi
	
    case $ask in
	[Nn])
	    if [[ -f "$cache" && "`grep -w "autonuke=" $cache | wc -l`" = 0 ]]
	    then
		echo "autonuke=\"n\"" >> $cache
	    fi
	    ;;
	[Yy]|*)
	    if [[ -f "$cache" && "`grep -w "autonuke=" $cache | wc -l`" = 0 ]]
	    then
		echo "autonuke=\"y\"" >> $cache
	    fi
		
	    echo -n "Installing Tur-Autonuke, please wait...                       	"
    	    mv tur-autonuke/tur-autonuke.conf $glroot/bin
	    cp tur-autonuke/tur-autonuke.sh $glroot/bin
	    echo "*/10 * * * *		$glroot/bin/tur-autonuke.sh >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
	    touch $glroot/ftp-data/logs/tur-autonuke.log
	    echo -e "[\e[32mDone\e[0m]"
	    ;;
    esac
}

## psxc-imdb
function psxcimdb
{
    if [[ -f "$cache" && "`grep -w "psxcimdb" $cache | wc -l`" = 1 ]]
    then
	ask=`grep -w "psxcimdb" $cache | cut -d "=" -f2 | tr -d "\""`
    else
	echo
        echo -e "\e[4mDescription for PSXC-IMDB:\e[0m"
        cat $rootdir/packages/scripts/psxc-imdb/description
	echo
    	echo -n "Install PSXC-IMDB ? [Y]es [N]o, default Y : " ; read ask
    fi
	
    case $ask in
	[Nn])
	    if [[ -f "$cache" && "`grep -w "psxcimdb=" $cache | wc -l`" = 0 ]]
	    then
		echo "psxcimdb=\"n\"" >> $cache
	    fi
	    ;;
	[Yy]|*)
	    if [[ -f "$cache" && "`grep -w "psxcimdb=" $cache | wc -l`" = 0 ]]
	    then
	    	echo "psxcimdb=\"y\"" >> $cache
	    fi
		
	    if [[ -f "$cache" && "`grep -w "psxcimdbchan" $cache | wc -l`" = 1 ]]
	    then
		imdbchan=`grep -w "psxcimdbchan" $cache | cut -d "=" -f2 | tr -d "\""`
	    else
		while [[ -z $imdbchan ]] 
		do
		    echo -n "IMDB trigger chan for !imdb requests : " ; read imdbchan
		done
	    fi
		
	    echo -n "Installing PSXC-IMDB, please wait...                            "
	    cd psxc-imdb
	    cp ./extras/* $glroot/bin
	    cp ./addons/* $glroot/bin
	    cp ./main/psxc-imdb.sh $glroot/bin
	    cp ./main/psxc-imdb.conf $glroot/etc
	    cp ./main/psxc-imdb.tcl $glroot/sitebot/scripts/pzs-ng/plugins
	    cp ./main/psxc-imdb.zpt $glroot/sitebot/scripts/pzs-ng/plugins
	    $glroot/bin/psxc-imdb-sanity.sh >/dev/null 2>&1
	    touch $glroot/ftp-data/logs/psxc-imdb-rescan.tmp
	    touch $glroot/ftp-data/logs/psxc-moviedata.log
	    echo "source scripts/pzs-ng/plugins/psxc-imdb.tcl" >> $glroot/sitebot/eggdrop.conf
	    cat gl >> $glroot/etc/glftpd.conf
	    echo -e "[\e[32mDone\e[0m]"
	    sed -i "s/#changethis/$imdbchan/" $glroot/sitebot/scripts/pzs-ng/plugins/psxc-imdb.tcl
	    cd ..
		
	    if [[ -f "$cache" && "`grep -w "psxcimdbchan=" $cache | wc -l`" = 0 ]]
	    then
		echo "psxcimdbchan=\"$imdbchan\"" >> $cache
	    fi
	    ;;
    esac
}

## tur-addip
function addip
{
    if [[ -f "$cache" && "`grep -w "addip" $cache | wc -l`" = 1 ]]
    then
	ask=`grep -w "addip" $cache | cut -d "=" -f2 | tr -d "\""`
    else
        echo
	echo -e "\e[4mDescription for Tur-Addip:\e[0m"
        cat $rootdir/packages/scripts/tur-addip/description
	echo
	echo -n "Install Tur-Addip ? [Y]es [N]o, default Y : " ; read ask
    fi
	
    case $ask in
	[Nn])
	    if [[ -f "$cache" && "`grep -w "addip=" $cache | wc -l`" = 0 ]]
	    then
		echo "addip=\"n\"" >> $cache
	    fi
	    ;;
	[Yy]|*)
	    if [[ -f "$cache" && "`grep -w "addip=" $cache | wc -l`" = 0 ]]
	    then
		echo "addip=\"y\"" >> $cache
	    fi
		
	    echo -n "Installing Tur-Addip, please wait...                            "
	    cd tur-addip
	    cp *.tcl $glroot/sitebot/scripts
	    cp *.sh $glroot/bin
	    echo "source scripts/tur-addip.tcl" >> $glroot/sitebot/eggdrop.conf
	    touch $glroot/ftp-data/logs/tur-addip.log
	    sed -i "s/changeme/$port/" $glroot/bin/tur-addip.sh
	    sed -i "s/changeme/$channelops/" $glroot/sitebot/scripts/tur-addip.tcl
	    cd ..
	    echo -e "[\e[32mDone\e[0m]"
	    ;;
    esac
}

## topstat
function topstat
{
    if [[ -f "$cache" && "`grep -w "top" $cache | wc -l`" = 1 ]]
    then
    	ask=`grep -w "top" $cache | cut -d "=" -f2 | tr -d "\""`
    else
	echo
        echo -e "\e[4mDescription for Top:\e[0m"
        cat $rootdir/packages/scripts/top/description
	echo
	echo -n "Install Top ? [Y]es [N]o, default Y : " ; read ask
    fi
	
    case $ask in
	[Nn])
	    if [[ -f "$cache" && "`grep -w "top=" $cache | wc -l`" = 0 ]]
	    then
		echo "top=\"n\"" >> $cache
	    fi
	    ;;
	[Yy]|*)
	    if [[ -f "$cache" && "`grep -w "top=" $cache | wc -l`" = 0 ]]
	    then
		echo "top=\"y\"" >> $cache
	    fi
		
	    echo -n "Installing Top, please wait...                                  "
	    cd top
	    cp *.tcl $glroot/sitebot/scripts
	    cp *.sh $glroot/bin 
	    echo "source scripts/top.tcl" >> $glroot/sitebot/eggdrop.conf
	    cd ..
	    echo -e "[\e[32mDone\e[0m]"
	    ;;
    esac
}

## ircnick
function ircnick
{
    if [[ -f "$cache" && "`grep -w "ircnick" $cache | wc -l`" = 1 ]]
    then
    	ask=`grep -w "ircnick" $cache | cut -d "=" -f2 | tr -d "\""`
    else
	echo
        echo -e "\e[4mDescription for Ircnick:\e[0m"
        cat $rootdir/packages/scripts/ircnick/description
	echo
	echo -n "Install Ircnick ? [Y]es [N]o, default Y : " ; read ask
    fi
	
    case $ask in
	[Nn])
	    if [[ -f "$cache" && "`grep -w "ircnick=" $cache | wc -l`" = 0 ]]
	    then
		echo "ircnick=\"n\"" >> $cache
	    fi
	    ;;
	[Yy]|*)
	    if [[ -f "$cache" && "`grep -w "ircnick=" $cache | wc -l`" = 0 ]]
	    then
		echo "ircnick=\"y\"" >> $cache
	    fi
		
	    echo -n "Installing Ircnick, please wait...                              "
	    cp ircnick/*.sh $glroot/bin
	    cp ircnick/*.tcl $glroot/sitebot/scripts
	    sed -i "s/changeme/$channelops/" $glroot/sitebot/scripts/ircnick.tcl
	    echo "source scripts/ircnick.tcl" >> $glroot/sitebot/eggdrop.conf
	    echo -e "[\e[32mDone\e[0m]"
	    ;;
    esac
}

## tur-archiver
function archiver
{
    if [[ -f "$cache" && "`grep -w "archiver" $cache | wc -l`" = 1 ]]
    then
        ask=`grep -w "archiver" $cache | cut -d "=" -f2 | tr -d "\""`
    else
        echo
        echo -e "\e[4mDescription for Tur-Archiver:\e[0m"
        cat $rootdir/packages/scripts/tur-archiver/description
        echo
        echo -n "Install Tur-Archiver ? [Y]es [N]o, default Y : " ; read ask
    fi

    case $ask in
        [Nn])
            if [[ -f "$cache" && "`grep -w "archiver=" $cache | wc -l`" = 0 ]]
            then
                echo "archiver=\"n\"" >> $cache
            fi
            ;;
        [Yy]|*)
            if [[ -f "$cache" && "`grep -w "archiver=" $cache | wc -l`" = 0 ]]
            then
                echo "archiver=\"y\"" >> $cache
            fi

            echo -n "Installing Tur-Archiver, please wait...                         "
            cp tur-archiver/*.sh $glroot/bin
	    gcc -o $glroot/bin/file_date tur-archiver/file_date.c
	    echo "0 0 * * *               $glroot/bin/tur-archiver.sh >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
            echo -e "[\e[32mDone\e[0m]"
            ;;
    esac
}

## section-traffic
function section-traffic
{
    if [[ -f "$cache" && "`grep -w "section_traffic" $cache | wc -l`" = 1 ]]
    then
	ask=`grep -w "section_traffic" $cache | cut -d "=" -f2 | tr -d "\""`
    else
        echo
        echo -e "\e[4mDescription for Section-Traffic:\e[0m"
        cat $rootdir/packages/scripts/section-traffic/description
        echo
        echo -n "Install Section-Traffic ? [Y]es [N]o, default Y : " ; read ask
    fi

    case $ask in
        [Nn])
            if [[ -f "$cache" && "`grep -w "section_traffic=" $cache | wc -l`" = 0 ]]
            then
                echo "section_traffic=\"n\"" >> $cache
            fi
            ;;
        [Yy]|*)
    	    if [[ -f "$cache" && "`grep -w "section_traffic=" $cache | wc -l`" = 0 ]]
    	    then
                echo "section_traffic=\"y\"" >> $cache
    	    fi

    	    echo -n "Installing Section-Traffic, please wait...                      "
	    if [ ! -f "/usr/sbin/mariadbd" ]
	    then
	        echo "No MySQL installed, can't install script. Install MySQL and run ./cleanup.sh and this installer again."
	    else
		current=`shasum /etc/mysql/mariadb.conf.d/50-server.cnf | cut -d' ' -f1`
		new=`shasum section-traffic/50-server.cnf | cut -d' ' -f1`
		if [ "$current" != "$new" ]
		then
		    mv  /etc/mysql/mariadb.conf.d/50-server.cnf  /etc/mysql/mariadb.conf.d/50-server.cnf.bak
		    cp -f section-traffic/50-server.cnf /etc/mysql/mariadb.conf.d/
		fi
		if [ ! -d $glroot/backup/mysql ]
		then
		    service mysql stop && mysql_install_db >/dev/null 2>&1 && service mysql start
		fi
		cd section-traffic
		cp xferlog-import_3.3.sh $glroot/bin && sed -i "s/changeme/$sitename/" $glroot/bin/xferlog-import_3.3.sh
		cp section-traffic.sh $glroot/bin && sed -i "s/changeme/$sitename/" $glroot/bin/section-traffic.sh
		cp section-traffic.tcl $glroot/sitebot/scripts
		echo "source scripts/section-traffic.tcl" >> $glroot/sitebot/eggdrop.conf
		sed -i "s/changeme/$channelops/" $glroot/sitebot/scripts/section-traffic.tcl
		cp import.sql import.sql.new && sed -i "s/changeme/$sitename/" import.sql.new
		./setup-section-traffic.sh create && rm import.sql.new
		echo "*/30 * * * *            $glroot/bin/xferlog-import_3.3.sh >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
		echo "30 0 * * *              $glroot/bin/section-traffic.sh cleanup >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
		cd ..
            	echo -e "[\e[32mDone\e[0m]"
	    fi
            ;;
    esac
}


## usercreation
function usercreation
{
    if [[ -f "$cache" && "`grep -w "username" $cache | wc -l`" = 1 ]]
    then
	username=`grep -w "username" $cache | cut -d "=" -f2 | tr -d "\""`
    else
	echo
	echo "--------[ FTP user configuration ]------------------------------------"
	echo
	echo -n "Please enter the username of admin, default admin : " ; read username
    fi
	
    if [ "$username" = "" ] 
    then
    	username="admin"
    fi

    if [[ -f "$cache" && "`grep -w "password" $cache | wc -l`" = 1 ]]
    then
    	password=`grep -w "password" $cache | cut -d "=" -f2 | tr -d "\""`
    else
    	echo -n "Please enter the password [$username], default password : " ; read password
    fi
	
    if [ "$password" = "" ] 
    then
    	password="password"
    fi

    localip=`ip addr show | awk '$1 == "inet" && $3 == "brd" { sub (/\/.*/,""); print $2 }' | head | awk -F "." '{print $1"."$2"."$3.".*"}'`
    netip=`wget -qO- http://ipecho.net/plain | awk -F "." '{print $1"."$2"."$3.".*"}'`
	
    if [[ -f "$cache" && "`grep -w "ip" $cache | wc -l`" = 1 ]]
    then
	ip=`grep -w "ip" $cache | cut -d "=" -f2 | tr -d "\""`
    else
	echo -n "IP for [$username] ? Type without *@ or ident@. Minimum xxx.xxx.* default $localip $netip : " ; read ip
    fi
	
    if [ "$ip" = "" ] 
    then
	if [ "$localip" = "$netip" ]
	then
	    ip="*@$netip"
	else
	    ip="*@$localip *@$netip"
	fi
    fi

    if [[ -f "$cache" && "`grep -w "username=" $cache | wc -l`" = 0 ]]
    then
	echo "username=\"$username\"" >> $cache
	echo "password=\"$password\"" >> $cache
	echo "ip=\"*@$ip\"" >> $cache
    fi

    if [ "$router" = "y" ] 
    then
	connection="-E ftp://localhost"
    else
	connection="ftp://localhost"
    fi

    success="230 User glftpd logged in."
status=`ftp -nv localhost $port <<EOF
quote USER glftpd
quote PASS glftpd
quit
EOF`
    if [ "`echo $status | grep -c "$success"`" -eq 0 ]
    then
	if [ -e /etc/systemd/system/glftpd.socket ]
	then
	    systemctl stop glftpd.socket >/dev/null && systemctl start glftpd.socket >/dev/null
	fi
	if [ -e /etc/rc.d/rc.inetd ]
	then
	    /etc/rc.d/rc.inetd stop >/dev/null && /etc/rc.d/rc.inetd start >/dev/null
	fi
    fi
    if [ "`echo $status | grep -c "$success"`" -eq 1 ]
    then
	ncftpls -u glftpd -p glftpd -P $port -Y "site change glftpd flags +347ABCDEFGH" $connection > /dev/null
	ncftpls -u glftpd -p glftpd -P $port -Y "site grpadd SiteOP SiteOP" $connection > /dev/null
	ncftpls -u glftpd -p glftpd -P $port -Y "site grpadd Admin Administrators/SYSOP" $connection > /dev/null
	ncftpls -u glftpd -p glftpd -P $port -Y "site grpadd Friends Friends" $connection > /dev/null
    	ncftpls -u glftpd -p glftpd -P $port -Y "site grpadd NUKERS NUKERS" $connection > /dev/null
	ncftpls -u glftpd -p glftpd -P $port -Y "site grpadd VACATION VACATION" $connection > /dev/null
	ncftpls -u glftpd -p glftpd -P $port -Y "site grpadd iND Independent Racers" $connection > /dev/null
	ncftpls -u glftpd -p glftpd -P $port -Y "site gadduser Admin $username $password $ip" $connection > /dev/null
    	ncftpls -u glftpd -p glftpd -P $port -Y "site chgrp $username SiteOP" $connection > /dev/null
	ncftpls -u glftpd -p glftpd -P $port -Y "site change $username flags +1347ABCDEFGH" $connection > /dev/null
	ncftpls -u glftpd -p glftpd -P $port -Y "site change $username ratio 0" $connection > /dev/null
	ncftpls -u glftpd -p glftpd -P $port -Y "site chgrp glftpd Admin" $connection > /dev/null
	ncftpls -u glftpd -p glftpd -P $port -Y "site chgrp glftpd SiteOP" $connection > /dev/null
	echo
	echo "[$username] created successfully and added to the groups Admin and SiteOP"
	echo "These groups were also created: NUKERS, iND, VACATION & Friends"
    else
    	echo -e "\e[0;31mCouldn't connect to the newly installed FTP and add user and groups. Manual add of user and groups is needed.\e[0m"
    fi
    sed -i "s/\"changeme\"/\"$username\"/" $glroot/sitebot/eggdrop.conf
    sed -i "s/\"sname\"/\"$sitename\"/" $glroot/sitebot/scripts/pzs-ng/ngBot.conf
    sed -i "s/\"ochan\"/\"$channelops\"/" $glroot/sitebot/scripts/pzs-ng/ngBot.conf
    sed -i "s/(ochan)/($channelops)/" $glroot/sitebot/scripts/pzs-ng/ngBot.conf
    sed -i "s/\"channame\"/\"$announcechannels\"/" $glroot/sitebot/scripts/pzs-ng/ngBot.conf
}

## CleanUp / Config
function cleanup
{
    cd ../../
    if [ ! -d $glroot/backup ]; then mkdir $glroot/backup ; fi
    mv packages/$PK1DIR packages/source/
    mv packages/$PK2DIR packages/source/
    mv packages/$PK3DIR packages/source/
    if [ "$(cat install.cache | grep eur0presystem | cut -d "=" -f2 | tr -d "\"")" = "y" ]; then mv packages/scripts/eur0-pre-system/foo-tools packages/source/ ; fi
    mv $rootdir/.tmp/site/* $glroot/site/
    cp -r packages/source/pzs-ng $glroot/backup
    cp packages/scripts/extra/pzs-ng-update.sh $glroot/backup 
    cp packages/scripts/extra/backup.sh $glroot/backup && sed -i "s/changeme/$sitename/" $glroot/backup/backup.sh
    cp $glroot/backup/pzs-ng/sitebot/extra/invite.sh $glroot/bin
    cp packages/scripts/extra/syscheck.sh $glroot/bin
    mv -f $rootdir/.tmp/dated.sh $glroot/bin
    
    for sec in `grep section.*dated=\"y\" $cache | sed -e 's/section//' -e 's/dated//' | cut -d '=' -f1`
    do
	dated=`grep "section$sec=" $cache | cut -d '=' -f2 | tr -d '"'`
	sed -i '/^sections/a '"$dated" $glroot/bin/dated.sh
    done
	
    if [ `grep 'section.*dated="y"' $cache | wc -l` -ge 1 ]
    then
        echo "0 0 * * *         	$glroot/bin/dated.sh >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
        $glroot/bin/dated.sh >/dev/null 2>&1
    fi

    if [ "`ls $glroot/site | grep "^TV*" | wc -l`" -ge 1 ]
    then
        cp -f packages/scripts/tvmaze/TVMaze.tcl $glroot/sitebot/scripts/pzs-ng/plugins
        cp -f packages/scripts/tvmaze/TVMaze.zpt $glroot/sitebot/scripts/pzs-ng/plugins
        cp packages/scripts/tvmaze/*.sh $glroot/bin
        echo "source scripts/pzs-ng/plugins/TVMaze.tcl" >> $glroot/sitebot/eggdrop.conf
	for tv in `ls $glroot/site | grep "^TV*"`
	do
	    sed -i "s|set tvmaze(sections) {|set tvmaze(sections) { \"/site/$tv/\" |" $glroot/sitebot/scripts/pzs-ng/plugins/TVMaze.tcl
	done 
	$glroot/bin/tvmaze-nuker.sh sanity >/dev/null 2>&1
    fi

    echo "#*/5 * * * *		$glroot/bin/tur-space.sh go >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
    touch $glroot/ftp-data/logs/tur-space.log
    mkdir -m 777 $glroot/tmp
    chown -R $BOTU:glftpd $glroot/sitebot
    $glroot/bin/update_perms.sh
    chmod 777 $glroot/ftp-data/logs
    chmod 666 $glroot/ftp-data/logs/*
    echo "EOF" >> $glroot/sitebot/eggdrop.conf && cat $glroot/sitebot/eggdrop.conf | sed -n '/MY SCRIPTS/,/EOF/p' | sort > .tmp/myscripts && sed -i '/EOF/d' .tmp/myscripts
    sed -i '/MY SCRIPTS/,$d' $glroot/sitebot/eggdrop.conf
    cat .tmp/myscripts >> $glroot/sitebot/eggdrop.conf
    rm -rf .tmp >/dev/null 2>&1
    [ -d /etc/rsyslog.d ] && cp packages/scripts/extra/glftpd.conf /etc/rsyslog.d && service rsyslog restart
    cp packages/scripts/extra/rescan_fix.sh $glroot/bin
    echo "*/2 * * * *             $glroot/bin/rescan_fix.sh >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
}
version
start
port
device_name
channel
announce
opschan
ircnickname
section_names
glftpd
eggdrop
irc
pzshfile
pzsbotfile
pzsng
presystem
slvprebw
ircadmin
request
trial
vacation
whereami
precheck
autonuke
psxcimdb
addip
topstat
ircnick
archiver
section-traffic
usercreation
cleanup
echo 
echo "If you are planning to uninstall glFTPD then run cleanup.sh"
echo
echo "To get the bot running you HAVE to do this ONCE to create the initial userfile"
echo "su - sitebot -c \"$glroot/sitebot/sitebot -m\""
echo
echo "If you want automatic cleanup of site then please review the settings in $glroot/bin/tur-space.conf and enable the line in crontab"
echo 
echo "All good to go and I recommend people to check the different settings for the different scripts including glFTPD itself."
echo
echo "Enjoy!"
echo 
echo "Installer script created by Teqno" 

exit 0
