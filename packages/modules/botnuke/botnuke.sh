#!/bin/bash
VER=1.32

#--[ Intro ]-------------------------------------------------
#                                                            	
# BotNuke/BotUnNuke by Turranius.                            	
# This is a script that lets any @ in your sitechan nuke or  	
# unnuke with !nuke and !unnuke.                             	
#                                                            	
#-[ Installation ]-------------------------------------------
#                                                            	
# Copy this botnuke.sh to /glftpd/bin and make it executable 	
# for the user running the bot (chmod 755 botnuke.tcl).      	
# Copy botnuke.tcl to your bots scripts folder and load it   	
# in the bots config.                                        	
# If you wish to change the default triggers (!nuke/!unnuke) 	
# then edit the .tcl file. If you do not have botnuke.sh in  	
# /glftpd/bin, then change the binary path in it too.        	
# If you wish to make it executable by everyone, change the  	
# 'o' in the binds to '-' (without the quotes).              	
#                                                            	
# If you want the output from this command in the chan       	
# instead of privmsg, change $nick to $chan after PRIVMSG    
#                                                            
# Make sure the binary "nuker" exists and works. This comes  
# with glftpd.                                               
#                                                            
# Change the settings below in botnuke.sh. Pretty straight   
# forward.                                                   
# Make sure the nukeuser is a real user and has the A and B  
# flags.                                                     
#                                                            
# Do; chmod +s /glftpd/bin/nuker                             
# I had some problems getting +s to work on my mandrake comp 
# but Dark0n3 helped me with that. If you get                
# "Failed to perform chroot()" when running it, check the    
# little help file on the webpage ( In description for this  
# script ).                                                  
# That basically works fine for RedHat/Mandrake, but cant    
# say for sure for other distros.                            
# Still cant get it to work? Check this link                 
# http://www.courtesan.com/sudo/intro.html                   
# Basically need 'nuker' to be run as root for the user that 
# is running the bot.                                        
#                                                            
# Try su'ing to the user running the bot and execute         
# botnuke.sh from shell. If it works from shell, it should   
# work from irc.                                             
# Add botnuke.tcl to your bots config file and rehash it.    
#                                                            
# You can nuke in 2 ways. Either specify the full path to    
# the release, inside /site ( !nuke DIVX/release 1 test ) or 
# just specify the release name. If there are no slashes (/) 
# in the releasename, it will try to look up the release in  
# glftpd.log.                                                
# It will look backwards through glftpd.log until it finds   
# a match. It will then stop looking. So if you do:          
# !nuke CD1 1 sucks                                          
# it will nuke the CD1 folder in the last uploaded release.  
# Not recomended to do that though =) Use full path instead. 
#                                                            
# As default, only ops in the chan can nuke and unnuke but   
# you can change that in the .tcl ofcourse.                  
#--[ Contact ]-----------------------------------------------
#                                                            
# Contact Turranius on efnet. Usually in #glftpd.            
# WEB: http://www.grandis.nu                                 
#                                                            
#--[ Settings ]----------------------------------------------

glconf=/etc/glftpd.conf # Path to glftpd.conf
glroot=/glftpd          # Glftpd's root dir
siteroot=/site          # Path to /site
nuker=/glftpd/bin/nuker # Nuker binary.
nukeuser=glftpd         # User who does the actual nuke.
gllog=/glftpd/ftp-data/logs/glftpd.log # Path to glftpd.log
alloweddir="Approved_by"

#--[ Script Start ]------------------------------------------

action=$1
release=$2
multiplier=$3
reason=$4

## Check version.
if [[ "$2" = "--status" ]]
then

    echo "BotNuke $VER by Turranius"
    exit 0

fi

proc_nukehelp()
{

    echo "Usage: command <path/release> <nukemultipler> <reason>"
    echo "Do not use spaces in reason."

}

proc_unnukehelp()
{

    echo "Usage: command <path/release> <unnuke reason>"
    echo "Do not use spaces in reason."

}

## Find release in glftpd.log. Executed if there are no / in nuke request.
proc_findrelease()
{
    if [[ ! -r "$gllog" ]]
    then

        echo "Error: Cant read glftpd.log at $gllog. Check perms if path is correct."
        exit 0

    else

        for rawdata in $(tac "$gllog" | grep -F -- "$release" | tr -s ' ' '^' | grep -w "NEWDIR:" | cut -d'^' -f7 | tr -d '"')
        do

            if [[ "$(basename "$rawdata")" = "$release" ]]
            then

                if [[ "$action" = "NUKE" ]]
                then

                    if [[ -d "$glroot$rawdata" ]]
                    then

                        fullrelease="$rawdata"
                        break

                    fi

                else

                    fullrelease="$rawdata"
                    break

                fi

            fi

        done

    fi
}

proc_checkallowed()
{
    if [[ "$alloweddir" ]]
    then

        if ls "$dirtocheck/" 2>/dev/null | grep -wi -q "$alloweddir"
        then

            echoname=$(basename "$dirtocheck")
            echo "$echoname contains dir $alloweddir. Wont nuke it."
            exit 0

        fi

    fi
}

## Is there a slash in release? If so use that as path.
if [[ "$release" ]]
then

    if echo "$release" | grep -q "/"
    then

        SLASH="YES"

    else

        proc_findrelease

    fi

fi

case $action in
    NUKE)
        if [[ -z "$release" || -z "$multiplier" || -z "$reason" ]]
        then

            proc_nukehelp
            exit 0

        fi

        if [[ "$SLASH" = "YES" ]]
        then

            if [[ -d "$glroot$siteroot/$release" ]]
            then

                dirtocheck="$glroot$siteroot/$release"
                proc_checkallowed
                $nuker -r "$glconf" -N "$nukeuser" -n "/$siteroot/$release" "$multiplier" "$reason"
                [[ -f "$glroot/bin/incomplete-list-nuker.sh" ]] && $glroot/bin/incomplete-list-nuker.sh store "/$siteroot/$release"
                exit 0

            else

                echo "Could not find $release. Try again."
                exit 0

            fi

        else

            if [[ "$fullrelease" ]]
            then

                dirtocheck="$glroot$fullrelease"
                proc_checkallowed
                $nuker -r "$glconf" -N "$nukeuser" -n "/$fullrelease" "$multiplier" "$reason"
                [[ -f "$glroot/bin/incomplete-list-nuker.sh" ]] && $glroot/bin/incomplete-list-nuker.sh store $fullrelease
                exit 0

            else

                echo "$release not found in glftpd.log. Use full path ( from inside /site ) to point it out to me"
                exit 0

            fi

        fi
        ;;

    UNNUKE)
        reason=$3
        if [[ -z "$release" || -z "$reason" ]]
        then

            proc_unnukehelp
            exit 0

        fi

        if [[ "$SLASH" = "YES" ]]
        then

            $nuker -r "$glconf" -N "$nukeuser" -u "/$siteroot/$release" "$reason"
            [[ -f "$glroot/bin/incomplete-list-nuker.sh" ]] && $glroot/bin/incomplete-list-nuker.sh remove "/$siteroot/$release"
            exit 0

        else

            if [[ "$fullrelease" ]]
            then

                $nuker -r "$glconf" -N "$nukeuser" -u "/$fullrelease" "$reason"
                [[ -f "$glroot/bin/incomplete-list-nuker.sh" ]] && $glroot/bin/incomplete-list-nuker.sh remove $fullrelease
                exit 0

            else

                echo "$release not found in glftpd.log. Use full path ( from inside /site ) to point it out to me"
                exit 0

            fi

        fi
        ;;

    *)
        echo "Error in tcl. It didnt specify NUKE or UNNUKE."
        exit 0
        ;;

esac
