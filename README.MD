## Intended systems

This installer is intended to be used on systems that do not have existing MariaDB databases running. If it's being used on systems that have existing databases running, then keep in mind that this installer will backup the 
existing /etc/mysql/mariadb.conf.d/50-server.cnf to /etc/mysql/mariadb.conf.d/50-server.cnf.bak and install its own version if section-traffic or tur-trial3 is installed. This could potentially 
stop existing databases from working properly. If you want to use the installer despite having existing databases, then I would recommend you do not choose to install section-traffic or 
tur-trial3 and do this manually instead.

## To download

``` 
git clone https://github.com/teqnodude/glftpd-installer
```

## Software

*  latest stable glFTPd for Linux both 32/64 bit version
*  eggdrop latest github version

## Scripts

*  pzs-ng latest github version 
*  rud-news
*  seen
*  getops
*  eur0-pre-system(add/del/list affils part only)
*  foo-tools(only foo-pre installed) latest github version
*  imdbrating
*  ircnick
*  mediainfo
*  precheck
*  psxc-imdb
*  section_manager
*  section-traffic
*  slv-PreBW
*  top
*  tuls
*  tur-addip
*  tur-archiver
*  tur-autonuke
*  tur-free
*  tur-ftpwho
*  tur-ircadmin
*  tur-precheck
*  tur-predircheck
*  tur-predircheck manager
*  tur-request
*  tur-rules
*  tur-space
*  tur-trial3
*  tur-vacation
*  tvmaze-nuker
*  whereami
*  syscheck


## Requirements

The installer needs to be run as root and it has only been tested in **Debian** and **Slackware**

List of required packages for every script to work

**Debian**
``` 
apt-get install cron gcc systemd autoconf bc curl diffutils ftp git libflac-dev libssl-dev lm-sensors lynx make mariadb-server ncftp passwd rsync smartmontools tcl tcl-dev tcllib tcl-tls tcpd wget zip bsdmainutils rsyslog
``` 
**BASH** needs to be the default shell. To change from default DASH to BASH in Debian do 
``` 
dpkg-reconfigure dash
``` 
## Screenshots

### Normal installation

![Screenshot_1](https://github.com/teqnodude/glftpd-installer/assets/36924638/af283a70-7445-47f0-92fb-91b87aea06c1)
![Screenshot_2](https://github.com/teqnodude/glftpd-installer/assets/36924638/ffcf7274-1de5-4e82-8c69-ba9f55450a3d)
![Screenshot_3](https://github.com/teqnodude/glftpd-installer/assets/36924638/a13f4665-5ade-4c75-8f9d-41861e91b898)
![Screenshot_4](https://github.com/teqnodude/glftpd-installer/assets/36924638/014d40b3-9353-40bf-974d-6af3ade9265f)

### Unattended installation

![Screenshot_5](https://github.com/teqnodude/glftpd-installer/assets/36924638/784c4698-ac20-4210-8581-0f89dac0cbd4)
![Screenshot_6](https://github.com/teqnodude/glftpd-installer/assets/36924638/0db1bb75-cdbd-43ea-9586-afceb517e2b3)

## How to do an Unattended installation

After a regular installation you are left with a file called install.cache located in install dir that will be used automatically the next time you run the installation script. Here are the various variables in install.cache if you want to make your installation unattended.

```
sitename="Test" # Name of the site. Don't use space in sitename. 
port="2010" # Port for the FTP
device="/dev/sda1" # What device to use for /site
channelnr="2" # How many channels the bot will be in
channame1="#main n nopass" # Channelname of 1st chan with no password requirement
channame2="#flood y testing" # Channelname of 2nd chan with password requirement
announcechannels="#main #flood" # Announce channels
channelops="#main" # Ops channel 
ircnickname="l337" # Irc nickname of bot owner
sections="3" # How many sections will be created, max 22 sections allowed
# Recommended section names: 
# 0DAY ANIME APPS DOX EBOOKS FLAC GAMES MBLURAY MP3 NSW PS4 PS5 TV-1080 TV-2160 
# TV-720 TV-HD TV-NL X264 X264-1080 X264-720 X265-2160 XVID XXX XXX-PAYSITE
section1="0DAY" # Name of section 1
section1dated="y" # Dated section?
section2="MP3" # Name of section 2
section2dated="n" # Dated section?
section3="DVDR" # Name of section 3 
section3dated="n" # Dated section?
router="y" # If site is behind router
pasv_addr="123.123.123.123" # IP or DNS to use as passive address for glFTPd
pasv_ports="6000-7000" # Port range to use for passive mode for glFTPd
# What ircserver should the bot connect to. + = SSL port. Remove :ircpassword if no password is required
ircserver="irc.example.org +7000 ircpassword" 
eur0presystem="y" # Install Eur0-pre-system with foo-pre
slvprebw="y" # Install Slv-PreBW
ircadmin="y" # Install Tur-Ircadmin
request="y" # Install Tur-Request
trial="y" # Install Tur-Trial
vacation="y" # Install Tur-Vacation
whereami="y" # Install Whereami
precheck="y" # Install Precheck
autonuke="y" # Install Tur-Autonuke
psxcimdb="y" # Install PSXC-IMDB
psxcimdbchan="#main" # Trigger chan for PSXC-IMDB
addip="y" # Install Tur-Addip
top="y" # Install Top
ircnick="y" # Install Ircnick
archiver="y" # Install Tur-Archiver
section_traffic="y" # Install Section-Traffic
username="admin" # Username for Administrator account
password="password" # Password for Administrator account
ip="*@192.168.1.*" # IP for Administrator account
```

## FAQ

Q. Is there anything I need to know before I install glFTPd using this installer?

A. You have to run this script as root and glFTPd gets installed to /glftpd and the eggdrop to /glftpd/sitebot. Please
   ensure that the things that are listed under Requirements in this file are installed before running this script.
   Also, this script has only been tested in Debian and Slackware systems.

-------------------------------------------------------------------------------

Q. Is the installer going to be hard to use or ask me anything i'm not going to know the answers to?

A. Not really, just run the install.sh and answer the questions that come up as you progress,
   there are brief explainations of most of the questions/options you will face :)

-------------------------------------------------------------------------------

Q. OK so I have installed glFTPd now what?

A. After the installation you have to create the initial userfile for sitebot or it will not start up.
   Do that by doing:
   ```
   su - sitebot -c "/glftpd/sitebot/sitebot -m"
   ```
   Now your bot should be running on the irc network that you specified during the installation. Type the following and 
   replace sitename with the sitename you chose during installation for the site:
   ```
   /msg sitename hello
   ```
   By now you should get a reply from the bot with further instructions. Once everything is set up then in the future the 
   bot will be automatically started by crontab if not running by checking every 10 min. To manually start the eggdrop after 
   you set up the sitebot you do:
   ```
   su - sitebot -c "/glftpd/sitebot/sitebot"
   ```

-------------------------------------------------------------------------------

Q. Where can I find more scripts that may be useful for glFTPd?

A. Take a look at https://algorhythm.cc/

-------------------------------------------------------------------------------
