#!/bin/bash
VER=2.0
#---------------------------------------------------------------
#                                                               
# Mediainfo by Teqno                                            
#                                                               
# It extracts info from *.rar file for related releases to      
# give the user the ability to compare quality.                 
#                                                               
#--[ Settings ]-------------------------------------------------

GLROOT=/glftpd
TMP=$GLROOT/tmp
TMPFILE=$TMP/mediainfo.txt
COLOR1=7 # Orange
COLOR2=14 # Dark grey
COLOR3=4 # Red
SECTIONS="ARCHIVE/TV ARCHIVE/MOVIES/X264-1080 ARCHIVE/MOVIES/X265-2160 REQUESTS TV-720 TV-1080 TV-2160 TV-BLURAY TV-NL TV-NO TV-NORDIC X264-1080 X264-NORDIC X264-WEB X265-2160"

#--[ Script Start ]---------------------------------------------

print_help()
{
	
	local rendered_sections
	rendered_sections="$(for SEC in $SECTIONS
	do
		
		printf "%s%s %s|\n" "$COLOR3" "$SEC" "$COLOR2"
	
	done | sed 's/|$//')"

	cat <<-EOF
		${COLOR2}Please enter full releasename ie ${COLOR3}Terminator.Salvation.2009.THEATRICAL.1080p.BluRay.x264-FLAME
		${COLOR2}Only works for releases in: 
		${rendered_sections}
	EOF

}

select_section()
{
	
	local input="$1"
	local tv="$2"
	local movie="$3"
	local section=""
	local release=""

	if [[ -z "$tv" ]]
	then

		case "$input" in
		
            *ARCHIVE/MOVIES/*)

                # Extract the section after ARCHIVE/MOVIES (e.g., X265-2160, X264-1080)
                section=$(printf '%s\n' "$input" | awk -F 'ARCHIVE/MOVIES/' '{print $2}' | cut -d'/' -f1)

                # Keep your normal movie-based release pattern
                release="$movie*"
            ;;

            *REQUESTS/*)
                
                local req_root
			    req_root=$(printf '%s\n' "$input" | awk -F 'REQUESTS/' '{print $2}' | cut -d'/' -f1)

				section="REQUESTS/$req_root"
				release="$movie*"
          	;;

			*.2160p.*)
				section="X265-2160"
				release="$movie*"
			;;

            *.NORWEG[iI]AN.*|*.DAN[iI]SH.*|*.SWED[iI]SH.*|*.FINNISH.*)
                section=X264-NORDIC
                release="$movie*"
            ;;

            *.1080p.WEB*)
    	    	section=X264-WEB
	    	    release="$movie*"
	        ;;

			*.1080p.*)
				
				section="X264-1080"
				release="$movie*"
			;;

			*)
				print_help
				exit 0
			;;

		esac

	else

		case "$input" in
		

            *ARCHIVE/TV/*)

                # Extract the section after ARCHIVE/TV (e.g., TV-X264, TV-X265, TV-1080, TV-2160)
                section=$(printf '%s\n' "$input" | awk -F 'ARCHIVE/TV/' '{print $2}' | sed 's|/[^/]*$||')


                # Let the TV pattern from earlier parsing drive the release glob
                # (works for nested paths like ARCHIVE/TV/TV-X264/Show/S01)
                release="$tv*"
            ;;		
		
	        
            *REQUESTS/*)

			    local req_root
			    req_root=$(printf '%s\n' "$input" | awk -F 'REQUESTS/' '{print $2}' | cut -d'/' -f1)

			    section="REQUESTS/$req_root"
			    release="$tv*"

	        ;;
	        
            *.DAN[iI]SH.1080[Pp].*|*.SWED[iI]SH.1080[Pp].*|*.F[iI]NN[iI]SH.1080[Pp].*)
		        section=TV-NORDIC
		        release="$tv*1080p*"
	        ;;
	        
            *.DAN[iI]SH.720[Pp].*|*.SWED[iI]SH.720[Pp].*|*.F[iI]NN[iI]SH.720[Pp].*)
		        section=TV-NORDIC
		        release="$tv*720p*"
	        ;;
	        
            *.NORWEG[iI]AN.2160[Pp].*)
		        section=TV-NO
		        release="$tv*2160p*"
	        ;;
        
            *.NORWEG[iI]AN.1080[Pp].*)
		        section=TV-NO
		        release="$tv*1080p*"
	        ;;
        
            *.NORWEG[iI]AN.720[Pp].*)
		        section=TV-NO
		        release="$tv*720p*"
	        ;;
        
            *.DUTCH.1080[Pp].*)
		        section=TV-NL
		        release="$tv*1080p*"
	        ;;
        
            *.DUTCH.720[Pp].*)
		        section=TV-NL
		        release="$tv*720p*"
	        ;;
        
            *.1080[Pp].BluRay.*)
		        section=TV-BLURAY
		        release="$tv*1080p*"
	        ;;
	        
            *.1080[Pp].*)
		        section=TV-1080
		        release="$tv*1080p*"
	        ;;
        
            *.720[Pp].*)
		        section=TV-720
		        release="$tv*720p*"
	        ;;
        
            *.2160[Pp].UHD.BluRay.*)
		        section=TV-BLURAY
		        release="$tv*2160p*"
	        ;;
        
            *.2160[Pp].*)
		        section=TV-2160
		        release="$tv*2160p*"
	        ;;

			*)
				print_help
				exit 0
			;;

		esac

	fi

	printf '%s|%s\n' "$section" "$release"

}

scan_and_print()
{
	
	local section="$1"
	local input="$2"
	local release_pat="$3"

	# Normalize: only the final directory name should be joined after $base/$section
	local input_leaf="${input##*/}"

	# Also normalize section in case it was set with a leading slash
	section="${section#/}"

	# Try primary site root first, then ARCHIVE/MOVIES and ARCHIVE/TV
	local found=""
	for base in "$GLROOT/site" "$GLROOT/site/ARCHIVE/MOVIES" "$GLROOT/site/ARCHIVE/TV"
	do
		
		if [[ -d "$base/$section/$input_leaf" ]]
		then

			found="$base/$section"
			break

		fi
	
	done

	if [[ -z "$found" ]]
	then

		echo "Release not found"
		exit 0

	else

		if find "$found/$input_leaf" -type f -name '* Complete -*' -quit | grep -q .
		then

			echo "Release incomplete"
			exit 0

		else

			cd "$GLROOT/bin" || { echo "Cannot cd to $GLROOT/bin" ; exit 1 ; }
			[[ -d "$TMP" ]] || mkdir -m 0777 -p "$TMP"

			shopt -s nullglob

			# Scan under the resolved section root
			for info in "$found"/*
			do

				
				base_info="${info##*/}"

				case "$base_info" in
					*'[NUKED]'*|*'[INCOMPLETE]'*|*DIRFIX*|*SAMPLEFIX*|*NFOFIX*) continue ;;
					$release_pat) : ;;
					*) continue ;;
				esac

				if ! find "$info" -type f -name '* Complete -*' -quit | grep -q .
				then

					
					media_file="$(find "$info" -maxdepth 1 -type f -name '*.rar' -print -quit)"
					if [[ -z "$media_file" ]]
					then

						echo "No .rar found in: $base_info"
						continue

					fi

					if ./mediainfo-rar "$media_file" | grep -q "failed"
					then

						echo "Couldn't extract information"
						exit 0

					fi

					local tmpfile
					tmpfile="$(mktemp "${TMP}/mediainfo.XXXXXX")"
					./mediainfo-rar "$media_file" > "$tmpfile"

					local rel_name filesize duration obitrate vbitrate nbitrate audio abitrate mabitrate formtitle format channels language

					rel_name="$(grep '^Filename' "$tmpfile" | cut -d ':' -f2- | sed -e "s|$found/||" -e 's|/.*||' -e 's/ //g')"
					echo -en "${COLOR1} $rel_name${COLOR2}"

					filesize="$(grep '^File size' "$tmpfile" | grep -E 'MiB|GiB' | cut -d ':' -f2- | sed 's/ //g')"
					[[ -n "$filesize" ]] && echo -en " |${COLOR1} $filesize${COLOR2}"

					duration="$(sed -n '/General/,/Video/p' "$tmpfile" | grep '^Duration' | uniq | cut -d ':' -f2- | sed 's/ //g')"
					[[ -n "$duration" ]] && echo -en " |${COLOR1} $duration${COLOR2}"

					obitrate="$(sed -n '/General/,/Video/p' "$tmpfile" | grep -v 'Overall bit rate mode' | grep '^Overall bit rate' | cut -d ':' -f2- | sed 's/ //g')"
					[[ -n "$obitrate" ]] && echo -en " | Overall:${COLOR1} $obitrate${COLOR2}"

					vbitrate="$(sed -n '/Video/,/Audio/p' "$tmpfile" | grep '^Bit rate  ' | cut -d ':' -f2- | sed 's/ //g')"
					[[ -n "$vbitrate" ]] && echo -en " | Video:${COLOR1} $vbitrate${COLOR2}"

					nbitrate="$(sed -n '/Video/,/Forced/p' "$tmpfile" | grep '^Nominal bit rate  ' | cut -d ':' -f2- | sed 's/ //g')"
					[[ -n "$nbitrate" ]] && echo -en " | Video Nominal:${COLOR1} $nbitrate${COLOR2}"

					if [[ -z "$(sed -n '/Audio #1/,/Forced/p' "$tmpfile")" ]]
					then

						audio="Audio"

					else

						audio="Audio #1"

					fi

					abitrate="$(sed -n "/$audio/,/Forced/p" "$tmpfile" | grep '^Bit rate  ' | cut -d ':' -f2- | sed 's/ //g')"
					[[ -n "$abitrate" ]] && echo -en " | Audio:${COLOR1} $abitrate${COLOR2}"

					mabitrate="$(sed -n "/$audio/,/Forced/p" "$tmpfile" | grep '^Maximum bit rate  ' | cut -d ':' -f2- | sed 's/ //g')"
					[[ -n "$mabitrate" ]] && echo -en " | Max Audio:${COLOR1} $mabitrate${COLOR2}"

					formtitle="$(sed -n "/$audio/,/Forced/p" "$tmpfile" | grep '^Title  ' | cut -d ':' -f2- | sed 's/ //')"
					if [[ "$formtitle" =~ DTS-HD ]]
					then

						echo -en " |${COLOR1} $formtitle${COLOR2}"

					else

						format="$(sed -n "/$audio/,/Forced/p" "$tmpfile" | grep '^Format  ' | cut -d ':' -f2- | sed -e 's/^ //' -e 's/UTF-8//')"
						[[ -n "$format" ]] && echo -en " |${COLOR1} $format${COLOR2}"

						channels="$(sed -n "/$audio/,/Forced/p" "$tmpfile" | grep '^Channel(s)' | cut -d ':' -f2- | sed 's/ //g')"
						[[ -n "$channels" ]] && echo -en "${COLOR1} $channels${COLOR2}"

					fi

					language="$(sed -n "/$audio/,/Forced/p" "$tmpfile" | grep '^Language  ' | cut -d ':' -f2- | sed 's/^ //' | head -1)"
					[[ -n "$language" ]] && echo -en "${COLOR1} $language${COLOR2}"

					echo

					rm -f "$tmpfile"

				
				fi
			
			done

			shopt -u nullglob

		fi

	fi

}



#--[ Script Start ]----------------------------------------------#

main()
{

    local input
    input="$(printf '%s\n' "$*" | cut -d ' ' -f2 | sed 's|^/*||; s|/*$||')"

    if [[ -z "$input" ]]
    then

        print_help
        exit 0

    fi

    # Always work from the leaf to avoid dragging path segments into patterns
    local input_leaf
    input_leaf="${input##*/}"

    local tv movie

	# Detect TV tokens (season/episode/date/part)
    # 1) Try from leaf (normal TV dirs)
    # 2) If empty, fall back to full path (handles REQUESTS/FILLED-Show.S01E03/Leaf)    
    tv=$(printf '%s\n' "$input_leaf" | grep -Eo '.*(S[0-9]{2}E[0-9]{2}|E[0-9]{2}|[0-9]{4}\.[0-9]{2}\.[0-9]{2}|Part\.[0-9])')
	if [[ -z "$tv" ]]
    then

        tv=$(printf '%s\n' "$input" | grep -Eo '.*(S[0-9]{2}E[0-9]{2}|E[0-9]{2}|[0-9]{4}\.[0-9]{2}\.[0-9]{2}|Part\.[0-9])' | sed 's|.*/||')

    fi	


    # Build MOVIE STEM up to the 4-digit year from the LEAF (e.g., "Title.2018.")
    if printf '%s' "$input_leaf" | sed -E 's/[0-9]{4}p//' | grep -Eq '.*\.[0-9]{4}\.'
    then

        movie="$(printf '%s' "$input_leaf" | sed -E 's/[0-9]{4}p//' | grep -Eo '.*\.[0-9]{4}\.')"

    else

        # Fallback: strip trailing quality tokens if no year was found
        movie="$(printf '%s' "$input_leaf" | sed -E 's/[0-9]{4}p.*//')"

    fi

    # Now select_section can derive the correct section from either the archive path or the quality,
    # and will receive a movie STEM so release="$movie*" matches all variants (INTERNAL, different groups, etc.)
    IFS='|' read -r section release <<<"$(select_section "$input" "$tv" "$movie")"

    scan_and_print "$section" "$input" "$release"

    exit 0

}

main "$@"
