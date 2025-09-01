#!/bin/bash
VER=1.1
#--[ Info ]-----------------------------------------------------
#                                                               
# Script is based on Tur-Oneline_Stats created by Turranius but 
# tweaked a lot.
#
#--[ Setup ]----------------------------------------------------
#                                                               
# Copy top.sh to /glftpd/bin, chmod 755 /glftpd/bin/top.sh      
#                                                               
#-[ Configuration ]---------------------------------------------
#                                                               
# Edit top.sh and set the following options:       		
#                                                               
# glroot         = The path to your glftpd dir.                 
#                                                               
# stats          = Path to glftpds stats binary, seen from      
#                  glroot above. If you need to, you may also   
#                  specify the path to glftpd.conf here.        
#                                                               
# GO_TO_GIG      = This is a number. How many MB in the output  
#                  before we convert it to GB instead?          
#                  Set to "" to disable. It will always show MB 
#                  if disabled.                                 
#                                                               
# MESSAGE        = This is what it will output for each user.   
#                  You specify the output using "cookies".      
#                  These are:                                   
#                                                               
#                  %POS%    The position of the user in the     
#                           selected ranking list.              
#                                                               
#                  %USER%   The username.                       
#                                                               
#                  %MB%     The MB (or GB) that the %USER% is   
#                           currently at.                       
#                                                               
#                  %NAME%   This is set to either MB or GB      
#                           depending on what it currently is.  
#                                                               
#                  %BOLD%   Starts and stops bold output in IRC.
#                                                               
#                  %ULINE%  Starts and stops underlined output. 
#                                                               
#                  %C1%     This starts the color mode. %C1% is 
#                           black. It goes from %C0% -> %C15%   
#                           and corresponds to the same color-  
#                           codes as when pressing ctrl-k in    
#                           mirc.                               
#                                                               
#                           Note, to stop coloring, set %C1%    
#                           which is black. For example:        
#                           %C9%%USER%%C9% does not work while  
#                           %C9%%USER%%C1% does.                
#                                                               
# ENABLE_COLORS  = TRUE/FALSE. If you do not plan on using      
#                  any colors, set this to FALSE to speed up the
#                  execution of the script. Those cookes are not
#                  translated if this is FALSE.                 
#                                                               
# EXCLUDE = Put here which group you want to exclude from stats,
# 	    only one group is allowed. If this is set then	
#           INCLUDE setting does not work.            		
#								
# INCLUDE = Put here which group you want to only show stats of,
#           only one group is allowed. If this is set then	
#	    EXCLUDE setting does not work.  			
#								
#--[ Other ]----------------------------------------------------
#                                                               
# You execute this the same way as you would with the stats     
# binary. It is NOT a standalone script. It just reformats the  
# output from the stats binary to display it in one line.       
#                                                               
# Files, Tagline and Speed are IMO usless info (want to keep it 
# slim when its just one line), so that information is not used.
#                                                               
# There is an example tcl included that you can use if you want 
# to create your own commands.                                  
#                                                               
# If you like, you can modify your botscript to use this script 
# instead of the stats binary for your normal !wkup commands and
# the likes. Do NOT specify -r /etC/glftpd.conf in the stats= if
# so, as the arguments are handled by the botscript itself.     
#                                                               
# If you want to have automatic output from time to time, you   
# can crontab something like this:                              
# echo `date "+%a %b %e %T %Y"` TURGEN: \"WeekTop Uploads: `/glftpd/bin/top.sh -w`\" >> /glftpd/ftp-data/logs/glftpd.log
# And it will announce the weekup stats at the time you crontab 
# it at.                                                        
#                                                               
#--[ Settings ]-------------------------------------------------

glroot="/glftpd"
stats="/bin/stats -r /glftpd/etc/glftpd.conf"

GO_TO_GIG="10000"

MESSAGE="%POS%.%C4% %USER%%C4% %C14%(%C4% %MB% %C14%%NAME% %C14%)"

ENABLE_COLORS=TRUE

EXCLUDE=""

INCLUDE=""

#--[ Script Start ]---------------------------------------------

if [[ -n "$FLAGS" && -n "$RATIO" ]]
then

    mode="gl"

else

    mode="irc"
    stats="$glroot$stats"

fi


proc_cookies()
{

    # Start from MESSAGE and apply cookies using bash expansions (faster than echo|sed)
    OUTPUT="$MESSAGE"

    OUTPUT="${OUTPUT//%POS%/$position}"
    OUTPUT="${OUTPUT//%USER%/$user}"
    OUTPUT="${OUTPUT//%MB%/$meg}"
    OUTPUT="${OUTPUT//%NAME%/$NAME}"
    OUTPUT="${OUTPUT//%BOLD%/}"
    OUTPUT="${OUTPUT//%ULINE%/}"

    if [[ "$ENABLE_COLORS" == "TRUE" ]]
    then

        # Map %C0% … %C15%  ->  .0 … .15
        for i in {0..15}
        do

            OUTPUT="${OUTPUT//%C${i}%/${i}}"

        done

    else

        # Strip all %C*% tokens
        for i in {0..15}
        do

            OUTPUT="${OUTPUT//%C${i}%/}"

        done

    fi

}
 

# Prefer the actual argv rather than an intermediate args var
if [[ $# -eq 0 ]]
then

    $stats -h
    exit 0

fi


# Build stats output with include/exclude logic
if [[ -n "$EXCLUDE" && -z "$INCLUDE" ]]
then

    $stats "$@" -g "$EXCLUDE" > "$glroot/tmp/stats.tmp"

elif [[ -z "$EXCLUDE" && -n "$INCLUDE" ]]
then

    $stats "$@" -o "$INCLUDE" > "$glroot/tmp/stats.tmp"

else

    $stats "$@" > "$glroot/tmp/stats.tmp"

fi


# Validate output
if [[ ! -e "$glroot/tmp/stats.tmp" ]]
then

    echo "No output file from \"$stats $*\" - make sure it's working."
    exit 1

fi

if ! grep -q -- "------------------------" "$glroot/tmp/stats.tmp"
then

    echo "Help:"
    $stats -h
    exit 0

fi

# parse stats and build OUTMESSAGE
OUTMESSAGE=""
i=0
users_dir="$glroot/ftp-data/users"

# read only the relevant lines once
while IFS= read -r rawline
do

    # collapse runs of spaces, then use ~ as a stable field sep
    tline="$(printf "%s" "$rawline" | tr -s ' ' '~')"

    # field 2 is username after the leading "[pos]" field
    username="$(cut -d'~' -f2 <<<"$tline")"

    # resolve actual user file (skip default.user)
    user=""
    if [[ -f "$users_dir/$username" ]]
    then

        user="$username"

    else

        # fallback: first match (excluding default.user)
        user="$(ls -1 "$users_dir" | grep -F -- "$username" | grep -v '^default\.user$' | head -n1)"

    fi

    # skip if no user file
    if [[ -z "$user" || ! -f "$users_dir/$user" ]]
    then

        continue

    fi

    # skip if FLAGS line contains a 6
    if grep -Eq '^FLAGS.*6' "$users_dir/$user"
    then

        continue

    fi

    # increment and format position as 2 digits with leading zero
    position="$(( ++i ))"
    position="$(printf "%02d" "$position")"

    # pick the first token that ends with GiB and strip letters -> numeric MiB value
    # (rawline still has spaces; safer to scan tokens from it)
    meg=""
    for tok in $rawline
    do

        if [[ "$tok" == *GiB ]]
        then

            meg="${tok//[!0-9]/}"
            break

        fi

    done

    # if no GiB token found, skip
    if [[ -z "$meg" ]]
    then

	continue
	
    fi

    NAME="GB"

    if [[ -n "$GO_TO_GIG" && "$meg" -ge "$GO_TO_GIG" ]]
    then

        NAME="TB"
        meg="$(( meg / 1024 ))"

    fi

    # fill OUTPUT from MESSAGE template
    proc_cookies

    if [[ -z "$OUTMESSAGE" ]]
    then

        OUTMESSAGE="$OUTPUT"

    else

        OUTMESSAGE="$OUTMESSAGE\n$OUTPUT"

    fi

done < <(grep -E '^\[' "$glroot/tmp/stats.tmp" | grep -v ' 0GiB ')


# emit the built message (respecting \n separators)
echo -e "$OUTMESSAGE"

[[ -e "$glroot/tmp/stats.tmp" ]] && rm -f -- "$glroot/tmp/stats.tmp"
