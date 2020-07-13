## To download

``` 
git clone https://github.com/teqnodude/glftpd-installer
```

## Software

*  glFTPD v2.10a for Linux both 32/64 bit version
*  Eggdrop v1.8.4 Stable Release

## Scripts

*  pzs-ng  
*  rud-news
*  seen
*  getops
*  eur0-pre-system(add/del/list affils part only)
*  foo-tools(only foo-pre installed)
*  idlebotkick
*  imdbrating
*  ircnick
*  mediainfo
*  precheck
*  psxc-imdb
*  section manager
*  slv-PreBW
*  tuls
*  tur-addip
*  tur-autonuke
*  tur-free
*  tur-ftpwho
*  tur-ircadmin
*  tur-oneline_stats
*  tur-precheck
*  tur-predircheck
*  tur-predircheck manager
*  tur-request
*  tur-rules
*  tur-space
*  tur-trial3
*  tur-undupe
*  tur-vacation
*  tvmaze_nuke
*  whereami
*  syscheck


## Requirements

The installer needs to be run as root and it has only been tested in **Debian** and **Slackware**

List of required packages for every script to work

**Debian**
``` 
apt-get install autoconf bc curl diffutils ftp git libflac-dev libssl-dev lm-sensors lynx make mariadb-server mkvtoolnix ncftp passwd smartmontools tcl tcl-dev tcl-tls tcpd wget zip
``` 
**BASH** needs to be the default shell. To change from default DASH to BASH in Debian do 
``` 
dpkg-reconfigure dash
``` 
## Screenshots

### Normal installation

![Screenshot_1](https://user-images.githubusercontent.com/36924638/64728657-c9cb9700-d4db-11e9-9878-1c72595d7ccf.png)
![Screenshot_2](https://user-images.githubusercontent.com/36924638/64728658-c9cb9700-d4db-11e9-9694-e389735e407e.png)
![Screenshot_3](https://user-images.githubusercontent.com/36924638/64728659-ca642d80-d4db-11e9-9e1f-aeed185d02de.png)
![Screenshot_4](https://user-images.githubusercontent.com/36924638/64728660-ca642d80-d4db-11e9-9736-32d804b527cf.png)

### Unattended installation

![Screenshot_5](https://user-images.githubusercontent.com/36924638/64728661-ca642d80-d4db-11e9-8c1f-6da2ce4b7f8c.png)

## How to do an Unattended installation

After a regular installation you are left with a file called install.cache located in install dir that will be used automatically the next time you run the installation script. Here are the various variables in install.cache if you want to make your installation unattended.

```
sitename="Test" # Name of the site 
port="2010" # Port for the FTP
version="64" # Bit version of glFTPD 32/64
device="/dev/sda1" # What device to use for /site
channelnr="2" # How many channels the bot will be in
channame1="#main n nopass" # Channelname of 1st chan with no password requirement
channame2="#flood y testing" # Channelname of 2nd chan with password requirement
announcechannels="#main #flood" # Announce channels
channelops="#main" # Ops channel 
ircnickname="l337" # Irc nickname of bot owner
sections="3" # How many sections will be created
# Allowed section names: 
# 0DAY ANIME APPS DVDR FLAC GAMES MP3 MBLURAY MVDVDR NSW PDA 
# PS4 TV-HD TV-NL TV-SD X264 X265-2160 XVID XXX XXX-PAYSITE
section1="0DAY" # Name of section 1
section2="MP3" # Name of section 2
section3="DVDR" # Name of section 3 
router="y" # If site is behind router
pasv_addr="123.123.123.123" # IP or DNS to use as passive address for glFTPD
pasv_ports="6000-7000" # Port range to use for passive mode for glFTPD
# What ircserver should the bot connect to. + = SSL port. Remove :ircpassword if no password is required
ircserver="irc.example.org:+7000:ircpassword" 
eur0presystem="y" # Install Eur0-pre-system with foo-pre
slvprebw="y" # Install Slv-PreBW
idlebotkick="y" # Install Idlebotkick
ircadmin="y" # Install Tur-Ircadmin
request="y" # Install Tur-Request
trial="y" # Install Tur-Trial
vacation="y" # Install Tur-Vacation
whereami="y" # Install Whereami
undupe="y" # Install Tur-Undupe
precheck="y" # Install Precheck
autonuke="y" # Install Tur-Autonuke
psxcimdb="y" # Install PSXC-IMDB
psxcimdbchan="#main" # Trigger chan for PSXC-IMDB
addip="y" # Install Tur-Addip
oneline_stats="y" # Install Tur-Oneline_Stats
ircnick="y" # Install Ircnick
username="admin" # Username for Administrator account
password="password" # Password for Administrator account
ip="*@192.168.1.*" # IP for Administrator account
```

## FAQ

Q. Is there anything I need to know before I install glFTPD using this installer?

A. You have to run this script as root and glFTPD gets installed to /glftpd and the eggdrop to /glftpd/sitebot. Please
   ensure that the things that are listed under Requirements in this file are installed before running this script.
   Also, this script has only been tested in Debian and Slackware systems.

-------------------------------------------------------------------------------

Q. Is the installer going to be hard to use or ask me anything i'm not going to know the answers to?

A. Not really, just run the install.sh and answer the questions that come up as you progress,
   there are brief explainations of most of the questions/options you will face :)

-------------------------------------------------------------------------------

Q. OK so I have installed glFTPD now what?

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

Q. Where can I find more scripts that may be useful for glFTPD?

A. Take a look at https://algorhythm.cc/

-------------------------------------------------------------------------------
