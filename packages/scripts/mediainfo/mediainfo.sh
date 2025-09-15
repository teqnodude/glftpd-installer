#!/bin/bash
VER=1.9
#--[ Info ]-----------------------------------------------------
#																
# Mediainfo by Teqno											
#																
# It extracts info from *.rar file for related releases to		
# give the user the ability to compare quality.					
#																
#--[ Settings ]-------------------------------------------------

GLROOT="/glftpd"
TMP="$GLROOT/tmp"
TMPFILE="$TMP/mediainfo.txt"
COLOR1="7" # Orange
COLOR2="14" # Grey
COLOR3="4" # Red
SECTIONS="TV-720 TV-1080 TV-2160 TV-NO TV-NORDIC X264-1080 X265-2160"

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

			*.2160p.*)
				section="X265-2160"
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

			*.2160p.*)
				section="TV-2160"
				release="$tv*2160p*"
			;;

			*.DAN[iI]SH.1080p.*|*.SWED[iI]SH.1080p.*|*.FINNISH.1080p.*)
				section="TV-NORDIC"
				release="$tv*1080p*"
			;;

			*.NORWEG[iI]AN.1080p.*)
				section="TV-NO"
				release="$tv*1080p*"
			;;

			*.1080p.BluRay.*)
				section="TV-BLURAY"
				release="$tv*1080p*"
			;;

			*.1080p.*)
				section="TV-1080"
				release="$tv*1080p*"
			;;

			*.DAN[iI]SH.720p.*|*.SWED[iI]SH.720p.*|*.FINNISH.720p.*)
				section="TV-NORDIC"
				release="$tv*720p*"
			;;

			*.NORWEG[iI]AN.720p.*)
				section="TV-NO"
				release="$tv*720p*"
			;;

			*.720p.*)
				section="TV-720"
				release="$tv*720p*"
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

	if [[ ! -d "$GLROOT/site/$section/$input" ]]
	then

		echo "Release not found"
		exit 0

	else

		if find "$GLROOT/site/$section/$input" -type f -name '* Complete -*' -quit | grep -q .
		then

			echo "Release incomplete"
			exit 0

		else

			cd "$GLROOT/bin" || { echo "Cannot cd to $GLROOT/bin" ; exit 1 ; }

			[[ -d "$TMP" ]] || mkdir -m 0777 -p "$TMP"

			shopt -s nullglob

			for info in "$GLROOT/site/$section"/*
			do

				
				base_info="${info##*/}"

				# Skip unwanted dirs and safely match the computed release pattern using 'case'
				case "$base_info" in

					*'[NUKED]'*|*'[INCOMPLETE]'*|*DIRFIX*|*SAMPLEFIX*|*NFOFIX*)
						continue
					;;

					$release_pat)
						:  # matched
					;;

					*)
						continue
					;;

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

					rel_name="$(grep '^Filename' "$tmpfile" | cut -d ':' -f2- | sed -e "s|$GLROOT/site/$section/||" -e 's|/.*||' -e 's/ //g')"
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
	input="$(printf '%s\n' "$*" | cut -d ' ' -f2)"

	if [[ -z "$input" ]]
	then

		print_help
		exit 0

	fi

	local tv movie
	tv="$(printf '%s' "$input" | grep -o ".*.S[0-9][0-9]E[0-9][0-9].\|.*.E[0-9][0-9].\|.*.[0-9][0-9][0-9][0-9].[0-9][0-9].[0-9][0-9].\|.*.Part.[0-9]." | sed 's|^/||')"

	if [[ "$(printf '%s' "$input" | sed 's/[0-9][0-9][0-9][0-9]p//' | grep -o ".*.[0-9][0-9][0-9][0-9]." | sed 's|^/||' | cut -d'/' -f4)" ]]
	then

		movie="$(printf '%s' "$input" | sed 's/[0-9][0-9][0-9][0-9]p//' | grep -o ".*.[0-9][0-9][0-9][0-9]." | sed 's|^/||')"

	else

		movie="$(printf '%s' "$input" | sed 's|[0-9][0-9][0-9][0-9]p.*||')"

	fi

	IFS='|' read -r section release <<<"$(select_section "$input" "$tv" "$movie")"

	scan_and_print "$section" "$input" "$release"

	exit 0

}

main "$@"
