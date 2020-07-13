#!/bin/bash
VER=1.2
###################################################################################
# Tur-Free. A replacement !free/!df command for irc/shell.                        #
# This will show total/used/free space in the sections you define.                #
# You may mash multiple drives into one section, if you for instance want to show #
# space in some archive which is part of multiple drives.                         #
#                                                                                 #
#-[ Installation ]----------------------------------------------------------------#
#                                                                                 #
# - Copy tur-free.sh to /glftpd/bin and make it executable by the person running  #
#   the bot.                                                                      #
# - Copy tur-free.tcl to your bots scripts dir and load in the bots config file.  #
#   Rehash the bot. If tur-free.sh is not in /glftpd/bin you have to edit the     #
#   and set the path to it there. Default triggers are !df and !free.             #
# - Config the settings below:                                                    #
#                                                                                 #
# SECTIONS=  The heart of the script. Its basically SECTIONNAME:DISK1:DISK2:DISK3 #
#            By that I mean: NAME is just the name of the section. For DISK, run  #
#            'df -Pm' from shell. You'll see all your disks and where they are    #
#            mounted. DISK1 is anything unique in that string, like the /dev/hd?  #
#            text. You'll understand once you see the examples below.             #
#                                                                                 #
#            Grep Experts: You can use anything in the line as a DISK. I'll grep  #
#            the whole line. So if you have multple disks all mounted somewhere   #
#            that share the same name ( like /DIVX/ ), you can just add DIVX as a #
#            DISK and I'll merge all of them together under the same NAME.        #
#            Be careful not to add two similar words twice. Like NAME:DIVX:DIV or #
#            result might be doubled.                                             #
#                                                                                 #
#            You can have up to 19 DISK's under the same name. More then that     #
#            will not be calculated.                                              #
#            Hint: If you want a total output, make one of them: TOTAL:/site      #
#                  and it will merge every disk mounted under /site under the     #
#                  name TOTAL                                                     #
#                                                                                 #
# COMMAND=   This is the df (diskfree) command that will be executed to get the   #
#            list. By default its just 'df -Pm' which means Posix output and all  #
#            numbers in megabytes. Read up on df if you like. You can, for        #
#            instance, add --exclude-type=smbfs if you do not want it to output   #
#            any drives mounted using Samba. This will speed up the execution of  #
#            of the initial list building.                                        #
#            Just remember that it needs MB output.                               #
#                                                                                 #
# CALCFREE=  TRUE/FALSE. With TRUE, it will calculate free space by subtracting   #
#            used space from total space. This usually looks better as it adds up #
#            but might not be 100% correct ( bit/byte conversion etc ). Setting   #
#            it to FALSE will read that info from df, but wont always count up.   #
#                                                                                 #
# GIGOUTPUT= Give all numbers in gigabyte instead of MB? This will cause 'bc' to  #
#            be executed so I can do a split of SPLITBY (see below) on the MB     #
#            number that df outputs.                                              #
#                                                                                 #
# SPLITBY=   When reading the info from df, it gets the MB. If GIGAOUTPUT above   #
#            is TRUE, it will split this by 1024 (default) to get GB, but since   #
#            df reports actual size, not size printed on disk                     #
#            (120GB is 112 actually), it will look a little less then you thought.#
#            Setting this to something like 950 will cause it to look a little    #
#            better. The less you set this to, the more space it will say you     #
#            have and vice versa.                                                 #
#                                                                                 #
# DECIMALS=  When GIGOUTPUT is TRUE, bc can make a lot of decimals when redoing   #
#            the numbers to GB. This will force it to stop at 2 decimals but I    #
#            put this here so you can force another number. Set it to 0 if you do #
#            not want any decimals in the final output.                           #
#            This has no effect unless GIGOUTPUT is true cause df by itself does  #
#            not use decimals.                                                    #
#                                                                                 #
# ONELINE=   Do you want the entire output on one line? If TRUE, it will just     #
#            output one single line and it might be messy with lots of sections.  #
#            If FALSE, it will give one section per line.                         #
#                                                                                 #
# DEBUG=     TRUE/FALSE. Setting this to TRUE will display what it finds and how  #
#            it calculates. Good if you dont get the values you had hoped for.    #
#            Run it from shell if you set this to TRUE.                           #
#                                                                                 #
# SITENAME=  Just the name of the site so we can use $SITENAME in the output...   #
#                                                                                 #
# HEADER=    This will be shown before any other text output. If you are using    #
#            ONELINE="TRUE", you will need to clean this up a little since they   #
#            are by default written for ONLINE="FALSE", which is the default.     #
#            If you dont want these, set them to ="" or put a # infront of the    #
#            line.                                                                #
#                                                                                 #
# FOOTER=    Same as with HEADER. If you can figure this one out, I'll pray for   #
#            your soul.                                                           #
#                                                                                 #
# You may use %BOLD% in any of the outputs to start and stop bold text mode.      #
#                                                                                 #
# Right after all the settings is the proc_output. Thats the final output.        #
# I'm too lazy to make them options so change here if you want it too look        #
# anything other then the default. If you play on using ONELINE="TRUE", you will  #
# most likely want to change this to make it look better on one line.             #
#                                                                                 #
# When running from shell or irc and you give no arguments, it will show free     #
# space in all defined sections. You can also select one of the names and it will #
# show only that section. If you give a section that is not defined, it will list #
# all defined sections.                                                           #
# If you select one section only, the HEADER and FOOTER will not be displayed.    #
#                                                                                 #
# Defining a DISK that does not exist will result in 0 results on that NAME. This #
# means the DISK was not found when doing 'df' and its probably not mounted or    #
# something. Set DEBUG=TRUE and run it to see what it finds.                      #
#                                                                                 #
#---------------------------------------------------------------------------------#
# Contact: Turranius on efnet/linknet. Usually in #glftpd on efnet.               #
# http://www.grandis.nu/glftpd                                                    #
#                                                                                 #
#-[ Changelog ]-------------------------------------------------------------------#
#                                                                                 #
# 1.2   : Fix: If GIGOUTPUT was false, it would not show MB after the values in   #
#              the last section defined. Thanks inoxxx for reporting it.          #
#                                                                                 #
# 1.1   : Add: Added setting DEBUG (TRUE/FALSE). This will display what it finds  #
#              when calculating. Good to verify that it finds all the disks.      #
#                                                                                 #
#         Add: Added setting CALCFREE (TRUE/FALSE) to make the free space look    #
#              better. Read about it in the text above.                           #
#                                                                                 #
#         Add: Added setting SPLITBY (num). When reading the MB sizes from df,    #
#              this is what I will split it with to get GB. Read about it above.  #
#                                                                                 #
#         Fix: If the disk is totally empty, it will display 0.0 in used space.   #
#                                                                                 #
# 1.0   : Initial release.                                                        #
#                                                                                 #
#-[ Settings ]--------------------------------------------------------------------#

## NAME:DISK1:DISK2:DISK3:etc:etc
## Do not use spaces anywhere. Make sure it starts with " and ends with "
## One line per section ( or a space inbetween. Whatevah ).
SECTIONS="
"

COMMAND="df -Pm"
CALCFREE=FALSE
GIGOUTPUT=TRUE
SPLITBY="1024 / 1024"
DECIMALS=2
ONELINE=FALSE
DEBUG=FALSE
SITENAME="changeme"
RED=4
DGREY=14

#HEADER="%BOLD%$SITENAME [DF] -%BOLD% Free Space Report"
#FOOTER="%BOLD%$SITENAME [DF] -%BOLD% Presented to you by Tur-Free $VER"

###################################################################################
# Unless you want to change standard text output, dont change anything below here #
# Otherwise, look right below this line for the output..                          #
###################################################################################

## How to echo the final results.
proc_output() {

  ## If ONELINE is TRUE, the below will be the echoed (2 lines to change).

  if [ "$ONELINE" = "TRUE" ]; then
    if [ -z "$MSG" ]; then
      MSG="Section $LASTSECTION : [Total: $total] [Used: $used] %BOLD%[Free: $free]%BOLD%"
    else
      MSG="$MSG <-> Section $LASTSECTION : [Total: $total] [Used: $used] %BOLD%[Free: $free]%BOLD%"
    fi

  ## If ONELINE is FALSE, this will be outputted for each section. Dont change the sed at the end.

  else
    #echo "%BOLD%$SITENAME [DF] -%BOLD% Section %BOLD%$LASTSECTION%BOLD% : [Total: $total] [Used: $used] %BOLD%[Free: $free]%BOLD%" | sed -e s/%BOLD%/$BOLD/g
     echo "${RED}%BOLD%$LASTSECTION%BOLD%${DGREY}:${RED} $free ${DGREY}of${RED} $total ${DGREY}free - ${DGREY}Used${RED} $used" | sed -e s/%BOLD%/$BOLD/g
  fi
}

###################################################################################
# Dont change shit below here, or I'll skullfuck ya. hehe. Naah, change whatever  #
# you like.                                                                       #
###################################################################################

## Procedure for recalculating to GB if thats enabled.
proc_recalc() {
  AMOUNT="TB"
  total="$( echo "$total / $SPLITBY" | bc -l )"

  used="$( echo "$used / $SPLITBY" | bc -l )"
  if [ "$CALCFREE" = "TRUE" ]; then
    free="$( echo "$total - $used" | bc -l )"
  else
    free="$( echo "$free / $SPLITBY" | bc -l )"
  fi
  firstnum="$( echo $total | cut -d'.' -f1 )"
  if [ "$DECIMALS" = "0" ]; then
    total="$firstnum $AMOUNT"
  else
    secondnum="$( echo $total | cut -d'.' -f2 | cut -b1-$DECIMALS )"
    if [ -z "$firstnum" ]; then
      total="0.$secondnum $AMOUNT"
    else
      total="$firstnum.$secondnum $AMOUNT"
    fi
  fi

  firstnum="$( echo $used | cut -d'.' -f1 )"
  if [ "$DECIMALS" = "0" ]; then
    used="$firstnum $AMOUNT"
  else
    secondnum="$( echo $used | cut -d'.' -f2 | cut -b1-$DECIMALS )"
    if [ -z "$firstnum" ]; then
      used="0.$secondnum $AMOUNT"
    else
      used="$firstnum.$secondnum $AMOUNT"
    fi
  fi

  firstnum="$( echo $free | cut -d'.' -f1 )"
  if [ "$DECIMALS" = "0" ]; then
    free="$firstnum $AMOUNT"
  else
    secondnum="$( echo $free | cut -d'.' -f2 | cut -b1-$DECIMALS )"
    if [ -z "$firstnum" ]; then
      firstnum="0"
    fi
    free="$firstnum.$secondnum $AMOUNT"
  fi
}

## Procedure to calculate amounts.
proc_calc() {
  dfsection="$( echo $rawlist | grep "$CALCSECTION" )"
  if [ "$( echo "$dfsection" | grep "$CALCSECTION" )" ]; then
     totalnr="$( echo $dfsection | cut -d'^' -f2 )"
     usednr="$( echo $dfsection | cut -d'^' -f3 )"
     freenr="$( echo $dfsection | cut -d'^' -f4 )"
     total="$( echo "$total + $totalnr" | bc -l )"
     free="$( echo "$free + $freenr" | bc -l )"
     used="$( echo "$used + $usednr" | bc -l )"

     if [ "$DEBUG" = "TRUE" ]; then
       echo "Name: $SECTIONNAME"
       echo "Selection: $rawsection"
       echo "From df: $rawlist" | tr -s '^' ' '
       echo "total: $total"
       echo "used: $used"
       echo "free: $free"
       echo "-----------------------------------------"
     fi

  fi
}

## Define char for bold. Shouldnt be changed.
BOLD=""

## Check if theres a selected section. If not, run all as usual
## If there is one, set SECTIONS to that one only so only that one
## gets displayed. Also unset HEADER and FOOTER so they are not 
## displayed ( remove the 2 unset lines to allow them to show ).
if [ "$1" ]; then
  for section1 in $SECTIONS; do
    section2="$( echo $section1 | cut -d':' -f1 )"
    if [ -z "$ALLSECTIONS" ]; then
      ALLSECTIONS="$section2"
    else
      ALLSECTIONS="$ALLSECTIONS $section2"
    fi
    if [ "$( echo $section2 | grep -wi "$1" )" ]; then
      SECTIONS="$section1"
      SINGLESECTION="TRUE"
      unset HEADER
      unset FOOTER
    fi
  done
  if [ "$SINGLESECTION" != "TRUE" ]; then
    echo "No section defined. Valid sections are - $ALLSECTIONS - or no argument for all."
    exit 0
  fi
fi

## Build initial list.
LIST="$( $COMMAND | tr -s ' ' '^' )"

## Get the first section in list...
for rawsection in $SECTIONS; do
  LASTSECTION="$( echo $rawsection | cut -d':' -f1 )"
  break
done

## Reset numbers for first run
free=0; total=0; used=0

## Say the header if it isnt disabled or set for one line only...
if [ "$ONELINE" != "TRUE" ]; then
  if [ "$HEADER" ]; then
    HEADER="$( echo $HEADER | sed -e s/%BOLD%/$BOLD/g )"
    echo "$HEADER"
  fi
fi

## Read each section defined.
for rawsection in $SECTIONS; do
  ## Get the name of this section.
  SECTIONNAME="$( echo $rawsection | cut -d':' -f1 )"

  ## Dont talk or reset numbers until all drives for this section
  ## is processed.
  if [ "$LASTSECTION" != "$SECTIONNAME" ]; then
    AMOUNT="MB"
    if [ "$GIGOUTPUT" = "TRUE" ]; then
      proc_recalc
    else
      free="$free MB"
      total="$total MB"
      used="$used MB"
    fi

    if [ "$DEBUG" = "TRUE" ]; then
      echo " "
      echo "Final output:"
    fi
    proc_output

    free=0
    total=0
    used=0
  fi

  ## Grab the first drive from this sectionname.
  SECTION1="$( echo $rawsection | cut -d':' -f2 )"

  for rawlist in $LIST; do
    ## Do calculation for first section.
    if [ -z "$SECTION1" ]; then
      echo "Error: Section $rawsection has nothing to search on. Dont end with a :"
      exit 0
    fi

    CALCSECTION="$SECTION1"
    proc_calc

    ## Check if more drives are defined for this section and if so
    ## calculate them together.
    SECTION2="$( echo $rawsection | cut -d':' -f3 )"
    if [ "$SECTION2" ]; then
     CALCSECTION="$SECTION2"
     proc_calc
     SECTION3="$( echo $rawsection | cut -d':' -f4 )"
     if [ "$SECTION3" ]; then
      CALCSECTION="$SECTION3"
      proc_calc
      SECTION4="$( echo $rawsection | cut -d':' -f5 )"
      if [ "$SECTION4" ]; then
       CALCSECTION="$SECTION4"
       proc_calc
       SECTION5="$( echo $rawsection | cut -d':' -f6 )"
       if [ "$SECTION5" ]; then
        CALCSECTION="$SECTION5"
        proc_calc
        SECTION6="$( echo $rawsection | cut -d':' -f7 )"
        if [ "$SECTION6" ]; then
         CALCSECTION="$SECTION6"
         proc_calc
         SECTION7="$( echo $rawsection | cut -d':' -f8 )"
         if [ "$SECTION7" ]; then
          CALCSECTION="$SECTION7"
          proc_calc
          SECTION8="$( echo $rawsection | cut -d':' -f9 )"
          if [ "$SECTION8" ]; then
           CALCSECTION="$SECTION8"
           proc_calc
           SECTION9="$( echo $rawsection | cut -d':' -f10 )"
           if [ "$SECTION9" ]; then
            CALCSECTION="$SECTION9"
            proc_calc
            SECTION10="$( echo $rawsection | cut -d':' -f11 )"
            if [ "$SECTION10" ]; then
             CALCSECTION="$SECTION10"
             proc_calc
             SECTION11="$( echo $rawsection | cut -d':' -f12 )"
             if [ "$SECTION11" ]; then
              CALCSECTION="$SECTION11"
              proc_calc
              SECTION12="$( echo $rawsection | cut -d':' -f13 )"
              if [ "$SECTION12" ]; then
               CALCSECTION="$SECTION12"
               proc_calc
               SECTION13="$( echo $rawsection | cut -d':' -f14 )"
               if [ "$SECTION13" ]; then
                CALCSECTION="$SECTION13"
                proc_calc
                SECTION14="$( echo $rawsection | cut -d':' -f15 )"
                if [ "$SECTION14" ]; then
                 CALCSECTION="$SECTION14"
                 proc_calc
                 SECTION15="$( echo $rawsection | cut -d':' -f16 )"
                 if [ "$SECTION15" ]; then
                  CALCSECTION="$SECTION15"
                  proc_calc
                  SECTION16="$( echo $rawsection | cut -d':' -f17 )"
                  if [ "$SECTION16" ]; then
                   CALCSECTION="$SECTION16"
                   proc_calc
                   SECTION17="$( echo $rawsection | cut -d':' -f18 )"
                   if [ "$SECTION17" ]; then
                    CALCSECTION="$SECTION17"
                    proc_calc
                    SECTION18="$( echo $rawsection | cut -d':' -f19 )"
                    if [ "$SECTION18" ]; then
                     CALCSECTION="$SECTION18"
                     proc_calc
                     SECTION19="$( echo $rawsection | cut -d':' -f20 )"
                     if [ "$SECTION19" ]; then
                      CALCSECTION="$SECTION19"
                      proc_calc
                     fi
                    fi
                   fi
                  fi
                 fi
                fi
               fi
              fi
             fi
            fi
           fi
          fi
         fi
        fi
       fi
      fi
     fi
    fi
  done

  LASTSECTION="$SECTIONNAME"

done

## Echo last section.
if [ "$GIGOUTPUT" = "TRUE" ]; then
  proc_recalc
else
  total="$total MB"
  free="$free MB"
  used="$used MB"
fi

if [ "$DEBUG" = "TRUE" ]; then
  echo " "
  echo "Final output:"
fi
proc_output

## If this is to be a one line output, say the whole thing here
## ( otherwise, proc_output says each line ).
if [ "$ONELINE" = "TRUE" ]; then
  if [ "$HEADER" ]; then
    MSG="$HEADER $MSG"
  fi
  if [ "$FOOTER" ]; then
    MSG="$MSG $FOOTER"
  fi
  MSG="$( echo $MSG | sed -e s/%BOLD%/$BOLD/g )"
  echo "$MSG"
else
  if [ "$FOOTER" ]; then
    FOOTER="$( echo $FOOTER | sed -e s/%BOLD%/$BOLD/g )"
    echo "$FOOTER"
  fi
fi
