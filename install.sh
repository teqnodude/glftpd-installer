#!/bin/bash
VER=11.x
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

echo "Welcome to the glFTPd installer v$VER"
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
    echo -n "Downloading relevant packages, please wait..." | awk '{printf("%-64s",$0)}'
    if [[ `curl -s https://glftpd.io | grep "/files/glftpd" | grep -v BETA | grep -o "glftpd-LNX.*.tgz" | head -1` == glftpd* ]]
    then
	url="https://glftpd.io"
    else
	if [[ `curl -s https://mirror.glftpd.nl.eu.org | grep "/files/glftpd" | grep -v BETA | grep -o "glftpd-LNX.*.tgz" | head -1` == glftpd* ]]
	then
	    url="https://mirror.glftpd.nl.eu.org"
	else
	    echo
	    echo
	    echo -e "\e[0;91mNo available website for downloading glFTPd, aborting installation.\e[0m"
	    exit 1
	fi
    fi
    latest=`curl -s $url | grep "/files/glftpd" | grep -v BETA | grep -o "glftpd-LNX.*.tgz" | head -1`
    version=`lscpu | grep Architecture | awk '{print $2}'`
    case $version in
	i686)
	    version="32"
	    latest=`echo $latest | sed 's/x64/x86/'`
	    cd packages && wget -q $url/files/$latest && cd ..
	    ;;
	x86_64)
	    version="64"
	    cd packages && wget -q $url/files/$latest && cd ..
	    ;;
    esac
    PK1=`echo $latest`
    PK1DIR=`echo $latest | sed 's|.tgz||'`
    PK2DIR="pzs-ng"
    PK3DIR="eggdrop"
    UP="tar xf"
    BOTU="sitebot"
    CHKGR=`grep -w "glftpd" /etc/group | cut -d ":" -f1`
    CHKUS=`grep -w "sitebot" /etc/passwd | cut -d ":" -f1`
	
    if [ "$CHKGR" != "glftpd" ] 
    then
        groupadd glftpd -g 199
    fi
	
    if [ "$CHKUS" != "sitebot" ] 
    then
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
    
    cp -f $rootdir/packages/core/cleanup.sh $rootdir
}

function device_name
{
    if [[ -f "$cache" && "`grep -w "device" $cache | wc -l`" = 1 ]]
    then
    	device=`grep -w "device" $cache | cut -d "=" -f2 | tr -d "\""`
    	echo "Sitename           = $sitename"
    	echo "Port               = $port"
    	echo "glFTPd version     = $version bit" 
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

    if [[ -f "$cache" && "`grep -w "channelmain" $cache | wc -l`" = 1 ]]
    then
        channelmain=`grep -w "channelmain" $cache | cut -d "=" -f2 | tr -d "\""`
        echo "Main channel       = $channelmain"
    else
        echo "Channels: `cat $rootdir/.tmp/channels`"
        while [[ -z $channelmain ]]
        do
            echo -n "Which of these channels as main channel ? : " ; read channelmain
        done
    fi

    echo "$channelmain" > $rootdir/.tmp/dzmchan

    if [[ -f "$cache" && "`grep -w "channelmain=" $cache | wc -l`" = 0 ]]
    then
        echo "channelmain=\"$channelmain\"" >> $cache
    fi

    if [[ -f "$cache" && "`grep -w "channelspam" $cache | wc -l`" = 1 ]]
    then
        channelspam=`grep -w "channelspam" $cache | cut -d "=" -f2 | tr -d "\""`
        echo "Spam channel       = $channelspam"
    else
        echo "Channels: `cat $rootdir/.tmp/channels`"
        while [[ -z $channelspam ]]
        do
            echo -n "Which of these channels as spam channel ? : " ; read channelspam
        done
    fi

    echo "$channelspam" > $rootdir/.tmp/dzspamchan

    if [[ -f "$cache" && "`grep -w "channelspam=" $cache | wc -l`" = 0 ]]
    then
        echo "channelspam=\"$channelspam\"" >> $cache
    fi

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
    cp packages/modules/tur-autonuke/tur-autonuke.conf.org packages/modules/tur-autonuke/tur-autonuke.conf
    cp packages/core/dated.sh.org $rootdir/.tmp/dated.sh
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
	echo "set chanlist($section) 			\"$channelspam\"" >> $rootdir/.tmp/dzschan
	#echo "#stat_section 	$section	/site/$section/* no" >> $rootdir/.tmp/glstat
	echo "section.$section.name=$section" >> $rootdir/.tmp/footools
	echo "section.$section.dir=/site/$section/%YYYY-%MM-%DD" >> $rootdir/.tmp/footools
	echo "section.$section.gl_credit_section=0" >> $rootdir/.tmp/footools
	echo "section.$section.gl_stat_section=0" >> $rootdir/.tmp/footools
	sed -i "s/\bDIRS=\"/DIRS=\"\n\/site\/$section\/\$today/" packages/modules/tur-autonuke/tur-autonuke.conf
	sed -i "s/\bDIRS=\"/DIRS=\"\n\/site\/$section\/\$yesterday/" packages/modules/tur-autonuke/tur-autonuke.conf
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
	echo "set chanlist($section) 			\"$channelmain\"" >> $rootdir/.tmp/dzschan
	echo "/site/$section/ " > $rootdir/.tmp/.section && cat $rootdir/.tmp/.section >> $rootdir/.tmp/.temp
	cat $rootdir/.tmp/.temp | awk -F '[" "]+' '{printf $0}' > $rootdir/.tmp/.nodatepath
	#echo "#stat_section 	$section /site/$section/* no" >> $rootdir/.tmp/glstat
	echo "section.$section.name=$section" >> $rootdir/.tmp/footools
	echo "section.$section.dir=/site/$section" >> $rootdir/.tmp/footools
	echo "section.$section.gl_credit_section=0" >> $rootdir/.tmp/footools
	echo "section.$section.gl_stat_section=0" >> $rootdir/.tmp/footools
	sed -i "s/\bDIRS=\"/DIRS=\"\n\/site\/$section/" packages/modules/tur-autonuke/tur-autonuke.conf
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
        echo "IMDB channels      = "`grep -w "psxcimdbchan" $cache | cut -d "=" -f2 | tr -d "\""`
    fi

    echo
    echo "--------[ Installation of software and scripts ]----------------------"
    packages/scripts/tur-rules/rulesgen.sh MISC
    cd packages
    echo
    echo -n "Installing glftpd, please wait..." | awk '{printf("%-64s",$0)}'
    echo "####### Here starts glFTPd scripts #######" >> /var/spool/cron/crontabs/root
    cd $PK1DIR && sed "s/changeme/$port/" ../core/installgl.sh.org > installgl.sh && chmod +x installgl.sh && ./installgl.sh >/dev/null 2>&1
    >$glroot/ftp-data/misc/welcome.msg
    echo -e "[\e[32mDone\e[0m]"
    cd ../core
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
    gcc -O2 ../extra/tur-ftpwho/tur-ftpwho.c -o $glroot/bin/tur-ftpwho
    gcc ../extra/tuls/tuls.c -o $glroot/bin/tuls
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
    cp ../extra/incomplete-list.sh $glroot/bin
    cp ../extra/incomplete-list-nuker.sh $glroot/bin
    cp ../extra/incomplete-list-symlinks.sh $glroot/bin
    cp ../extra/lastlogin.sh $glroot/bin
    chmod 755 $glroot/site
    ln -s $glroot/etc/glftpd.conf /etc/glftpd.conf
    chmod 777 $glroot/ftp-data/msgs
    cp ../extra/update_perms.sh $glroot/bin
    cp ../extra/update_gl.sh $glroot/bin
    cp ../extra/imdb-scan.sh $glroot/bin
    cp ../extra/imdb-rescan.sh $glroot/bin
    cp ../extra/glftpd-version-check.sh $glroot/bin
    echo "0 18 * * *              $glroot/bin/glftpd-version-check.sh >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
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
    echo -n "Installing eggdrop, please wait..." | awk '{printf("%-64s",$0)}'
    cd ../$PK3DIR ; ./configure --prefix="$glroot/sitebot" >/dev/null 2>&1 && make config >/dev/null 2>&1  && make >/dev/null 2>&1 && make install >/dev/null 2>&1
    cd ../core
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
    cp ../extra/*.tcl $glroot/sitebot/scripts
    sed -i "s/#changeme/$announcechannels/" $glroot/sitebot/scripts/rud-news.tcl
    sed -i "s/#personal/$channelops/" $glroot/sitebot/scripts/rud-news.tcl
    mv -f ../scripts/tur-rules/tur-rules.sh $glroot/bin
    cp ../scripts/tur-rules/*.tcl $glroot/sitebot/scripts
    cp ../scripts/tur-free/*.tcl $glroot/sitebot/scripts
    cp ../scripts/tur-predircheck_manager/tur-predircheck_manager.tcl $glroot/sitebot/scripts
    sed -i "s/changeme/$channelops/g" $glroot/sitebot/scripts/tur-predircheck_manager.tcl
    cp ../extra/kill.sh $glroot/sitebot
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
    cat packages/core/pzshead > zsconfig.h
    echo "/site/REQUESTS/" >> $rootdir/.tmp/.nodatepath
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
    cat packages/core/dzshead > ngBot.conf
    echo "set device(0)"				'"'$device SITE'"' >> ngBot.conf
    cat packages/core/dzsbnc >> ngBot.conf
    echo "REQUEST" >> $rootdir/.tmp/.validsections
    echo "set paths(REQUEST)			\"/site/REQUESTS/*/*\"" >> $rootdir/.tmp/dzsrace
    echo "set chanlist(REQUEST)			\"$announcechannels\"" >> $rootdir/.tmp/dzschan
    cat packages/core/dzsmidl  >> ngBot.conf
    echo "set sections				\"`cat $rootdir/.tmp/.validsections`\"" >> ngBot.conf
    echo "" >> ngBot.conf
    #cat $rootdir/.tmp/dzsstats >> ngBot.conf
    cat $rootdir/.tmp/dzsrace >> ngBot.conf && rm $rootdir/.tmp/dzsrace
    cat $rootdir/.tmp/dzschan >> ngBot.conf && rm $rootdir/.tmp/dzschan
    cat packages/core/dzsfoot >> ngBot.conf
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
    echo -n "Installing pzs-ng, please wait..." | awk '{printf("%-64s",$0)}'
    cd packages/pzs-ng
    ./configure >/dev/null 2>&1 ; make >/dev/null 2>&1 ; make install >/dev/null 2>&1
    $glroot/libcopy.sh >/dev/null 2>&1
    echo -e "[\e[32mDone\e[0m]"
    cp sitebot/ngB* $glroot/sitebot/scripts/pzs-ng/
    mkdir $glroot/sitebot/scripts/pzs-ng/modules
    cp sitebot/modules/glftpd.tcl $glroot/sitebot/scripts/pzs-ng/modules
    mkdir $glroot/sitebot/scripts/pzs-ng/plugins
    cp ../core/glftpd-installer.theme $glroot/sitebot/scripts/pzs-ng/themes
    cp ../core/ngBot.vars $glroot/sitebot/scripts/pzs-ng
    cp -f ../core/sitewho.conf $glroot/bin
    rm -f $glroot/sitebot/scripts/pzs-ng/ngBot.conf.dist
}

function modules
{
    cd $rootdir
    for module in `ls ./packages/modules`
    do
	. packages/modules/$module/$module.inc
    done
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
    sed -i "s/\"mainname\"/\"$channelmain\"/" $glroot/sitebot/scripts/pzs-ng/ngBot.conf
    sed -i "s/\"spamname\"/\"$channelspam\"/" $glroot/sitebot/scripts/pzs-ng/ngBot.conf
    sed -i "s/\"invitename\"/\"$announcechannels\"/" $glroot/sitebot/scripts/pzs-ng/ngBot.conf
}

## CleanUp / Config
function cleanup
{
    cd $rootdir
    if [ ! -d $glroot/backup ]; then mkdir $glroot/backup ; fi
    mv packages/$PK1DIR packages/source/
    mv packages/$PK2DIR packages/source/
    mv packages/$PK3DIR packages/source/
    if [ "$(cat install.cache | grep eur0presystem | cut -d "=" -f2 | tr -d "\"")" = "y" ]; then mv packages/modules/eur0-pre-system/foo-tools packages/source/ ; fi
    mv $rootdir/.tmp/site/* $glroot/site/
    cp -r packages/source/pzs-ng $glroot/backup
    cp packages/extra/pzs-ng-update.sh $glroot/backup 
    cp packages/extra/backup.sh $glroot/backup && sed -i "s/changeme/$sitename/" $glroot/backup/backup.sh
    cp $glroot/backup/pzs-ng/sitebot/extra/invite.sh $glroot/bin
    cp packages/extra/syscheck.sh $glroot/bin
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
    rm -rf $glroot/glftpd-LNX_current
    rm -f packages/modules/tur-autonuke/tur-autonuke.conf
    [ -d /etc/rsyslog.d ] && cp packages/extra/glftpd.conf /etc/rsyslog.d && service rsyslog restart
    cp packages/extra/rescan_fix.sh $glroot/bin
    echo "*/2 * * * *             $glroot/bin/rescan_fix.sh >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
}
version
start
port
device_name
channel
announce
ircnickname
section_names
glftpd
eggdrop
irc
pzshfile
pzsbotfile
pzsng
modules
usercreation
cleanup
echo 
echo "If you are planning to uninstall glFTPd then run cleanup.sh"
echo
echo "To get the bot running you HAVE to do this ONCE to create the initial userfile"
echo "su - sitebot -c \"$glroot/sitebot/sitebot -m\""
echo
echo "If you want automatic cleanup of site then please review the settings in $glroot/bin/tur-space.conf and enable the line in crontab"
echo 
echo "All good to go and I recommend people to check the different settings for the different scripts including glFTPd itself."
echo
echo "Enjoy!"
echo 
echo "Installer script created by Teqno" 

exit 0
