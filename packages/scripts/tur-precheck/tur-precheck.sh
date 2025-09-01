#!/bin/bash
VER=1.6
#--[ Settings ]-------------------------------------------------

VERIFY_RAR_WITH_SFV="FALSE"
VERIFY_MP3_WITH_SFV="FALSE"
VERIFY_ZIP_WITH_CURRENT_DISKS="TRUE"

DONT_ALLOW_DIZ="TRUE"

ALLOWED="\.[r-z|0-9][a|0-9][r|0-9]$ \.zip$ \.mp[g|2|3|4]$ \.vob$ \.avi$ \.jpg$ \.png$ \.nfo$ \.diz$ \.sfv$ \.mkv$ \.m2ts$ \.flac$ \.cue$"

BANNED="^tvmaze\.nfo$ ^5a\.nfo$ ^aks\.nfo$ ^atl\.nfo$ ^atlvcd\.nfo$ ^bar\.nfo$ ^cas\-pre\.jpg$ ^cmt\.nfo$ ^coke\.nfo$ ^dim\.nfo$ ^dkz\.nfo$ ^echobase\.nfo$ ^firesite\.nfo$ ^fireslut\.nfo$ ^ifk\.nfo$ ^lips\.nfo$ ^magfields\.nfo$ ^mfmfmfmf\.nfo$ ^mm\.nfo$ ^mob\.nfo$ ^mod\.nfo$ ^pbox\.nfo$ ^ph\.nfo$ ^pike\.nfo$ ^pre\.nfo$ ^release\.nfo$ ^sexy\.nfo$ ^tf\.nfo$ ^twh\.nfo$ ^valhalla\.nfo$ ^zn\.nfo$ ^imdb\.nfo$ ^vdrlake\.nfo$ ^dm\.nfo$ ^nud\.nfo$ ^thecasino\.nfo$ ^dtsiso21\.jpg$ ^dagger\.jpg$"

NODOUBLESFV="FALSE"
NOSAMENAME="TRUE"
NODOUBLENFO="TRUE"
NOFTPRUSHNFOS="TRUE"
DENY_SFV_NFO_IN_SAMPLE_DIRS="TRUE"
DENY_IMAGE_IN_SAMPLE_DIRS="TRUE"

#DENY_WHEN_NO_SFV="\.r[a0-9][r0-9]$ \.0[0-9][0-9]$ \.mp[2|3]$ \.flac$"
DENY_WHEN_NO_SFV=""

#GLLOG="/ftp-data/logs/glftpd.log"
GLLOG=""

EXCLUDEDDIRS="/REQUESTS /PRE /SPEEDTEST"

ERROR1="This file does not match any allowed file extentions. Skipping."
ERROR2="This filename is BANNED. Add it to your skiplists. Wanker."
ERROR3="There is already a .sfv in this dir. You must delete that one first."
ERROR4="This file is already there with a different case."
ERROR5="There is already a .nfo in this dir. You must delete that one first."
ERROR6="This nfo file format is not allowed ($1)"
ERROR7="You can't upload a .sfv or .nfo file into a Sample, Covers or Proof dir."
ERROR8="You must upload the .sfv file first."
ERROR9="You can't upload a .jpg into a Sample dir."

#--[ Script Start ]---------------------------------------------

BOLD=""
UNDERLINE=""
RESET=""

# Skip excluded dirs
if [[ -n "${EXCLUDEDDIRS:-}" ]]
then

    exclude_regex="$(tr -s ' ' '|' <<< "$EXCLUDEDDIRS")"
    if [[ -n "${2:-}" ]] && grep -Eiq "$exclude_regex" <<< "$2"
    then

        exit 0

    fi

fi

case "$1" in

    *.[rR0-9][aA0-9][rR0-9])

        if [[ "${VERIFY_RAR_WITH_SFV:-}" == "TRUE" ]]
        then

            # Find an .sfv file in target dir (basename only)
            sfv_file="$(find "$2" -maxdepth 1 -type f -iname '*.sfv' -printf '%f\n' -quit)"

            if [[ -z "${sfv_file:-}" ]]
            then

                printf 'You must upload .sfv first!\n\n'
                exit 2

            else

                # Exact, case-insensitive match of first field to $1
                if ! awk -v name="$1" 'BEGIN{IGNORECASE=1} $1==name {f=1} END{exit f?0:1}' "$2/$sfv_file"
                then

                    printf 'File does not exist in sfv!\n\n'
                    exit 2

                fi

            fi

        fi
        ;;

    *.[mM][pP]3)

        if [[ "${VERIFY_MP3_WITH_SFV:-}" == "TRUE" ]]
        then

            sfv_file="$(find "$2" -maxdepth 1 -type f -iname '*.sfv' -printf '%f\n' -quit)"

            if [[ -z "${sfv_file:-}" ]]
            then

                printf 'You must upload .sfv first!\n\n'
                exit 2

            else

                if ! awk -v name="$1" 'BEGIN{IGNORECASE=1} $1==name {f=1} END{exit f?0:1}' "$2/$sfv_file"
                then

                    printf 'File does not exist in sfv!\n\n'
                    exit 2

                fi

            fi

        fi
        ;;

    *.[dD][iI][zZ])

        if [[ "${DONT_ALLOW_DIZ:-}" == "TRUE" ]]
        then

            exit 2

        fi
        ;;

    *.[zZ][iI][pP])

        if [[ "${VERIFY_ZIP_WITH_CURRENT_DISKS:-}" == "TRUE" ]]
        then

            # Proceed only if there are any .zip files in CWD
            if compgen -G '*.zip' >/dev/null
            then

                searchstr="${1:0:3}"

                # Compare first 3 chars of existing zips (case-insensitive)
                if ! printf '%s\n' *.zip | cut -c1-3 | grep -iq "^${searchstr}$"
                then

                    printf 'Filename does not match with existing disks\n'
                    exit 2

                fi

            fi

        fi
        ;;

esac

if [[ -n "${ALLOWED:-}" ]]
then

    ALLOWED="$(tr -s ' ' '|' <<< "$ALLOWED")"
    if ! grep -Eiq "$ALLOWED" <<< "$1"
    then

        printf '%s\n\n' "$ERROR1"
        exit 2

    fi

fi

if [[ -n "${DENY_WHEN_NO_SFV:-}" ]]
then

    DENY_WHEN_NO_SFV="$(tr -s ' ' '|' <<< "$DENY_WHEN_NO_SFV")"
    if grep -Eiq "$DENY_WHEN_NO_SFV" <<< "$1"
    then

        if ! find "$2" -maxdepth 1 -type f -iname '*.sfv' | grep -q .
        then

            printf '%s\n\n' "$ERROR8"
            exit 2

        fi

    fi

fi

if [[ -n "${BANNED:-}" ]]
then

    BANNED="$(tr -s ' ' '|' <<< "$BANNED")"
    if grep -Eiq "$BANNED" <<< "$1"
    then

        printf '%s\n\n' "$ERROR2"
        exit 2

    fi

fi

if [[ "${NOSAMENAME:-}" == "TRUE" ]]
then

    if ls -1 "$2" | grep -iq "^$1$"
    then

        if ! ls -1 "$2" | grep -q "^$1$"
        then

            printf '%s\n\n' "$ERROR4"
            exit 2

        fi

    fi

fi

if [[ "${NODOUBLESFV:-}" == "TRUE" ]]
then

    if grep -Eiq '\.sfv$' <<< "$1"
    then

        if compgen -G "$2/*.[sS][fF][vV]" >/dev/null
        then

            printf '%s\n\n' "$ERROR3"

            if [[ -n "${GLLOG:-}" ]]
            then

                DIR="$(basename "$2")"

                # $1 = Filename. $2 = Full path. $DIR = current dir. $USER = duh
                echo "$(date '+%a %b %e %T %Y') TURGEN: \"${BOLD}[WANKER] - $USER${RESET} tried to upload ${BOLD}$1${RESET} into ${UNDERLINE}$DIR${RESET} where there already is a sfv!\"" >> "$GLLOG"

            fi

            exit 2

        fi

    fi

fi

if [[ "${DENY_SFV_NFO_IN_SAMPLE_DIRS:-}" == "TRUE" ]]
then

    if grep -Eiq '/sample$|/covers$|/proof$' <<< "$PWD"
    then

        if grep -Eiq '\.sfv$|\.nfo$' <<< "$1"
        then

            printf '%s\n\n' "$ERROR7"
            exit 2

        fi

    fi

fi

# DENY images in /sample
if [[ "${DENY_IMAGE_IN_SAMPLE_DIRS:-}" == "TRUE" ]]
then

    if grep -Eiq '/sample$' <<< "$PWD"
    then

        if grep -Eiq '\.(jpg|png)$' <<< "$1"
        then

            printf '%s\n\n' "$ERROR9"
            exit 2

        fi

    fi

fi

# Disallow double NFO
if [[ "${NODOUBLENFO:-}" == "TRUE" ]]
then

    if grep -Eiq '\.nfo$' <<< "$1"
    then

        pattern_nfo="${2%/}/*.[nN][fF][oO]"
        if compgen -G "$pattern_nfo" >/dev/null
        then

            printf '%s\n\n' "$ERROR5"

            if [[ -n "${GLLOG:-}" ]]
            then

                DIR="$(basename "$2")"

                # $1 = Filename. $2 = Full path. $DIR = current dir. $USER = duh
                echo "$(date '+%a %b %e %T %Y') TURGEN: \"${BOLD}[WANKER] - $USER${RESET} tried to upload ${BOLD}$1${RESET} into ${UNDERLINE}$DIR${RESET} where there already is a nfo!\"" >> "$GLLOG"

            fi

            exit 2

        fi

    fi

fi

# No FTPRush-style NFO names like "(123).nfo"
if [[ "${NOFTPRUSHNFOS:-}" == "TRUE" ]]
then

    if grep -Eiq '\.nfo$' <<< "$1"
    then

        if grep -Eiq '\([0-9].*\)\.nfo$' <<< "$1"
        then

            printf '%s\n\n' "$ERROR6"
            exit 2

        fi

    fi

fi
