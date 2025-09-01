#!/bin/bash
VER=1.30
#--[ Info ]----------------------------------------------------
#								
# Section Manager by Teqno     			 		
#								
# This will simplify the add/remove of sections for people      
# that finds it too tedious to manually do the work. It checks  
# for various scripts in /glftpd/bin folder including the script
# pzs-ng and adds the proper lines. Be sure to put the right    
# paths for glftpd and pzs-ng before running this script and 	
# don't forget to rehash the bot after the script is done. This	
# manager is intended for incoming sections only and not archive
#								
# If the script can't find the file defined in the path below 	
# the script will just skip it. 				
#			 					 
# This script only add/remove sections directly under /site and	
# not under any other location.					
#								
# ALERT!!!!!!!!!! 											
# The script works only with the scripts installed by the	
# glftpd-installer created by Teqno. Do NOT attempt to use this 
# on a system set up by other methods.                          
#								
#--[ Settings ]-------------------------------------------------

glroot=/glftpd									 	# path for glftpd dir
pzsbot=$glroot/sitebot/scripts/pzs-ng/ngBot.conf 	# path for ngBot.conf 
pzsng=$glroot/backup/pzs-ng		 			 		# path for pzs-ng
incoming=changeme 					 	 			# path for incoming device for glftpd

# Leave them empty if you want to disable them
turautonuke=$glroot/bin/tur-autonuke.conf		 	# path for tur-autonuke
turspace=$glroot/bin/tur-space.conf					# path for tur-space
approve=$glroot/bin/approve.sh						# path for approve
foopre=$glroot/etc/pre.cfg					 		# path for foopre 
turlastul=$glroot/bin/tur-lastul.sh					# path for tur-lastul
psxcimdb=$glroot/etc/psxc-imdb.conf					# path for psxc-imdb
dated=$glroot/bin/dated.sh					 		# path for dated.sh

#--[ Script Start ]---------------------------------------------

clear

rootdir=$(pwd)

# styling
cron_width="23"
red="$(tput setaf 1)"
green="$(tput setaf 2)"
yellow="$(tput setaf 3)"
reset="$(tput sgr0)"

start()
{

    local sections_list
    sections_list=$(grep "set sections" "$pzsbot" | sed 's/REQUEST//g' | cut -d "\"" -f2 | xargs)
    
    echo "Already configured sections: ${green}$sections_list${reset}"
    echo

    while [[ -z $section ]]
    do

        read -rp "What section do you want to manage, if not listed just type it in : " section

    done

    section=${section^^}
    
    echo
    read -rp "What do you wanna do with $section? [A]dd [R]remove, default A : " action
    
    echo
    read -rp "Is this a dated section? [Y]es [N]o, default N : " day
    
    echo
    read -rp "Does it contain zip files? [Y]es [N]o, default N : " zipfiles
    
    echo
    read -rp "Is this a movie section? [Y]es [N]o, default N : " movie

    # Set default values if empty and convert to uppercase
    action=${action:-A}
    action=${action^^}
    day=${day:-N}
    day=${day^^}
    zipfiles=${zipfiles:-N}
    zipfiles=${zipfiles^^}
    movie=${movie:-N}
    movie=${movie^^}

    echo

    # Clean and normalize sections list for checking
    local normalized_sections
    normalized_sections=$(echo "$sections_list" | tr ' ' '\n' | sort | xargs)
    
    # Check if section exists using pattern matching
    local section_exists=false

    if [[ " $normalized_sections " == *" $section "* ]]
    then

        section_exists=true

    fi

    case $action in

        R)

            if ! $section_exists
            then

                echo "${red}Section '$section' does not exist in configured sections.${reset}"
                echo "Available sections: ${green}$normalized_sections${reset}"
                echo
                exit 2

            fi

            actionname="Removed the section from"
            read -rp "Remove folder $section under $glroot/site? [Y]es [N]o, default N : " remove
            remove=${remove:-N}
            remove=${remove^^}

            echo

            case $remove in

                Y)

                    echo "Removing $section, please wait..."
                    echo

                    if [[ -d "$glroot/site/$section" ]]
                    then

                        if rm -rf "$glroot/site/$section"
                        then

                            echo "$actionname $glroot/site"

                        else

                            echo "${red}Failed to remove directory $glroot/site/$section${reset}"
                            exit 1

                        fi

                    else

                        echo "${yellow}Directory $glroot/site/$section does not exist.${reset}"

                    fi

                    echo
                    ;;

                *)
                    echo "${yellow}Remember, section folder $section needs to be removed under $glroot/site${reset}"
                    echo
                    ;;

            esac
            ;;

        *)

            if $section_exists
            then

                echo "${red}Section '$section' already exists in configured sections.${reset}"
                echo "Available sections: ${green}$normalized_sections${reset}"
                echo
                exit 2

            fi

            actionname="Added the section to"
            read -rp "Create folder $section under $glroot/site? [Y]es [N]o, default N : " create
            create=${create:-N}
            create=${create^^}

            echo

            case $create in

                Y)

                    echo "$actionname $glroot/site"
                    echo

                    if mkdir -m 777 "$glroot/site/$section" 2>/dev/null
                    then

                        echo "Directory created successfully."

                    else

                        echo "${red}Failed to create directory $glroot/site/$section${reset}"
                        exit 1

                    fi
                    echo
                    ;;

                *)
                    echo "${yellow}Remember, section folder $section needs to be created under $glroot/site${reset}"
                    echo
                    ;;

            esac
            ;;

    esac

}

turautonuke()
{

    if [[ -f "$turautonuke" ]]
    then

        case $action in

            R)

                if sed -i "/\/site\/$section$/d" "$turautonuke"
                then

                    echo "$actionname Tur-Autonuke"

                else

                    echo "${red}Failed to remove section $section from Tur-Autonuke config${reset}"

                fi
                ;;

            *)

                case $day in

                    Y)

                        if sed -i '/^DIRS/a '"/site/$section/\$today" "$turautonuke" && \
                           sed -i '/^DIRS/a '"/site/$section/\$yesterday" "$turautonuke"
                        then

                            echo "$actionname Tur-Autonuke"

                        else

                            echo "${red}Failed to add dated section $section to Tur-Autonuke config${reset}"

                        fi
                        ;;

                    *)

                        if sed -i '/^DIRS/a '"/site/$section" "$turautonuke"
                        then

                            echo "$actionname Tur-Autonuke"

                        else

                            echo "${red}Failed to add section $section to Tur-Autonuke config${reset}"

                        fi
                        ;;

                esac
                ;;

        esac

    else

        echo "${yellow}Tur-Autonuke config file not found${reset}"

    fi

}

turspace()
{

    if [[ -f "$turspace" ]]
    then

        case $action in

            R)

                if sed -i "/\/site\/$section:/d" "$turspace"
                then

                    echo "$actionname Tur-Space"

                else

                    echo "${red}Failed to update Tur-Space config${reset}"

                fi
                ;;

            *)

                case $day in

                    Y)

                        if sed -i '/^\[INCOMING\]/a '"INC$section=$incoming:$glroot/site/$section:" "$turspace"
                        then

                            echo "$actionname Tur-Space"

                        else

                            echo "${red}Failed to add dated section to Tur-Space config${reset}"

                        fi
                        ;;

                    *)

                        if sed -i '/^\[INCOMING\]/a '"INC$section=$incoming:$glroot/site/$section:" "$turspace"
                        then

                            echo "$actionname Tur-Space"

                        else

                            echo "${red}Failed to add section to Tur-Space config${reset}"

                        fi
                        ;;

                esac
                ;;

        esac

    else

        echo "${yellow}Tur-Space config file not found${reset}"

    fi

}

pzsng()
{
	
    local zsconf="$pzsng/zipscript/conf/zsconfig.h"

    if [[ -f "$zsconf" ]]
    then

        case $action in

            R)

	        local section_re
		section_re=$(printf '%s' "$section" | sed 's/[.[\*^$\\]/\\&/g')

		if sed -i -E \
    		    -e "s#(/site/${section_re})(/%Y-%m-%d/|/)##Ig" \
    		    -e 's/[[:space:]]+"$/"/' \
    		    -e 's/"[[:space:]]+/"/' \
    		    -e 's#/  /#/ /#g' \
	            "$zsconf"

	        then

                    echo "$actionname PZS-NG (paths removed)"

                else

                    echo "${red}Failed to remove PZS-NG paths for $section${reset}"

                fi
                ;;

            *)

                case $day in

                    Y)

                        if sed -i "/\bcleanupdirs_dated\b/ s/\"$/ \/site\/$section\/%Y-%m-%d\/\"/" "$zsconf"
                        then

                            :

                        else

                            echo "${red}Failed to add dated cleanup dir for $section${reset}"

                        fi
                        ;;

                    *)

                        if sed -i "/\bcleanupdirs\b/ s/\"$/ \/site\/$section\/\"/" "$zsconf"
                        then

                            :

                        else

                            echo "${red}Failed to add cleanup dir for $section${reset}"

                        fi
                        ;;

                esac

                case $zipfiles in

                    Y)

                        if sed -i "/\bzip_dirs\b/ s/\"$/ \/site\/$section\/\"/" "$zsconf"
                        then

                            :

                        else

                            echo "${red}Failed to add zip_dirs for $section${reset}"

                        fi
                        ;;

                    *)

                        if sed -i "/\bsfv_dirs\b/ s/\"$/ \/site\/$section\/\"/" "$zsconf"
                        then

                            :

                        else

                            echo "${red}Failed to add sfv_dirs for $section${reset}"

                        fi
                        ;;

                esac

                if sed -i "/\bcheck_for_missing_nfo_dirs\b/ s/\"$/ \/site\/$section\/\"/" "$zsconf"
                then

                    :

                else

                    echo "${red}Failed to add check_for_missing_nfo_dirs for $section${reset}"

                fi
                ;;

        esac

        echo
	printf "%-70s" "Recompiling PZS-NG for changes to go into effect, please wait..."
        if cd "$pzsng" && make distclean >/dev/null 2>&1 && ./configure -q && make >/dev/null 2>&1 && make install >/dev/null 2>&1 && cd "$rootdir"
	then
    
	    printf "%s\n" "${green}Done${reset}"

        else

    	    printf "%s\n" "${red}Failed${reset}"

        fi


    else

        echo "${yellow}PZS-NG config file not found${reset}"

    fi

}

pzsbot()
{
    local botconf="$pzsbot"
    local colwidth=40

    if [[ -f "$botconf" ]]
    then
        case $action in
            R)
                local before after

                # Update set sections: remove, then sort (case-insensitive) and de-dupe
                before=$(sed -n -E 's/^[[:space:]]*set[[:space:]]+sections[[:space:]]+"([^"]*)".*/\1/p' "$botconf")
                after=$(
                    printf '%s\n' "$before" \
                    | tr ' ' '\n' \
                    | sed '/^$/d' \
                    | grep -vi -x "$section" \
                    | sort -fu \
                    | xargs
                )

                sed -i -E \
                    "s#(^[[:space:]]*set[[:space:]]+sections[[:space:]]+\")[^\"]*(\".*)#\1$after\2#I" \
                    "$botconf"

                # Remove the section's paths/chanlist lines (case-insensitive)
                sed -i -E "/^[[:space:]]*set[[:space:]]+paths\($section\)/Id"    "$botconf"
                sed -i -E "/^[[:space:]]*set[[:space:]]+chanlist\($section\)/Id" "$botconf"
                ;;

            *)
                # Build fixed-width aligned lines (quote starts at column = colwidth)
                local label_paths="set paths(${section})"
                local value_paths
                if [[ "${day^^}" = "Y" ]]; then
                    value_paths="\"/site/${section}/*/*\""
                else
                    value_paths="\"/site/${section}/*\""
                fi

                local label_chan="set chanlist(${section})"
                local value_chan
                if [[ "${day^^}" = "Y" ]]; then
                    value_chan="\"\$spamchan\""
                else
                    value_chan="\"\$mainchan\""
                fi

                _pzsbot_make_fixed_line() {
                    local label="$1" value="$2" current pad
                    current=${#label}
                    pad=$(( colwidth - current ))
                    (( pad < 1 )) && pad=1
                    printf '%s%*s%s' "$label" "$pad" '' "$value"
                }

                local line_paths line_chan
                line_paths=$(_pzsbot_make_fixed_line "$label_paths" "$value_paths")
                line_chan=$(_pzsbot_make_fixed_line "$label_chan"  "$value_chan")

                # Escape for sed insertion (slashes and ampersands)
                _pzsbot_escape_sed() { sed -e 's/[\/&]/\\&/g'; }
                local line_paths_esc line_chan_esc
                line_paths_esc=$(printf '%s' "$line_paths" | _pzsbot_escape_sed)
                line_chan_esc=$(printf '%s' "$line_chan"   | _pzsbot_escape_sed)

                local ok=true
                sed -i "/set paths(REQUEST)/i $line_paths_esc"    "$botconf" || ok=false
                sed -i "/set chanlist(REQUEST)/i $line_chan_esc" "$botconf" || ok=false

                # Append section name (we'll re-sort the list right after)
                local current_sections
                current_sections="$(sed -n -E 's/^[[:space:]]*set[[:space:]]+sections[[:space:]]+\"([^\"]*)\".*/\1/p' "$botconf")"
                if [[ -z "$current_sections" ]]; then
                    sed -i -E \
                        "s#(^[[:space:]]]*set[[:space:]]+sections[[:space:]]+\")(\".*)#\1${section}\2#I" \
                        "$botconf"
                else
                    sed -i -E \
                        "s#(^[[:space:]]*set[[:space:]]+sections[[:space:]]+\")([^\"]*)(\".*)#\1\2 ${section}\3#I" \
                        "$botconf"
                fi
                ;;
        esac

        # ---- Post-update normalization: sort sections / paths / chanlist ----

        # 1) set sections: case-insensitive unique sort like in install.sh
        {
            curr=$(sed -n -E 's/^[[:space:]]*set[[:space:]]+sections[[:space:]]+"([^"]*)".*/\1/p' "$botconf" | tr -s ' ')
            sorted=$(
                printf '%s\n' "$curr" \
                | tr ' ' '\n' \
                | sed '/^$/d' \
                | sort -fu \
                | xargs
            )
            sed -i -E \
                "s#(^[[:space:]]*set[[:space:]]+sections[[:space:]]+\")[^\"]*(\".*)#\1$sorted\2#I" \
                "$botconf"
        }

        # 2) set paths(...) lines: sort case-insensitively by section
        {
            tmp_sorted_paths=$(mktemp)
            awk '
                match($0,/^[[:space:]]*set[ \t]+paths\(([^)]+)\)/,m){
                    print tolower(m[1]) "\t" $0
                }
            ' "$botconf" | sort -f -k1,1 | cut -f2- > "$tmp_sorted_paths"

            if [[ -s "$tmp_sorted_paths" ]]; then
                awk -v sorted="$tmp_sorted_paths" '
                    BEGIN{ins=0}
                    {
                        if ($0 ~ /^[[:space:]]*set[ \t]+paths\(/) {
                            if (!ins) {
                                while ((getline L < sorted) > 0) print L
                                close(sorted); ins=1
                            }
                            next
                        }
                        print
                    }
                ' "$botconf" > "$botconf.tmp" && mv "$botconf.tmp" "$botconf"
            fi
            rm -f "$tmp_sorted_paths"
        }

        # 3) set chanlist(...) lines: sort by section, EXCLUDING DEFAULT/WELCOME (keep them in place)
        {
            tmp_sorted_chans=$(mktemp)
            awk '
                match($0,/^[[:space:]]*set[ \t]+chanlist\(([^)]+)\)/,m){
                    sec=m[1]; lo=tolower(sec)
                    if (lo=="default" || lo=="welcome") next
                    print lo "\t" $0
                }
            ' "$botconf" | sort -f -k1,1 | cut -f2- > "$tmp_sorted_chans"

            if [[ -s "$tmp_sorted_chans" ]]; then
                awk -v sorted="$tmp_sorted_chans" '
                    BEGIN{ins=0}
                    {
                        if ($0 ~ /^[[:space:]]*set[ \t]+chanlist\(/) {
                            match($0,/^[[:space:]]*set[ \t]+chanlist\(([^)]+)\)/,m)
                            lo=tolower(m[1])
                            if (lo=="default" || lo=="welcome") { print; next }
                            if (!ins) {
                                while ((getline L < sorted) > 0) print L
                                close(sorted); ins=1
                            }
                            next
                        }
                        print
                    }
                ' "$botconf" > "$botconf.tmp" && mv "$botconf.tmp" "$botconf"
            fi
            rm -f "$tmp_sorted_chans"
        }

        echo "$actionname PZS-NG bot"
    else
        echo "${yellow}PZS-NG bot config file not found${reset}"
    fi
}


approve()
{

    if [[ -f "$approve" ]]
    then

        case $action in

            R)

                if sed -i "/$section$/d" "$approve"
                then

                    :

                else

                    echo "${red}Failed to update approve list for $section${reset}"

                fi
                ;;

            *)

                if [[ ${section^^} != @(0DAY|MP3|FLAC|EBOOKS) ]]
                then

                    if sed -i '/^SECTIONS="/a '"$section" "$approve"
                    then

                        :

                    else

                        echo "${red}Failed to add $section to SECTIONS${reset}"

                    fi

                else

                    if sed -i '/^DAYSECTIONS="/a '"$section" "$approve"
                    then

                        :

                    else

                        echo "${red}Failed to add $section to DAYSECTIONS${reset}"

                    fi

                fi
                ;;

        esac

        local sections
        local daysections
        local current
        local ncurrent

        sections=$(sed -n '/^SECTIONS="/,/"/p' "$approve" | grep -v DAYSECTIONS | grep -v NUMDAYFOLDERS | grep -v SECTIONS | grep -v "\"" | wc -l)
        daysections=$(sed -n '/^DAYSECTIONS="/,/"/p' "$approve" | grep -v DAYSECTIONS | grep -v NUMDAYFOLDERS | grep -v SECTIONS | grep -v "\"" | wc -l)
        current=$(grep -i ^numfolders= "$approve" | cut -d "\"" -f2)
        ncurrent=$(grep -i ^numdayfolders= "$approve" | cut -d "\"" -f2)

        if sed -i -e "s/^NUMFOLDERS=\".*\"/NUMFOLDERS=\"$sections\"/" "$approve" && \
           sed -i -e "s/^NUMDAYFOLDERS=\".*\"/NUMDAYFOLDERS=\"$daysections\"/" "$approve"
        then

            echo "$actionname Approve"

        else

            echo "${red}Failed to update NUMFOLDERS/NUMDAYFOLDERS${reset}"

        fi

    else

        echo "${yellow}Approve config file not found${reset}"

    fi

}

eur0pre()
{

    if [[ -f "$foopre" ]]
    then

        case $action in

            R)

                local before
                local after

                before=$(grep "allow=" "$foopre" | cut -d "=" -f2 | cut -d "'" -f1 | uniq)
                after=$(grep "allow=" "$foopre" | cut -d "=" -f2 | uniq | sed 's/|/\n/g' | sort | grep -vw "$section$" | xargs | sed 's/ /|/g')

                if sed -i "/allow=/s/$before/$after/g" "$foopre" && \
                   sed -i "/section.$section\./d" "$foopre"
                then

                    :

                else

                    echo "${red}Failed to remove foo-pre entries for $section${reset}"

                fi
                ;;

            *)

                if sed -i "s/.allow=/.allow=$section\|/" "$foopre"
                then

                    :

                else

                    echo "${red}Failed to append $section to allow list${reset}"

                fi

                if [[ ${section^^} != @(0DAY|MP3|FLAC|EBOOKS) ]]
                then

                    {
                        echo "section.$section.name=$section"
                        echo "section.$section.dir=/site/$section"
                        echo "section.$section.gl_credit_section=0"
                        echo "section.$section.gl_stat_section=0"
                    } >> "$foopre"

                else

                    {
                        echo "section.$section.name=$section"
                        echo "section.$section.dir=/site/$section/YYYY-MM-DD"
                        echo "section.$section.gl_credit_section=0"
                        echo "section.$section.gl_stat_section=0"
                    } >> "$foopre"

                fi
                ;;

        esac

        sed -i -E '/allow=/{ s/=\|+/=/; s/[[:space:]]*\|[[:space:]]*/|/g; s/\|{2,}/|/g; s/\|$//; }' "$foopre"
        echo "$actionname foo-pre"

    else

        echo "${yellow}foopre config file not found${reset}"

    fi

}

turlastul()
{

    if [[ -f "$turlastul" ]]
    then

        case $action in

            R)

                local before
                local after

                before=$(grep "sections=" "$turlastul" | cut -d "=" -f2 | tr -d "\"")
                after=$(grep "sections=" "$turlastul" | cut -d "=" -f2 | tr -d "\"" | sed 's/ /\n/g' | sort | grep -vw "$section$" | xargs)

                if sed -i "/sections=/s/$before/$after/g" "$turlastul"
                then

                    :

                else

                    echo "${red}Failed to remove $section from tur-lastul sections${reset}"

                fi
                ;;

            *)

                if sed -i "s/^sections=\"/sections=\"$section /" "$turlastul"
                then

                    :

                else

                    echo "${red}Failed to add $section to tur-lastul sections${reset}"

                fi
                ;;

        esac

        #sed -i '/^sections=/s/  / /g' "$turlastul"
        #sed -i '/^sections=/s/" /"/g' "$turlastul"
        #sed -i '/^sections=/s/ "/"/g' "$turlastul"
    	sed -i -E '/^sections=/{ s/[[:space:]]{2,}/ /g; s/"[[:space:]]+/"/g; s/[[:space:]]+"/"/g }' "$turlastul"
        echo "$actionname Tur-Lastul"

    else

        echo "${yellow}Tur-Lastul config file not found${reset}"

    fi

}

psxcimdb()
{

    if [[ -f "$psxcimdb" ]]
    then

        case $movie in

            Y)

                case $action in

                    R)

                        if sed -i "/^SCANDIRS/ s/\/site\/\b$section\b//" "$psxcimdb"
                        then

                            :

                        else

                            echo "${red}Failed to remove $section from PSXC-IMDB SCANDIRS${reset}"

                        fi
                        ;;

                    *)

                        if sed -i "s/^SCANDIRS=\"/SCANDIRS=\"\/site\/$section /" "$psxcimdb"
                        then

                            :

                        else

                            echo "${red}Failed to add $section to PSXC-IMDB SCANDIRS${reset}"

                        fi
                        ;;

                esac

                sed -i -E '/^SCANDIRS=/{ s/[[:space:]]{2,}/ /g; s/"[[:space:]]+/"/g; s/[[:space:]]+"/"/g; }' "$psxcimdb"
                echo "$actionname PSXC-IMDB"
                ;;

        esac

    else

        echo "${yellow}PSXC-IMDB config file not found${reset}"

    fi

}

dated()
{

    if [[ -f "$dated" ]]
    then

        case $day in

            Y)

                case $action in

                    R)

                        if sed -i "/$section/d" "$dated"
                        then

                            :

                        else

                            echo "${red}Failed to remove $section from dated.sh${reset}"

                        fi
                        ;;

                    *)

                        if sed -i '/^sections="/a '"$section" "$dated"
                        then

                            :

                        else

                            echo "${red}Failed to add $section to dated.sh${reset}"

                        fi
                        ;;

                esac

                echo "$actionname dated.sh"
                ;;

        esac

    else

        echo "${yellow}dated.sh file not found${reset}"

    fi

    echo
}

start
pzsng
pzsbot
turautonuke
turspace
approve
eur0pre
turlastul
psxcimdb
dated

cronfile="/var/spool/cron/crontabs/root"

if find "$glroot/site" -mindepth 1 -maxdepth 1 -type d \
     ! -iname 'today' \
     \( -iname '0day' -o -iname 'ebooks' -o -iname 'flac' -o -iname 'mp3' -o -iname 'xxx-paysite' \) \
     -print -quit | grep -q .
then

	# ensure cron exists
  	if ! grep -qsF 'dated.sh' "$cronfile"
  	then
  
		printf "%-${cron_width}s %s >/dev/null 2>&1\n" "0 0 * * *" "$glroot/bin/dated.sh" >> "$cronfile"
  
	fi

else
  
    # no matching sections: remove cron
    sed -i '/dated\.sh/d' "$cronfile"
    
fi


case $action in

    [Rr])

        if [ -f "$glroot/bin/tur-rules.sh" ]
        then

            echo "${red}Be sure to remove rules for section $section in $glroot/bin/tur-rules.sh and $glroot/ftp-data/misc/site.rules${reset}"

        fi
        ;;

    *)

        if [ -f "$glroot/bin/tur-rules.sh" ]
        then

            echo "${red}Be sure to add rules for section $section in $glroot/bin/tur-rules.sh and $glroot/ftp-data/misc/site.rules${reset}"

        fi
        ;;

esac

echo
echo "${red}Please rehash the bot or the updated settings will not take effect${reset}"
echo
