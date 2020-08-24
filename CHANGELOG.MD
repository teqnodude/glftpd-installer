## 10.x -

### Updated

- Increased the number of connections from default 64 to 300 for boxes that runs glFTPD in systemd

### Fixes

- Forgot to put both MVID and PRE section under allowed_types_exemption_dirs in zsconfig.h to allow the pre and upload of MVID


## 9.9 - 2020-08-03

### Updated

- Changed so people can upload and download for free in SPEEDTEST folder
- When searching for a block in tur-predircheck_manager you now get a reply if no result is found to avoid confusion
- Removed all tar packages and grabbing the latest versions from github and webpages instead making the installer a lot smaller
- Updated description for sitename to prevent problems caused by spaces in sitename


## 9.8 - 2020-07-01

### Added

- Added my own glFTPd version check to theme that runs in crontab and announce if and when new version is available to staffchan
- Added mkv_check to avoid bad and incomplete samples being uploaded to sample folders
- Added imdbrating which allows people to create an index for a section to filter out movies by genre, imdb score, year and more from psxc-imdb tag in movie folders
- Added listaffils.tcl for Eur0-Pre-System to allow people list affils on irc by doing !affils
- Added TVMaze_nuke that allows you to autonuke incoming series based on genre, year, country and type and exclude groups, affils and sections, check /glftpd/bin/TVMaze_nuke.sh for settings.
- Added custom made TVMaze with imdb rating and imdb url with fitting theme that executes TVMaze_nuke on every upload

### Fixes

- Tur-Predircheck_Manager had problems when editing sections where changes would occur on non-targeted sections
- Bugfixes for Tur-Predircheck_Manager that involved leaving | at start of the line and \ in announce after removal of block
- Fixed grep line for sections in tur-predircheck to better managing sections with similar names
- Changed file extension from .zst to .theme on pzs-ng theme file since certain editors like midnight commander couldn't edit the file because of extension
- Added wget as part of the requirements in README file
- mkv_check was not defined in ngBot.conf and gave errors in eggdrop.log
- tur-oneline_stats didn't show stats because of previous upgrade of glftpd that changed showing stats in MiB to GiB
- Removed duplicate lines from ngBot.conf
- Missing lines of PREBW in ngBot.conf

### Updated

- Enabled highlight for matches during search of block in Tur-Predircheck_Manager
- Changed color for glFTPd version check announce and had the check changed to once a day instead of every hour to avoid spam
- Added code to tur-request that checks new requests against dirlog to prevent requests of things that are already on site
- Changed limits for sections to max 20 and channels to max 15.
- Added TVMaze_nuke to the list of scripts included in this installer


## 9.7 - 2020-02-13

### Fixes

- Free: in statline didn't follow display_size_unit in glftpd.conf because developer forgot to implement new cookies.
- In certain situations debian users are having an incomplete PATH variable, have implemented a check against that which corrects the PATH
- Because new version of glFTPD is compiled against newer GLIBC_2.28 then change to glftpd-full-static is required for systems with older versions, set as default now
- Fixed the grabbing of foo-tools by setting a specific git version since the developer of foo-tools broke foo-pre with newer version.

### Updated

- Included search function in tur-predircheck_manager to make it easier spot blocks in large blocklists
- Updated packages for glFTPD to version 2.10a
- Updated section_manager to remove line from crontab related to the creation of dated dirs if no dated sections are found.
- Disabled timer for rud-news.tcl 
- Changed settings for rud-news.tcl and included fitting colors to better highlight when news is added
- I've put tur-space disabled by default in crontab to avoid having entire sites wiped due to bad setup information. I've also included a message at the end of installation regarding this
- Cosmetic code changes to tur-precheck
- Updated TVMaze.tcl with own code to make it use SSL and having links converted to https and also included the announce of rating
- Updated TVMaze.tcl with own code to enable the grab of IMDB url for use, enabled IMDB url for !tv lookups
- Updated Tur-Predircheck Manager and changed command "edit release" to "edit section" since it makes more sense
- Tur-precheck now also blocks .nfo files in Covers/Proof/Sample dirs


## 9.6 - 2019-12-25

### Fixes

- Changed nuke of incompletes to 12 hours instead of 24 hours because of missed nukes of incompletes in 0DAY/MP3/FLAC sections due to pzs-ng limitations
- With certain releases mediainfo spit out double Duration for video causing irc announce to split

### Updated

- Updated mediainfo to show Title for Audio when present instead of Format to highlight modes like DTS-HD MA 5.1 etc
- Added colors to mediainfo to better highlight relevant info
- Updated packages for glFTPD to the latest version 2.10 and updated glftpd.conf to reflect the new changes
- Updated pzs-ng because of update to glFTPD 2.10 since old version was not compatible
- Updated cleanup.sh script because of new versions of pzs-ng and glFTPD
- Updated README.MD to include Debian package passwd in list of requirements and the fact that the script has to be run as root to prevent future problems


## 9.5 - 2019-11-15

### Added

- Included my own Tur-Predircheck Manager to enable management of blocks inside Tur-Predircheck through IRC
- Included mediainfo script but needs to be manually installed

### Fixes

- Fixed clear_table.sh since it didn't work if no pass was entered
- Fixed tur-addip.tcl so mainchan is automatically set to the chosen ops channel during install for public trigger !addip. Chose ops channel for security reasons
- Port in idlebotkick were previously not set to the port chosen during install
- Added extra check in addaffil.sh in case someone removed the comment lines used as reference points
- More cosmetic changes like better indentation and corrected typos
- Tur-predircheck_manager left double || after remove of block
- Section Manager did not remove section from pre.cfg
- Changed code for Section Manager so that it better keep the format of zsconfig.h after removal of sections.
- Section Manager gave out error when removing section from addaffil.sh
- Removed /Subs from the list of incompletes in incomplete-list-nuker
- Fixed announce for Tur-predircheck_manager
- Fix of announce in Section Manager when choosing to remove section folder
- libFLAC was not installed because libcopy.sh was run before the install of pzs-ng, moved it to after install of pzs-ng
- Fixed spelling error when installing ircnick
- Emptied the default /ftp-data/misc/welcome.msg since it could cause errors in some ftp clients because of oneliners
- Optimized code in tur-predircheck_manager and fixed some errors that occured after feature of word block was added to script
- Fixed mediainfo and limited search and extraction of information to relevant parts of information dump
- Minor spelling errors
- Mediainfo didn't display audio at all times and removed some unnecessary code due to previous tweak of limited search
- Optimized Mediainfo and added the removal of tmp file since it could cause permission problems if run in shell and then in irc
- Fixed so Mediainfo is no longer looking for incomplete or nuked releases
- Added pattern for checking if release is TV Show or not in Mediainfo
- Mediainfo broke when releases used different set of rar files ie .part01.rar
- Added the removal of SAMPLEFIX and DIRFIX from list of releases in Mediainfo
- Excluded sample dir in incomplete-list-nuker, caused problems when people uploaded sfv into sample dirs

### Updated

- Updated README and included Tur-Predircheck Manager in the list of scripts
- Updated ircnick to only display latest since it's the relevant and changed announce to ops chan instead of nick
- Updated Tur-Predircheck_Manager so you no longer need to manually escape special chars since it's done automatically
- Minor adjustment to dated.sh script
- Changed slots for default.user from 2 to 6
- Removed remaining flood protections from eggdrop since they shown to cause havoc in chans under unusal circumstances ie netsplits
- Added the ability to edit existing block of words with tur-predircheck_manager, added help syntax and examples
- Added announce for ircnick in case user hasn't invited him/herself since the creation of log file
- Added timecheck for lockfile in incomplete-list-nuker to avoid it not being run after a reboot of box


## 9.0 - 2019-09-11

### Added

- Section Manager added which will be part of the core installation that will be found in root dir of /glftpd after installation for easy access, no more 
tedious manual updates of scripts due to add/del of sections

### Updated

- Did a big overhaul of the code to make it look better and also give a better overview both during normal and unattended installations
- Updated psxc-imdb settings and disabled the use of psxc-imdb-dotimdb.pl for the creation of .imdb
- Updated README with new screenshots

### Fixes

- setupsql.sh did not work properly due to change in MySQL language + if user had empty password for accessing db


## 8.5 - 2019-09-08

### Fixes

- Enabled highlightning of description for scripts during install to make it easier spotting relevant information
- Changed name of function to avoid conflict with system commands
- Enabled the copy of cleanup script much earlier in the script in case someone decides to abort in the middle of things and want to remove things from system
- Optimized installer by removing some unnecessary code and updated methods of handling files 
- Gone through the creation of glftpd.conf and created better indentation to give better overview
- Updated permissions for some commands
- Removed various traces of personal settings in various scripts which I forgot
- Ensured that all scripts that require log file are now having them created during install and set with proper permissions
- Removed listwho from Idlebotkick since it got replaced with tur-ftpwho a long time ago
- Many minor issues with echoing info during installation, nothing critical

### Updated

- Updated screenshots that shows both attended and unattended installation in 8.5


## 8.1 - 2019-09-07

### Fixes

- Added cleanup of comments and trailing spaces of install.cache
- Switched to downloading a fresh foo-tools at each run to avoid compiling issues which happened every now and then
- Inconsistent structure of 0DAY/FLAC/MP3 across scripts
- Created code to avoid installer crashing when person did not enter any info at required places
 
### Updated

- Added some brief descriptions and did some cosmetic code changes to a few scripts
- Added more screenshots that shows Unattended installation
- Minor cosmectic change to Precheck
- Merged a lot of functions that was based on old knowledge and coding style
 

## 8.0 - 2019-09-05

### Added

- An install.cache file is now being created during install which can be used for future unattended installations. When file is present
in dir the installation will become completely unattended if all variables are set. If any variable is not set then it will ask for user input.

### Updated

- Made eur0-pre-system clean up after installation
- Updated the format of CHANGELOG.MD fully where all past changes should now be viewed correctly on github
- Gone through the whole install.sh and implemented indentation to give a better overview of code for future possible developers

### Fixes

- Noticed errors when compiling foo-pre
- Noticed errors when compiling Eur0-pre-system
- Refuse any other input than numbers when asked for how many channels and sections to setup
- Minor cosmetic changes to code in installer.sh and other scripts


## 7.4 - 2019-09-03

### Added

- Added my own script called Ircnick to enable ops checking what nickname their users have on irc
- Added kill.sh to sitebot dir to make it easy for lazy people to kill bot

### Updated

- Updated Precheck to 1.0
- Gone through the whole changelog and formatted it to suit github better and to give a better overview of past changes 
- Updated the creation of channels part during installation to get a more clear overview and easier setup 
- Updated screenshots in README

### Todo

- Go through the whole CHANGELOG.MD and update format for everything. 


## 7.3 - 2019-09-02

### Fixes

- Fixed 2 errors when checking public and local ip due to path changes between systems
- Limited install script to only openbsd-inetd and systemd where systemd takes precedence if both are present
- Added the question if people read the Requirements in README.MD to avoid crashes during install 


## 7.2 - 2019-09-02

### Fixes

- Adjusted the order of settings in pre.cfg for better overview
- Improved cleanup script
- If chosen sitename with spaces in it then it would break configuration in multiple places 

### Updated

- When asked for DNS or IP for site during install it now defaults to your public ip
- Have changed the setup for irc by creating multiple questions to lessen keystrokes and to avoid incorrect input
- When asked to setup Administrator account then default values are now set with ip set based on local ip
- The installer now asks you for your nickname on irc to set the variable of owner on eggdrop


## 7.1 - 2019-09-01

### Fixes

- Removed a lot of unnecessary code to make it more optimized
- dated.sh was not created properly during install
- Corrected minor spelling errors and rewritten some of the text seen during installation
- Removed the creation of pre.sh for Eur0-pre-system due to switch to foo-pre in v7.0
- Made some cosmetic changes in the creation of zsconfig.h and ngBot.conf to give a better overview when viewing them after installation
- incomplete-list-nuker.sh missed necessary code to execute properly

### Updated

- When adding/removing affils by command SITE ADDAFFIL or SITE DELAFFIL it's now updating relevant files accordingly
- Removed section Musicvideos and relevant rules since it's no longer a popular section
- Removed section Ebook and relevant rules because they go under 0DAY 


## 7.02 - 2019-09-01

### Added

- Added slv-PreBW with customized colors to fit the current glftpd-installer theme.

### Fixes

- If chosen password for channel during install then the eggdrop wouldn't start because of missing ""


## 7.01 - 2019-08-31

### Added

- Added tur-free with customized colors to fit the current glftpd-installer theme. 
- Disabled default !df/!free in pzs-ng after switch to tur-free


## 7.0 - 2019-08-29

### Added

- Added foo-pre as part of Eur0-pre-system where sections added during install is used

### Updated

- Replaced script for SITE PRE command from /bin/pre.sh in glftpd.conf to /bin/foo-pre

### Fixes

- For some unknown reason the groupfile SiteOP did not get created during the creation of the group
which was solved by a simple copy and renaming of existing groupfile
- Corrected some minor spelling errors
- Various files have been merged and removed to make it less confusing for people to find correct information

## Other

- Gone through various files to make sure it's ready for it's launch to github and meet the world


## 6.1 - 2019-08-28

### Added

- Added rud-news.tcl where channels are based on the input during install
- Added input for ops channel to be used for various scripts

### Updated

- Updated rules 
- Updated README
- Updated ngBot.conf to respond to new input of ops chan and to include privchannel for ops
- Many minor issues that got fixed


## 6.05 - 2019-08-19

### Fixes

- Added checks for inetd and crond in both install and cleanup script to avoid error messages in Debian systems
- Corrected some minor spelling errors


## 6.04 - 2019-08-18

### Updated

- Updated TVMaze script


## 6.03 - 2019-06-26

### Added

- Incomplete-list-nuker.sh added to replace tur-autonuke. Disabled tur-autonuker modules so these two do not collide.


## 6.02 - 2019-02-26

### Fixes

- Fixed error with TVMaze script
- Fixed theme for psxc-imdb 


## 6.01 - 2019-01-24

### Updated

- Updated eggdrop from 1.8.3 to 1.8.4
- Updated glFTPD from 2.08 to 2.09

### Fixes

- Corrected some minor misspelling


## 6.0 - 2018-03-14

### Fixes

- Corrected some issues with tur-precheck.sh and tur-predircheck.sh
- Fixed the creation of groups during install which made SiteOP group only to be added to group file but not group folder
- Removed SiteOP as privgroup in glftpd.conf


## 5.9 - 2018-03-09

### Added

- Added tur-precheck.sh


## 5.8 - 2018-03-06

### Updated

- Removed the copy of libcopy.sh from pzs-ng since it's now recommended to use the one that glFTPD got.
- Replaced incomplete-list.sh with a fully working one that also displays missing nfo, hack by me based on original script.
- Fixed turranius dirloglist_gl by using the dirloglist.c and glconf.h from sources in /glftpd. Script works now as intended.


## 5.7 - 2018-02-20

### Updated

- Changed color of PRE's to yellow, NUKE's to orange in order to spot them more easily.
- Replaced news.tcl with rud-news.tcl since the old wasn't working properly with fish in pm's
- Changed days from 14 days until forever on unfilled requests in tur-request


## 5.6 - 2018-02-13

### Updated 

- eggdrop to 1.8.3 stable version

### Fixes 

- Tur-predircheck wasn't working properly
- Added separate announce for tur-predircheck
- Updates to theme 


## 5.5 - 2018-01-21

### Added

- Added tur-addip
- Added tur-oneline_stats

### Fixes

- Disabled annouce for update, new leader, race and halfway and inserted new line after completion.
- Fixed a lot of spelling errors and permission problems.
- Added more default key press events during install.


## 5.3 - 2018-01-05

### Added

- Updated glFTPD version to 2.08 final
- Updated psxc-imdb to latest version due to change of imdb.com layout

### Fixes

- Due to update of glFTPD the install script of glFTPD needed to be updated to support IPv6.


## 5.2 - 2017-10-10

### Added

- Added section X265-2160 as an option during install with included rules

### Fixes

- Renaming of folders and minor changes to various scripts
- Updated ngBot.tcl to announce ", please wait..." before checking incompletes


## 5.1 - 2017-09-24

### Added

- Made a customized pzs-ng theme
- Added the compilation of tuls and tur-ftpwho to the installation

### Updated

- Made dated script determined by the user input during installation

### Fixes

- Clarifcation of default values during installation
- Minor fixes when it comes to the cleanup after install 
- Proper permissions have been put in place for dirs
- Set nondupecheck for SPEEDTEST and REQUESTS folder after some complications 


## 5.02 - 2017-09-07

### Updated

- Replaced incomplete-list script with my own custom made.
- Set the default port 2010 for glFTPD
- Updated theme to show fastest/slowest racers and removed some unncessary output

### Fixes

- Removed DOX section because of lack of rules.
- Removed default timeout and maximum timeout from glftpd options because of problems with large files
- Fixed issue in tur-request script where it didn't remove old requests due to wrong command
- Fixed wrong theme variables


## 5.01 - 2017-08-13

## Updated

- eggdrop updated to latest version

### Added 

- included tur-predircheck package as an option 
- included working tur-ftpwho for 64bit version for compilation

### Fixes

- Minor adjustments to various scripts 
- Added more cleanup to install script
- Increased security through TLS enforcement in glftpd.conf


## 5.0 - 2017-02-05

### Updated

- eggdrop updated to latest version
- pzs-ng updated to latest version
- glFTPD updated to 2.07.1 and added both 32/64bit version as an option

### Fixes

- Spelling errors
- Updated the theme file
- Added FLAC as a section and with some rules attached to it
- Added the folder SPEEDTEST with creation of 50/100/150MB files to use for speedtesting
- Changed from creation of DSA certificates to ECDSA
- Locked the server to TLS vers 1.0/1.1/1.2 consider that old SSL is no longer secure
- Created a backup folder in your glftpd folder to hold the configuration of pzs-ng including a simple update script to keep it up2date
- Minor adjustments to various scripts
- Changed section names


## 4.01 - 2013-03-22

### Fixes

- Updated the theme file
- Made it easier to implement new scripts into the installation script
- Updated Tur-Request.conf with new layout of the announce


## 4.0 - 2013-03-27

### Updated

- pzs-ng updated to v2
- glFTPD updated to 2.02RC1

### Fixes

- Many broken parts in script that are ok now
- Included TCL 8.4.18 package to be sure the bot works properly
- Optimized script and lessen the output of info during the installation

### Added

- Tur-Space 1.1
- Tur-Autonuker 1.8.2


## 3.3 - 2009-02-27

### Updated

- pzs-ng updated to r2414-v1.1.0a

### Fixes 

- Removed loop at tur-ircadmin question
- Permission error fixed in scripts dir in eggdrop dir


## 2.01 - 2005-02-09

### Updated

- pzs-ng updated to 1.331


## 2.00 - 2005-02-05

### Fixes

- All those from 1.53 that were missed (tut tut)

### Updated

- Tur-request and Project ZS-NG have been updated and seem to be working

### Other

- Why the jump in build number you ask? - Simple the installer is now 
installing glFTPD 2.00 final so why not use 2.00 as the release number
seeing as v1.x was for glFTPD 1 branch so v2.x was thought to be good
enough for this new version :)


## 1.53 - 2005-01-25

### Fixes

- Minor fixes for tur-request and the pasv_port changed to pasv_ports


## 1.52 - 2005-01-09

### Added

- tur-lastul 1.2.2

### Fixes

- Invite function

### Removed

- Epguru removed cuz it doesn't work anymore


## 1.51 - 2005-01-08

### Updated

- All other scripts up2date
- theme file updated for pzs-ng


## 1.50 - 2005-01-05

### Updated

- glFTPD > 2.0 Final
- pzs-ng > 1.131

### Removed

- Useradded removed cuz noone used it


## 1.42 - 2004-10-26

### Updated

- glFTPD > beta4
- pzs-ng > 0.828
- tur-trial3 > beta12
- eggdrop > 1.6.17

### Fixes

- You now have the option to choose what chan should be the Admin/SiteOP chan during
- tur-ircadmin install.


## 1.40 - 2004-10-22

### Updated

- Updated pzs-ng to the latest available

### Fixes

- A lot of re-coding of stuff and fixed a few small errors as well

### Todo

- Make certain questions in install bulletproof so that you can't fuck 
it up during the installation. Really a precaution for all the newbies out there ;D


## 1.34 - 2004-10-16

### Updated

- Uninstall script are changed
- Changed the look during installation
- You can now choose if your behind router or not
- removed the sitewho script cuz its built-in pzs-ng

### Fixes

- changed some text as usual


## 1.33 - 2004-10-15

### Fixes

- Just the text in installer


## 1.32 - 2004-10-11

### Updated

- Chan and irc server options are now availble during the install

### Fixes

- cmdpre adjusted after your sitename on several scripts
- minor adjustments of the announce


## 1.31 - 2004-10-10

### Updated

- tur-trial3beta6 > beta7
- rules are been made depending on what sections you choose
- You now have the option to uninstall mysql on a uninstall of this script.
- Chan and irc server options are now avaible during the install 

### Fixes

- glftpd.conf are now made after your choices of scripts
- cmdpre adjusted after your sitename on several scripts


## 1.30 - 2004-10-08

### Updated

- project-zipscript updated to pz-ngbeta2
- user creation at the end of the installation
- timezone settings availble in the install
- tur-trial updated to tur-trial3
- mysql installation built in cuz tur-trial3 demands it
- tur-quota and megatrial removed due compability issues with tur-trial3
- seen and news script added as standard
- tur-newsannounce been added for easier check of new scripts/updates

### Fixes

- Typos and small errors as usual /me <-lame

### Todo

- Fix the nuke announce, isnt fixed in pz-ngbeta2.
- Add tur-autonuke


## 1.25 - 2004-08-20

### Updated

- glFTPD updated to RC3
- psxc-imdb updated to 2.7b
- epinfo changed to epguru 2.2

### Fixes

- Typos and small errors. 
- Fixed the Y/N questions so from now on you can hit any key without breaking it.

### Todo

- Fix the nuke announce, seems like it works right but announces in the wrong way.


## 1.22 - 2004-08-31

### Updated

- Have not had a lot of time to work on the installer dude to work and other
reasons, but have managed to do so now.

- 4 new scripts added and configd right :)

- few of the scripts have been updated and checked to make sure the configs
are 100% correct and working.

### Fixes

- Have fixed 99% of the scipts so now they all work (or should do)

- Many ppl have complained they cant get ircadmin working - this was found
to have been user error - please check that you have given the glftpd account
the correct flags so it can add/remove ppl, dupe/undupe, nuke/unnuke and so it
can kill connections - bacicaly give it flags 1347abcdefg

### Todo

- Get imdb script to wor both from irc and on the ftp itself :/


## 1.21.RC2 - 2004-07-22

### Fixes

- Have tweaked the code a bit and removed stuff that weren't needed and 
solved the issues when you answered no on the questions you got hit back
to the beginning of the installation.


## 1.21.RC1 - 2004-07-01

### Fixes

- Have added new code so that when you install glFTPD and the sitebot,
all scripts are set to the right permissions 755 and are chown'd to
the name of your sitebot (where it asks for the name of your site). This 
fixed many issues where things would look like there were working but 
werent actually :-)

### Todo

- Same thing to fix with the eggdrop *sigh*
- Add more scripts :-)


## 1.21.beta1 - 2004-06-21

NOTE: This installer is made for Slackware Linux and may not even
install on your distro, at the moment the authors have no plans to release
the installer for other distros.

### Updated

- GLFTPD has been updated to 2.0 RC1
- Eggdrop has been updated to 1.6.16

All scripts listed below have been updated to the lastest versions
availble at the time of this release (see list below)

- idlebotkick  sh = 2.2
- idlebotkick  tcl=1.1
- megatrial  sh = 1.1.1
- megatrial  tcl = 1.1.1
- psxc-imdb = 2.7
- tur-botsearch  sh = 1.4
- tur-botsearch  tcl = 1.1
- tur-ircadmin  sh = 1.3.1
- tur-ircadmin  tcl = 1.1
- tur-quota  sh = 1.4
- tur-quota  tcl = 1.0
- tur-request  sh = 2.6
- tur-request  tcl = 1.5
- tur-speed  sh = 1.3
- tur-speed  tcl = 1.0
- tur-trial2  sh = 2.6
- tur-trial2 tcl = 1.0
- tur-vacation  sh = 1.7

### Fixes

- The main fix was to tur-ftpwho script which had to have the new
struct ONLINE code added to it and be recompiled so it would work
with GLFTPD 2.xx series.

If you get a problem using our installer create an issue on github describing the problem
