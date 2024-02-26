#!/bin/bash
VER=1.10
##---------------------------------------------------------##
# Tur-Vacation. A simple way to go on vacation.             #
# Tired of people telling you they are going on vacation?   #
# Tired of having to add users to excuded list in the trial #
# script? Well, NO MORE. heh. Heres how it works:           #
#                                                           #
# Users issue a command from site. 'site vacation on yes'   #
# What it mainly does is add that user to a group. That     #
# group is already (by you) excluded in your trialscript so #
# they will not be automatically delled or something.       #
#                                                           #
# But this script can do two more things to the user.       #
# 1: It can prevent him from downloading while on vacation. #
# 2: it can prevent him from uploading while on vacation.   #
# It does this by setting max_sim_down and/or max_sim_up to #
# 0.                                                        #
# Thus they can log in and look around, but not much else.  #
#                                                           #
# It also has a minimum time that must have passed since    #
# they went on vacation, until they can turn vacation off   #
# again. This is so they cant go on vacation at the end of  #
# each month.                                               #
#                                                           #
# As with v1.4, it can work together with Tur-Trial 2.1+    #
# so that if a user was on vacation for half the month, he  #
# should only need to upload half the quota limit to pass.  #
# This is not used for tur-trial v3+, but I'll leave the    #
# function for those that dont use v3 yet.                  #
# For Tur-Trial v3+, you simply define the same group as    #
# "Vacation group" as you do in this script. Thats all.     #
# See Tur-Trial v3+'s documentation.                        #
#                                                           #
# You can also issue the command 'site vacation status' to  #
# get a status report of everyone on vacation as well as    #
# manually add or remove users from vacation.               #
#                                                           #
#-[ Setup ]------------------------------------------------##
#                                                           #
# Copy this script to /glftpd/bin. Make it executable.      #
# ( chmod 755 /glftpd/bin/tur-vacation.sh )                 #
#                                                           #
# Add it to glftpd.conf as a custom command:                #
# site_cmd vacation       EXEC    /bin/tur-vacation.sh      #
# custom-vacation         !=TRiAL !=TRiAL-2 *               #
# ( just an example above to deny trial users to run it. )  #
#                                                           #
# Edit the settings below:                                  #
#                                                           #
# NOTE: All paths are seen chrooted from /glftpd. Never add #
# the full path including /glftpd to any of them.           #
#                                                           #
# USERS=     Location of users folder.                      #
#                                                           #
# LOG=       Log location for vacation on and off.          #
#            Set to "" to disable logging.                  #
#            If you plan to use bot output, set this to     #
#            glftpd.log (default).                          #
#                                                           #
# MINDUR=    Minimum duration in days before they can turn  #
#            off vacation.                                  #
#            Set this one to "" to turn the function off.   #
#                                                           #
# VACATIONGROUP= Group they will be added to. Add this in   #
#                glftpd first ( site grpadd VACATION ).     #
#                Exclude this group from quota/whatever.    #
#                                                           #
# DB=        This script will keep data about people on     #
#            vacation in this file. Create it and make sure #
#            its writable.                                  #
#            ( touch /glftpd/etc/vacation.index )           #
#            ( chmod 666 /glftpd/etc/vacation.index )       #
#                                                           #
# TMP=       Temporary storage for modifying user files.    #
#            Make sure users have full perms in here.       #
#                                                           #
# BLOCKUP=   Set max_sim_up to 0 when they go on vacation?  #
#            With this on TRUE, they cant upload.           #
#                                                           #
# BLOCKDN=   Set max_sim_down to 0 when they go on vacation?#
#            With this one TRUE, they cant download.        #
#                                                           #
# STATUS=    What do you want to trigger the status report  #
#            with? If you dont like your user to do this    #
#            then change it something only you know.        #
#                                                           #
# DATEBIN=   This is the location of the binary 'date'.     #
#            As per default, its disabled with "", meaning  #
#            it will use date from your path. If, however   #
#            you use FBSD, you'll need to compile the       #
#            SH-Utils and specify the path to gdate.        #
#                                                           #
# GL_VER=    Set to either 1 or 2, depending on which gl    #
#            version you use.                               #
#                                                           #
# ADMINFLAG= These are the flags that are allowed to force  #
#            users in and out of vacation. | seperated.     #
#            So, "1|7" would allow users with flag 1 or 7   #
#            to do this.                                    #
#            This also grants the 'status clean' command    #
#            which can be used to clean out deleted users   #
#            from the vacation list.                        #
#                                                           #
# TRIALDATA= If you are using Tur-Trial 2.1+ for monthly    #
#            quota, set this file to point to the same file #
#            as VACATIONDATA in Tur-Trial.conf. It will     #
#            use this seperate file to check how long the   #
#            user was on vacation and deduct those number   #
#            days from the users quota limit.               #
#            Set a # infront of this one to disable it.     #
#            Its disabled by default.                       #
#                                                           #
#            If you set this file, users can only go on     #
#            vacation ONCE in each month to prevent abuse.  #
#                                                           #
# USEMSS=                                                   #
# MSSCONFIG=                                                #
#            The above two commands are for people running  #
#            MSS. If you dont, set USEMSS=FALSE.            #
#            Otherwise, read the included readme.mss file.  # 
#                                                           #
# Note: Information on usage is displayed when running the  #
# script inside glftpd without any arguments. If you have   #
# the ADMINFLAG(s), then extra information will be shown.   #
#                                                           #
# This script does NOT work from shell or irc.              #
#                                                           #
##---------------------------------------------------------##
# If you want irc output to go with this, set GLLOG to your   
# glftpd.log and, if you run zipscript-c, add this to       
# dZSbot.h:                                               
# To 'set msgtypes(DEFAULT)', add VACATION and VACATIONOFF    
#
# below the other 'set chanlist', add:                        
# set chanlist(VACATION)    "#YourChan"                     
# set chanlist(VACATIONOFF) "#YourChan"                     
#
# to the other 'set disable', add:                            
# set disable(VACATION)    0                                
# set disable(VACATIONOFF) 0                                
#
# to the other 'set variables', add:
# set variables(VACATION)    "%user %prelogin %postlogin"
# set variables(VACATIONOFF) "%user %duration %prelogin %postlogin"
#
# to the other 'set announce', add:
# set announce(VACATION)     "%user goes on vacation. Have fun!"
# set announce(VACATIONOFF)  "%user is back from vacation after %duration days. Welcome back!"
# 
# %prelogin and %postlogin are just how the LOGIN field in the user
# file looked before and after. Not much to have in irc, but 
# good that its logged.
#
# Dont forget to rehash the bot.
#
##-[ Contact ]---------------------------------------------##
# http://www.grandis.nu/glftpd/ or http://grandis.mine.nu   #
##---------------------------------------------------------##
# Changelog:
#
# 1.10  : * Now with proper glftpd 2+ support. When added to
#           the vacation group, 0 is added to the end of the
#           groupline in the userfile as it should be.
#           This is added by glftpd itself whenever the user
#           logs in, but sometimes they just go on vacation
#           and log out. Some scripts does not like when the
#           0 (or 1) is missing, like tur-trial3+.
#
# 1.9.1 : * If you only used BLOCKDN="TRUE" or BLOCKUP="TRUE"
#           and not both, it would not restore the slots for the user
#           when they got back from vacation.
#
# 1.9   : * Added another check when trying to go on vacation.
#           Previously it only checked the DB if the user was already
#           on vacation. Now, it also checks that the user isnt already
#           in the vacationgroup so we dont add him again.
#
#           This was added because admins someones tried to manually remove
#           people from vacation and would screw up the system.
#           Should instead use the deluser command added in 1.8 to do this.
#
#         * DATEBIN setting can now be left at "" to use date from your path
#           instead of a predefined one.
#
#         * LOG setting renamed to GLLOG.
#
#         * MSS integration for those running that. See readme.mss for that.
#
# 1.8   : Fixed a possible date error (remove initial 0 from month).
#         Caused problems for some bash version apparently).
#
#         Added two new commands for admins. adduser and deluser.
#         With these, you can put users on and off vacation, as long
#         as you are an administrator, controlled by the ADMINFLAG
#         setting (same as for checking status).
#         Run it without arguments for help. If you have one of the
#         adminflags, you'll see the help for status/adduser/deluser.
#
#         When doing the above, the normal limit for when you can come
#         back from vacation does not count. As admin, you can add someone
#         and then remove them again just as fast. The only limit is that
#         this can only be done once a month.
#         However, should someone go on vacation by mistake, you can let
#         them "free" again using 'site vacation deluser <username>' and 
#         bypass the limit.
#
# 1.7   : Moved default location of DB from /tmp to /etc
#
#         A flaw was found in the interaction with tur-trial.
#         If the user came back from vacation, tur-trial didnt
#         know this so it just kept deducting credits from the
#         quota limit even though they were back.
#         Now, tur-vacation writes a third value in the
#         TRIALDATA file. Its when the user came back from vacation.
#         Upgrade tur-trial too if you are using the interaction.
#
# 1.6.1 : When coming back from vacation, it didnt always
#         recognize that the user are currently on vacation and
#         would tell him/her "not found in the DB and need
#         a siteop to restore you". Thats now fixed.
#
# 1.6   : Added an option when checking status: clean
#         This will clean out purged users ( not deleted ) from
#         the vacation db.
#         To set who can do this, a setting was added below:
#         ADMINFLAG='1|7'
#         Meaning that users with flag 1 and 7 can do this.
#         Encapsule in '' and seperate flags with |
#
#         When checking status, it will show if a user is deleted
#         ( flag 6 ) and those deleted & purged ( no userfile ).
#
#         Changed it into proc's instead of just going from top
#         to bottom. Helps upgrades etc.
#
#         Changed all awk's to cut. Changed all grep -w FLAGS
#         to grep "^FLAGS "
#
# 1.5   : Some changes in regards to TRIALDATA, added in 1.4.
#
#         A user can only go on vacation once every month.
#
#         If a user is already in the TRIALDATA file when
#         going on vacation, it will remove previous instances
#         and just add this new one.
#
#         Some distros does not have a GNU compliant date bin
#         which was required for the TRIALDATA part. It made it
#         impossible to use date to get the number of seconds
#         sometimes. I now make those calculations manually
#         instead, just using 'date +%s' so it should work
#         on, for instance, freebsd too.
#
#         Also added the setting DATEBIN so you can specify
#         its location.
#
#         For reasons unknown, I removed the userdata from
#         the TRIALDATA file when you went OFF vacation.
#         That should ofcourse no be done.
#
# 1.4   : Added TRIALDATA. A seperate DB file used by 
#         Tur-Trial 2.1+ to deduct credits from quotalimit
#         if the user was on vacation this month.
#         Its disabled with a # by default. If you enable it,
#         create the file and chmod 777 on it.
#
#         NOTE: If you are just upgrading, current vacation
#         users will NOT be effected by this. They need to
#         get out of vacation and back in again for this to
#         work.
#
# 1.3   : It switched the upload and download slots when a 
#         user came back from vacation.. oops.
#
# 1.2   : Counted 12 hours instead of 24 per day, giving the
#         wrong days count in status check.
#
# 1.1   : When doing a status check, it kept going down the
#         script instead of exiting. Not a big deal as nothing
#         happened *usually*.
#############################################################

USERS=/ftp-data/users            ## Users location (if USEMSS=FALSE)
GLLOG=/ftp-data/logs/glftpd.log  ## Log location
MINDUR=14                         ## Min days to be on vaca..
VACATIONGROUP=VACATION           ## Group to add to.
DB=/etc/vacation.index           ## Database file.
TMP=/tmp                         ## Temporary location.
BLOCKUP=TRUE                     ## No uploading?
BLOCKDN=TRUE                     ## No downloading?
STATUS=status                    ## Check status with 'site ?'
ADMINFLAG='1|7'                  ## Used that can run 'clean'

DATEBIN=""                       ## Location of date executable.
GL_VER=2                         ## Glftpd version. 1 or 2.


#--[ Tur-Trial v2 interaction ]--#
# Remove below # to enable Tur-Trial 2.1+ interaction (Not used for tur-trial 3+).
# TRIALDATA="/etc/quota_vacation.db"

#--[ MSS Interaction ]--------#
# See readme.mss for more info.
USEMSS=FALSE
MSSCONFIG="/bin/mss-hub.conf"

##############################################################
# No changes below here, unless you want to change something #
# In which case, this text is useless and.. hmm. bah.        #
##############################################################

if [ "$USEMSS" = "TRUE" ]; then
  if [ ! -e "$MSSCONFIG" ]; then
    echo "Error. Cant read MSS config $MSSCONFIG"
    exit 1
  fi
  if [ -z "$MSSROLE" ]; then
    if [ "`echo "$MSSCONFIG" | grep "\-hub\.conf$"`" ]; then
      MSSROLE="HUB"
    elif [ "`echo "$MSSCONFIG" | grep "\-slave\.conf$"`" ]; then
      MSSROLE="SLAVE"
    else
      echo "Error. Could not detirmine the role of this mss box."
      echo "Add a setting to tur-vacation that says either"
      echo "MSSROLE=HUB or MSSROLE=SLAVE"
      exit 1
    fi
  fi

  . $MSSCONFIG

  if [ "$MSSROLE" = "HUB" ]; then
    USERS="$GLUSERS"
    DB=/etc/vacation.index
    if [ "$TRIALDATA" ]; then
      TRIALDATA="/etc/quota_vacation.db"
    fi
    ACTIONS="/etc"
  elif [ "$MSSROLE" = "SLAVE" ]; then
    USERS="$USERSOURCE"
    if [ -z "`grep "^FLAGS\ " $USERS/$VERIFYUSER`" ]; then
      echo "Hub connection seems down. Try again later."
      if [ "`echo "$FLAGS" | grep "1"`" ]; then
        echo "Flag 1 detected."
        echo "Reason for error message:"
        echo "Defined VERIFYUSER in $MSSCONFIG ( $VERIFYUSER ) cant not be"
        echo "read from $USERSOURCE"
        echo "$USERS is the defined path for USERSOURCE in $MSSCONFIG"
      fi
      exit 1
    fi
    DB="$PASSWDSOURCE/vacation.index"
    if [ "$TRIALDATA" ]; then
      TRIALDATA="$PASSWDSOURCE/quota_vacation.db"
    fi

    GLLOG="$FTP_DATA_EXT/logs/glftpd.log"

    ACTIONS="$PASSWDSOURCE"

    if [ ! -e "$FETCHLOGSDIR/mss-slavestatus.db" ]; then
      echo "Error. Can not find a list of slaves. Try again later."
      if [ "`echo "$FLAGS" | grep "1"`" ]; then
        echo "Flag 1 detected"
        echo "Do you have mss-report.sh loaded on the hub?"
        echo "The list it produces ( $FETCHLOGSDIR/mss-slavestatus.db )"
        echo "is the list we read to get the defined slaves since we cant reach"
        echo "mss-hub.conf from here."
        echo "Please see the mss README for how to set up mss-report.sh on the hub."
      fi
      exit 1
    else
      SLAVES="`grep "^\*\*" $FETCHLOGSDIR/mss-slavestatus.db | cut -d '=' -f2`"
      if [ -z "$SLAVES" ]; then
        echo "Error. Could not get a list of slaves."
        exit 1
      fi
    fi
  fi
fi

## Check if we can write to userfile.
if [ ! -w $USERS/$USER ]; then
  echo "Error. Your userfile can not be edited. Bug siteops to fix perms."
  exit 1
fi

if [ "$TRIALDATA" ]; then
  if [ ! -e "$TRIALDATA" ]; then
    echo "Please create the TRIALDATA file and set 777 on it."
    exit 1
  elif [ ! -w "$TRIALDATA" ]; then
    echo "Can not write to the TRIALDATA file. Set 777 on it."
    exit 1
  fi
fi

if [ -z "$DATEBIN" ]; then
  DATEBIN="date"
fi

## Test the DATEBIN
if [ -z "`$DATEBIN`" ]; then
  echo "Error. Cant execute $DATEBIN. Make sure it exists and is executable."
  exit 1
fi

## No argument? Show help.
proc_help() {
  echo "############################################################"
  echo "# Vacation System $VER by Turranius."
  echo "# This script allows you to set yourself in vacation mode."
  echo "# During that time, you will be excluded from any quotas"
  if [ "$BLOCKUP" = "TRUE" -a "$BLOCKDN" = "TRUE" ]; then
    echo "# and you can not upload or download."
    SAIDIT="YES"
  fi
  if [ "$SAIDIT" != "YES" ]; then
    if [ "$BLOCKUP" = "TRUE" ]; then
      echo "# and you will not be able to upload while on vacation."
    fi
    if [ "$BLOCKDN" = "TRUE" ]; then
      echo "# and you will not be able to download while on vacation"
    fi
  fi
  if [ "$MINDUR" ]; then
    echo "# If you set yourself on vacation, $MINDUR days must pass"
    echo "# before you are allowed to change back."
  fi
  echo "#"
  echo "# To enable vacation, issue 'site vacation on'"
  echo "# To disable it, issue 'site vacation off'"
  if [ "`grep "^FLAGS " "$USERS/$USER" | egrep "$ADMINFLAG"`" ]; then
    echo "#"
    echo "# To check users on vacation, issue 'site vacation status'"
    echo "# To force a user on/off vacation, issue 'site vacation adduser/deluser <username>'"
  fi
  exit 0
} ## End proc_help


## Show status for everyone on vacation.
proc_status() {
  if [ ! -r "$DB" ]; then
    echo "Can not read from $DB. Check perms or if the file even exists.."
    exit 1
  fi

  if [ -z "$( grep ^ $DB )" ]; then
    echo "No users on vacation..."
    exit 0
  fi
 
  if [ -z "$ADMINFLAG" ]; then
    ADMINFLAG="none"
  fi

  for each in `cat $DB`; do
    if [ "$each" ]; then
      user="$( echo $each | cut -d '^' -f1 )"
      otime="$( echo $each | cut -d '^' -f4 )"
      ominutes=$[$otime/60]
      ohours=$[$ominutes/60]
      odays=$[$ohours/24]
      
      time="$( $DATEBIN +%s )"
      minutes=$[$time/60]
      hours=$[$minutes/60]
      days=$[$hours/24]

      nhours=$[$hours-$ohours]
      ndays=$[$days-$odays]
      unset DELMSG
      if [ ! -e "$USERS/$user" ]; then
        FOUNDPURGED=TRUE
        DELMSG=" - Deleted and Purged?!"
        if [ "clean" = "$A2" ]; then
          if [ "$( grep "^FLAGS " "$USERS/$USER" | egrep "$ADMINFLAG" )" ]; then
            if [ ! -w "$DB" ]; then
              echo "Error. No write permissions on DB file $DB"
            else
              echo " "
              echo "Removing $user from vacation db."
              grep -v "^$user\^" "$DB" > "$TMP/vacationdata.tmp"
              cp -f "$TMP/vacationdata.tmp" "$DB"
              rm -f "$TMP/vacationdata.tmp"
            fi
          else
            if [ -z "$SAIDERR" ]; then
              echo "You do not have access to cleaning up the vacation DB."
              SAIDERR=TRUE
            fi
          fi
        fi
      elif [ "$( grep "^FLAGS " "$USERS/$USER" | grep "6" )" ]; then
        DELMSG=" - Deleted (Flag 6)"
      fi
      echo "$user has been gone for $ndays days ( $nhours hours )$DELMSG"
    fi
  done

  if [ -z "$user" ]; then
    echo "No users on vacation? DB empty."
  fi

  if [ "$A2" != "clean" -a "$FOUNDPURGED" = "TRUE" ]; then
    if [ "$( grep "^FLAGS " "$USERS/$USER" | egrep "$ADMINFLAG" )" ]; then
      echo "Issue 'status clean' to clean out purged users."
    fi
  fi

  exit 0
} ## End proc_status


## Going on vacation
proc_on() {
  if [ "$A2" != "yes" -a "$ADMINMODE" != "TRUE" ]; then
    echo "Are you sure?"
    if [ "$MINDUR" != "" ]; then
      echo "You will not be able to change back for $MINDUR days."
    fi
    if [ "$BLOCKUP" = "TRUE" ]; then
      echo "You will not be able to upload while on vacation."
    fi
    if [ "$BLOCKDN" = "TRUE" ]; then
      echo "You will not be able to download while on vacation."
    fi
    if [ "$TRIALDATA" ]; then
      echo "The time you are away will be deducted from your quota on the month you are back."
    fi
    echo "To verify and agree to those terms; issue 'site vacation on yes'"
    exit 0
  fi
  
  if [ ! -w "$DB" ]; then
    echo "Error. No permissons to edit vacation database. Bug siteops to fix perms"
    exit 1
  fi

  if [ "$GLLOG" ]; then
    if [ ! -w "$GLLOG" ]; then
      echo "Error. Can not write to logfile. Ask siteops to fix perms on it."
      exit 1
    fi
  fi

  if [ "$TRIALDATA" ]; then
    if [ ! -w "$TRIALDATA" ]; then
      echo "Error. Can not write to TRIALDATA file. Ask a siteop to fix perms on it."
      exit 1
    fi
  fi

  if [ "$( grep "^$USER\^" $DB )" ]; then
    echo "You are already on vacation.. turn that off first"
    exit 1
  fi

  if [ "`grep "^GROUP $VACATIONGROUP$" $USERS/$USER`" ]; then
    echo "Hmm, seems we have some inconsistensies.. You are already in the $VACATIONGROUP group"
    echo "but no information about you in the DB..."
    echo "Get someone to remove you from the $VACATIONGROUP group and check your up/down slots."
    exit 1
  fi
 
  if [ "$TRIALDATA" ]; then
    unset TRIALINFO
    TRIALINFO="$( grep "^$USER^" $TRIALDATA | cut -d '^' -f2 )"
    if [ "$TRIALINFO" ]; then

      SECONDSNOW="`$DATEBIN +%s`"
      DAYOFMONTH="`$DATEBIN +%d | sed -e 's/^0//'`"
      SECONDSSOFAR=$[$DAYOFMONTH*86400]
      MONTHSTARTSEC=$[$SECONDSNOW-$SECONDSSOFAR]

      if [ "$TRIALINFO" -gt "$MONTHSTARTSEC" ]; then
        echo "You can only go on vacation once a month!"
        exit 1
      fi
    fi      
  fi

  FIRST="$( grep "^LOGINS " $USERS/$USER | cut -d ' ' -f2 )"
  SECOND="$( grep "^LOGINS " $USERS/$USER | cut -d ' ' -f3 )"
  DNSLOTS="$( grep "^LOGINS " $USERS/$USER | cut -d ' ' -f4 )"
  UPSLOTS="$( grep "^LOGINS " $USERS/$USER | cut -d ' ' -f5 )"
  
  TIMENOW="$( $DATEBIN +%s )"

  echo $USER"^"$UPSLOTS"^"$DNSLOTS"^"$TIMENOW >> $DB

  ## Add to TRIALDATA file. Remove previous ones if hes in there already.
  if [ "$TRIALDATA" ]; then
    TRIALINFO="$( grep "^$USER^" $TRIALDATA | cut -d '^' -f2 )"
    if [ "$TRIALINFO" ]; then
      grep -vw "^$USER" $TRIALDATA > $TMP/trialdata.tmp
      cp -f $TMP/trialdata.tmp $TRIALDATA
      rm -f $TMP/trialdata.tmp
    fi
    echo $USER"^"$TIMENOW >> $TRIALDATA
  fi

  if [ -z "$( grep "^$USER\^" $DB )" ]; then
    echo "Could not verify saved data. Contact siteops."
    echo "Write to $DB with your info must have failed."
    exit 1
  fi

  if [ "$TRIALDATA" ]; then
    if [ -z "$( grep "^$USER\^" $TRIALDATA )" ]; then
      echo "Could not verify saved data. Contact siteops."
      echo "Write to $TRIALDATA with your info must have failed."

      grep -vw "^$USER" $DB > $TMP/db.tmp
      cp -f $TMP/db.tmp $DB
      rm -f $TMP/db.tmp

      exit 1
    fi
  fi

  BEFORELOGINS="$FIRST $SECOND $DNSLOTS $UPSLOTS"

  if [ "$BLOCKDN" = "TRUE" ]; then
    DNSLOTS="0"
  fi

  if [ "$BLOCKUP" = "TRUE" ]; then
    UPSLOTS="0"
  fi 

  AFTERLOGINS="$FIRST $SECOND $DNSLOTS $UPSLOTS"

  if [ "$GLLOG" ]; then
    echo `$DATEBIN "+%a %b %e %T %Y"` VACATION: \"$USER\" \"$BEFORELOGINS\" \"$AFTERLOGINS\"  >> $GLLOG
  fi

  sed -e "s/^LOGINS $BEFORELOGINS/LOGINS $AFTERLOGINS/" $USERS/$USER > $TMP/$USER.tmp
  cp -f $TMP/$USER.tmp $USERS/$USER
  rm -f $TMP/$USER.tmp
  if [ "$GL_VER" = "1" ]; then
    echo "GROUP $VACATIONGROUP" >> $USERS/$USER
  else
    echo "GROUP $VACATIONGROUP 0" >> $USERS/$USER
  fi
  echo "All done. Issue 'site vacation off' when back."

  if [ "$USEMSS" = "TRUE" ]; then
    for slave in $SLAVES; do
      echo "SYNC BASIC $USER" >> $ACTIONS/$slave.actions
    done
  fi

  exit 0
} ## End proc_on

proc_off() {
  if [ ! -w "$DB" ]; then
    echo "Can not write to vacation db. Ask siteops to fix perms."
    exit 1
  fi 

  if [ "$TRIALDATA" ]; then
    if [ ! -w "$TRIALDATA" ]; then
      echo "Can not write to TRIALDATA file. Ask siteops to fix perms."
      exit 1
    fi
  fi

  if [ -z "$( grep "^$USER^" $DB )" ]; then
    if [ -z "$( grep "GROUP $VACATIONGROUP" $USERS/$USER )" ]; then
      echo "You are not marked for vacation..."
      exit 1
    else
      echo "Can not find you in vacation database. You need a siteop to restore you."
      exit 1
    fi
  fi

  USERRAWDATA="$( grep "^$USER\^" $DB )"

  if [ -z "$USERRAWDATA" ]; then
    echo "Couldnt grab your previous info from vacation db. Ask a siteop to fix perms or fix you manually."
    exit 1
  fi

  FIRST="$( grep "^LOGINS " $USERS/$USER | cut -d ' ' -f2 )"
  SECOND="$( grep "^LOGINS " $USERS/$USER | cut -d ' ' -f3 )"
  ODNSLOTS="$( grep "^LOGINS " $USERS/$USER | cut -d ' ' -f4 )"
  OUPSLOTS="$( grep "^LOGINS " $USERS/$USER | cut -d ' ' -f5 )"

  DNSLOTS="$( echo $USERRAWDATA | cut -d '^' -f2 )"
  UPSLOTS="$( echo $USERRAWDATA | cut -d '^' -f3 )"
  TIMETHEN="$( echo $USERRAWDATA | cut -d '^' -f4 )"
  TIMENOW="$( $DATEBIN +%s )"
  
  if [ "$TIMETHEN" = "" -o "$TIMENOW" = "" ]; then
    echo "Error. Can not see when you went on vacation, or cant check what time it is now."
    exit 1
  fi

  if [ "$MINDUR" ]; then
    TIMETHEN=$[$TIMETHEN/60]
    TIMETHEN=$[$TIMETHEN/60]
    TIMETHEN=$[$TIMETHEN/24]
    TIMENOW=$[$TIMENOW/60]
    TIMENOW=$[$TIMENOW/60]
    TIMENOW=$[$TIMENOW/24]

    DIFFERENCE=$[$TIMENOW-$TIMETHEN]
 
    if [ "$ADMINMODE" != "TRUE" ]; then
      if [ "$DIFFERENCE" -lt "$MINDUR" ]; then
        echo "Minimum duration not yet reached."
        echo "You went on vacation $DIFFERENCE days ago and minimum is $MINDUR days"
        echo "If you feel this is in error, contact your favorite siteop."
        exit 1
      fi
    fi
  fi
 
  if [ "$ODNSLOTS" != "$DNSLOTS" ] || [ "$OUPSLOTS" != "$UPSLOTS" ]; then
    BEFORELOGINS="$FIRST $SECOND $ODNSLOTS $OUPSLOTS"
    AFTERLOGINS="$FIRST $SECOND $UPSLOTS $DNSLOTS"
    sed -e "s/^LOGINS $BEFORELOGINS/LOGINS $AFTERLOGINS/" $USERS/$USER > $TMP/$USER.tmp
    cp -f $TMP/$USER.tmp $USERS/$USER
    rm -f $TMP/$USER.tmp
  fi

  if [ "$( grep "^GROUP $VACATIONGROUP" $USERS/$USER )" ]; then
    if [ "$GL_VER" = "1" ]; then
      grep -vw "^GROUP $VACATIONGROUP" $USERS/$USER > $TMP/$USER.2.tmp
    else
      grep -v "^GROUP $VACATIONGROUP " $USERS/$USER > $TMP/$USER.2.tmp
    fi
    cp -f $TMP/$USER.2.tmp $USERS/$USER
    rm -f $TMP/$USER.2.tmp
  fi

  grep -vw "^$USER" $DB > $TMP/db.tmp
  cp -f $TMP/db.tmp $DB
  rm -f $TMP/db.tmp


  if [ "$TRIALDATA" ]; then
    OLDLINE=`grep "^$USER\^" $TRIALDATA`
    if [ -z "$OLDLINE" ]; then
      echo "Could not verify saved data in TRIALDATA. Contact siteops."
      echo "Write to $TRIALDATA with your info must have failed."
    else
      grep -vw "^$USER" $TRIALDATA > $TMP/trialdata.tmp
      cp -f $TMP/trialdata.tmp $TRIALDATA
      rm -f $TMP/trialdata.tmp
      TIMENOW=`date +%s`
      echo "$OLDLINE^$TIMENOW" >> $TRIALDATA
    fi
  fi

  if [ "$GLLOG" ]; then
    echo `$DATEBIN "+%a %b %e %T %Y"` VACATIONOFF: \"$USER\" \"$DIFFERENCE\" \"$BEFORELOGINS\" \"$AFTERLOGINS\"  >> $GLLOG
  fi
 
  echo "Welcome back!"

  if [ "$USEMSS" = "TRUE" ]; then
    for slave in $SLAVES; do
      echo "SYNC BASIC $USER" >> $ACTIONS/$slave.actions
    done
  fi

  exit 0
} ## End proc_on


## Set args into A1 and A2, removing all control chars for safety.
A1=`echo "$1" | tr -d '[:cntrl:]'`
A2=`echo "$2" | tr -d '[:cntrl:]'`

proc_usercheck() {
  if [ -z "`grep "^FLAGS " "$USERS/$OUSER" | egrep "$ADMINFLAG"`" ]; then
    echo "Error. You do not have access to this command."
    exit 1
  fi
  if [ -z "$USER" ]; then
    echo "Specify a user to add/remove too please"
    proc_help
    exit 1
  fi

  if [ ! -e "$USERS/$USER" ]; then 
    echo "Error. No user called $USER - Try again."
    exit 1
  elif [ ! -w "$USERS/$USER" ]; then
    echo "Error. Userfile for $USER can not be edited. Bug siteops to fix perms."
    exit 1
  fi
  echo "Looking good. Trying to emulate $USER"
  ADMINMODE="TRUE"

}

## Run process depending on A1 arg.
case $A1 in
  [oO][nN]) proc_on; exit 0 ;;
  [oO][fF][fF]) proc_off; exit 0 ;;
  [sS][tT][aA][tT][uU][sS]) proc_status; exit 0 ;;
  [aA][dD][dD][uU][sS][eE][rR]) OUSER="$USER"; USER="$2"; proc_usercheck; proc_on; exit 0;;
  [dD][eE][lL][uU][sS][eE][rR]) OUSER="$USER"; USER="$2"; proc_usercheck; proc_off; exit 0;;
  *) proc_help; exit 0
esac

exit 0