#!/bin/bash
VER=1.1
#--[ Info ]-----------------------------------------------------
#
# Syscheck by Teqno                                             
# Lists relevant S.M.A.R.T. status for disks and CPU temp       
#
#--[ Script start ]---------------------------------------------

RED="$(tput setaf 1)"
GREEN="$(tput setaf 2)"
YELLOW="$(tput setaf 3)"
RST="$(tput sgr0)"

# requirements check helpers
need()
{

    command -v "$1" >/dev/null 2>&1 || {
        echo "Missing required tool: $1"
        exit 1
    }

}

null_as()
{

    # usage: null_as "$value" "N/A"
    if [[ -z "$1" ]]
    then

        echo "$2"

    else

        echo "$1"

    fi

}

color_bad()
{

    v="$1"

    if [[ "$v" = "N/A" ]]
    then

        printf "%s%s%s" "$RED" "$v" "$RST"
        return

    fi

    if [[ "$v" =~ ^[0-9]+(\.[0-9]+)?$ ]]
    then

        if [[ "$v" =~ \. ]]
        then

            gt0="$(echo "$v > 0" | bc)"
            if (( gt0 ))
            then

                printf "%s%s%s" "$RED" "$v" "$RST"
                return

            fi

        else

            if (( v > 0 ))
            then

                printf "%s%s%s" "$RED" "$v" "$RST"
                return

            fi

        fi

    fi

    if [[ "$v" = "PASSED" ]]
    then

        printf "%s%s%s" "$GREEN" "$v" "$RST"
        return

    fi

    printf "%s" "$v"

}

color_temp()
{

    # Colorize temperature with thresholds (edit to taste)
    # <40°C = plain, 40–49.9 = yellow, >=50 = orange, >=60 = red
    v="$1"

    if [[ ! "$v" =~ ^[0-9]+(\.[0-9]+)?$ ]]
    then

        # if it's not a number, treat as bad
        printf "%s %s%s" "$RED" "$v" "$RST"
        return

    fi

    iv="${v%.*}"

    if (( iv >= 60 ))
    then

        printf "%s %s%s" "$RED" "$v" "$RST"

    elif (( iv >= 50 ))
    then

        printf "%s %s%s" "$ORANGE" "$v" "$RST"

    else

        printf "%s %s%s" "$GREEN" "$v" "$RST"

    fi

}

case "$1" in
    mobo)

        need lsblk
        need smartctl

        echo "----------------------------- Regular Controller ------------------------------"

        for disk in $(lsblk -dn -o NAME,TYPE | awk '$2=="disk"{print $1}')
        do

            diskinfo="$(LC_ALL=C smartctl -a /dev/"$disk" 2>/dev/null)"

            if [[ "$disk" =~ ^nvme ]]
            then

                model="$(printf '%s\n' "$diskinfo" | sed -n 's/^Model Number:[[:space:]]*//p' | head -1)"
                model="$(null_as "$model" "N/A")"

                capacity="$(printf '%s\n' "$diskinfo" | sed -n \
                    -e 's/^Total NVM Capacity:[[:space:]]*//p' \
                    -e 's/^Namespace [0-9]\+ Size\/Capacity:[[:space:]]*//p' \
                    -e 's/^Size\/Capacity:[[:space:]]*//p' | head -1)"
                capacity="$(printf '%s\n' "$capacity" | sed -n 's/.*\[\(.*\)\].*/\1/p; t; p')"
                capacity="$(null_as "$capacity" "N/A")"

                serial="$(printf '%s\n' "$diskinfo" | sed -n 's/^Serial Number:[[:space:]]*//p' | head -1)"
                serial="$(null_as "$serial" "N/A")"

                health="$(printf '%s\n' "$diskinfo" | sed -n 's/^SMART overall-health self-assessment test result:[[:space:]]*//p' | tr -d '[:space:]' | head -1)"
                health="$(null_as "$health" "N/A")"

                temp="$(printf '%s\n' "$diskinfo" | awk -F'[[:space:]]+' '/^Temperature:/{print $2; exit}')"
                temp="$(null_as "$temp" "N/A")"

                reallocated="N/A"
                pending="N/A"

                media_errors="$(printf '%s\n' "$diskinfo" | sed -n 's/^Media and Data Integrity Errors:[[:space:]]*//p' | head -1)"
                media_errors="$(null_as "$media_errors" "N/A")"

                percent_used="$(printf '%s\n' "$diskinfo" | sed -n 's/^Percentage Used:[[:space:]]*//p' | head -1)"
                percent_used="$(null_as "$percent_used" "N/A")"

            else


                model="$(printf '%s\n' "$diskinfo" | sed -n 's/^Device Model:[[:space:]]*//p' | head -1)"
                model="$(null_as "$model" "N/A")"

                capacity="$(printf '%s\n' "$diskinfo" | sed -n 's/^User Capacity:[[:space:]]*//p' | sed -n 's/.*\[\(.*\)\].*/\1/p' | head -1)"
                capacity="$(null_as "$capacity" "N/A")"

                serial="$(printf '%s\n' "$diskinfo" | sed -n 's/^Serial Number:[[:space:]]*//p' | head -1)"
                serial="$(null_as "$serial" "N/A")"

                health="$(printf '%s\n' "$diskinfo" | sed -n 's/^SMART overall-health self-assessment test result:[[:space:]]*//p' | tr -d '[:space:]' | head -1)"
                health="$(null_as "$health" "N/A")"

                temp="$(printf '%s\n' "$diskinfo" | awk '/Temperature/{print $10; exit}')"
                temp="$(null_as "$temp" "N/A")"

                reallocated="$(printf '%s\n' "$diskinfo" | awk '$1=="5"||$2=="Reallocated_Sector_Ct"{print $(NF);exit}')"
                reallocated="$(null_as "$reallocated" "N/A")"

                pending="$(printf '%s\n' "$diskinfo" | awk '$1=="197"||$2=="Current_Pending_Sector"{print $(NF); exit}')"
                pending="$(null_as "$pending" "N/A")"

                media_errors="N/A"
                percent_used="N/A"

            fi

            echo
            echo "Device Model:${RED} $model ${RST}- User Capacity:${RED} $capacity${RST}"
            echo "Serial Number:${RED} $serial${RST}"
            echo "HDD:${RED} /dev/$disk ${RST}- Health: $(color_bad "$health")${RST} - TEMP:$(color_temp "$temp")${RST}ºc"
            echo "Reallocated_Sector_Ct: $(color_bad "$reallocated")${RST}"
            echo "Current_Pending_Sector: $(color_bad "$pending")${RST}"
            echo "Media and Data Integrity Errors: $(color_bad "$media_errors")${RST}"
            echo "Percentage Used: $percent_used${RST}"
            echo "-"

        done
        echo
        exit 0
        ;;


    lsi)

        need lspci
        need smartctl

        if [[ "$(lspci | grep -c -E 'LSI MegaRAID|MegaRAID')" -ge 1 ]]
        then

            bus="$(smartctl --scan 2>/dev/null | grep -oE '/dev/bus/[0-9]+' | sort -u | head -1)"
            [[ -z "$bus" ]] && bus="/dev/bus/0"

            echo "----------------------------- LSI Raid Controller ------------------------------"

            if command -v megacli >/dev/null 2>&1
            then

                for disk in $(megacli -pdlist -a0 2>/dev/null | awk -F': ' '/^Device Id/ {print $2}' | sort -n)
                do

                    diskinfo="$(LC_ALL=C smartctl -a -d megaraid,"$disk" "$bus" 2>/dev/null)"

                    model="$(printf '%s\n' "$diskinfo" | sed -n 's/^Device Model:[[:space:]]*//p' | head -1)"
                    model="$(null_as "$model" "N/A")"

                    capacity="$(printf '%s\n' "$diskinfo" | sed -n 's/^User Capacity:[[:space:]]*//p' | sed -n 's/.*\[\(.*\)\].*/\1/p' | head -1)"
                    capacity="$(null_as "$capacity" "N/A")"

                    serial="$(printf '%s\n' "$diskinfo" | sed -n 's/^Serial Number:[[:space:]]*//p' | head -1)"
                    serial="$(null_as "$serial" "N/A")"

                    health="$(printf '%s\n' "$diskinfo" | sed -n 's/^SMART overall-health self-assessment test result:[[:space:]]*//p' | tr -d '[:space:]' | head -1)"
                    health="$(null_as "$health" "N/A")"

                    # Temperature: prefer attribute table "Temperature_Celsius", else any "Temperature:" line
                    temp="$(printf '%s\n' "$diskinfo" | awk '
                        $2=="Temperature_Celsius"{print $10; exit}
                        /^Temperature:[[:space:]]+[0-9]+/{for(i=1;i<=NF;i++) if ($i ~ /^[0-9]+$/){print $i; exit}}
                    ')"
                    temp="$(null_as "$temp" "N/A")"

                    # SMART attributes by ID or name (works across different smartctl formats)
                    reallocated="$(printf '%s\n' "$diskinfo" | awk '
                        $1=="5" || $2=="Reallocated_Sector_Ct" {print $NF; exit}
                    ')"
                    reallocated="$(null_as "$reallocated" "N/A")"

                    pending="$(printf '%s\n' "$diskinfo" | awk '
                        $1=="197" || $2=="Current_Pending_Sector" {print $NF; exit}
                    ')"
                    pending="$(null_as "$pending" "N/A")"

                    echo
                    echo "Device Model:${RED} $model ${RST}- User Capacity:${RED} $capacity${RST}"
                    echo "Serial Number:${RED} $serial${RST}"
                    echo "HDD:${RED} /dev/$disk ${RST}- Health: $(color_bad "$health")${RST} - TEMP: $(color_temp"$temp")${RST}ºc"
                    echo "Reallocated_Sector_Ct: $(color_bad "$reallocated")${RST}"
                    echo "Current_Pending_Sector: $(color_bad "$pending")${RST}"
                    echo "-"

                done

                echo
                exit 0

            else

            echo "megacli not found"
            exit 0

            fi

        else

            echo "No LSI card found in system"
            exit 0

        fi
        ;;

    areca)

        need lspci

        if [[ "$(lspci | grep -c 'ARC-')" -ge 1 ]]
        then

            if [[ -x /root/cli64 ]]
            then

                echo "----------------------------- Areca device ------------------------------"

                for disk in $(/root/cli64 disk info 2>/dev/null | sed -e 's/^[ \t]*//' -e '/=/d' | awk '!/N\.A\./{print $1}' | sed -e '/#/d' -e '/^GuiErrMsg.*/d')
                do

                    info="$(
                        /root/cli64 disk info drv="$disk" 2>/dev/null
                    )"
                    smart="$(
                        /root/cli64 disk smart drv="$disk" 2>/dev/null
                    )"

                    model="$(printf '%s\n' "$info"  | sed -n 's/^Model Name[[:space:]]*:[[:space:]]*//p' | head -1)"
                    model="$(null_as "$model" "N/A")"

                    capacity="$(printf '%s\n' "$info" | sed -n 's/^Disk Capacity[[:space:]]*:[[:space:]]*//p' | head -1)"
                    capacity="$(null_as "$capacity" "N/A")"

                    serial="$(printf '%s\n' "$info"   | sed -n 's/^Serial Number[[:space:]]*:[[:space:]]*//p' | head -1)"
                    serial="$(null_as "$serial" "N/A")"

                    health="$(printf '%s\n' "$info"   | sed -n 's/^Device State[[:space:]]*:[[:space:]]*//p' | head -1)"
                    health="$(null_as "$health" "N/A")"

                    # Temp line often looks like: "Temp         : 34 C"
                    temp="$(printf '%s\n' "$info" | awk '
                        /Temp[[:space:]]*:/ {
                            for (i=1;i<=NF;i++) if ($i ~ /^[0-9]+(\.[0-9]+)?$/) { print $i; exit }
                        }' | head -1)"
                    temp="$(null_as "$temp" "N/A")"

                    # SMART attributes (names can vary slightly; grab by label fragment)
                    reallocated="$(printf '%s\n' "$smart" | awk '
                        /Reallocated[[:space:]]+Sector[[:space:]]+Count/ {print $NF; exit}
                    ')"
                    reallocated="$(null_as "$reallocated" "N/A")"

                    pending="$(printf '%s\n' "$smart" | awk '
                        /Current[[:space:]]+Pending[[:space:]]+Sector/ {print $NF; exit}
                    ')"
                    pending="$(null_as "$pending" "N/A")"

                    echo
                    echo "Device Model:${RED} $model ${RST}- User Capacity:${RED} $capacity${RST}"
                    echo "Serial Number:${RED} $serial${RST}"
                    echo "HDD:${RED} /dev/$disk ${RST}- Health: $(color_bad "$health")${RST} - TEMP: $(color_temp"$temp")${RST}ºc"
                    echo "Reallocated_Sector_Ct: $(color_bad "$reallocated")${RST}"
                    echo "Current_Pending_Sector: $(color_bad "$pending")${RST}"
                    echo "-"

                done

                echo
                exit 0

            else

                echo "Areca CLI not found at /root/cli64"
                exit 0

            fi

        else

            echo "No Areca card found in system"
            exit 0

        fi
        ;;

    cpu)

        need sensors

        total=0
        count=0

        # Pass 1: average per-core temps
        while IFS= read -r line
        do

            temp="$(printf '%s\n' "$line" | sed -n 's/^[^:]*:[[:space:]]*[+]\([0-9]\+\(\.[0-9]\+\)\?\)°C.*/\1/p')"
            if [[ -n "$temp" ]]
            then

                total="$(awk -v a="$total" -v b="$temp" 'BEGIN{printf "%.2f", a+b}')"
                (( count++ ))

            fi

        done < <(LC_ALL=C sensors 2>/dev/null | grep -E '^Core[[:space:]]+[0-9]+:')

        # Pass 2: use Package id if no Core lines
        if (( count == 0 ))
        then

            while IFS= read -r line
            do

                temp="$(printf '%s\n' "$line" | sed -n 's/^[^:]*:[[:space:]]*[+]\([0-9]\+\(\.[0-9]\+\)\?\)°C.*/\1/p')"
                if [[ -n "$temp" ]]
                then

                    total="$(awk -v a="$total" -v b="$temp" 'BEGIN{printf "%.2f", a+b}')"
                    (( count++ ))

                fi

            done < <(LC_ALL=C sensors 2>/dev/null | grep -E '^Package id [0-9]+:')
        fi

        # Pass 3: machine-readable fallback
        if (( count == 0 ))
        then

            while IFS= read -r t
            do

                if [[ "$t" =~ ^[0-9]+(\.[0-9]+)?$ ]]
                then

                    total="$(awk -v a="$total" -v b="$t" 'BEGIN{printf "%.2f", a+b}')"
                    (( count++ ))

                fi

            done < <(LC_ALL=C sensors -u 2>/dev/null | awk '/temp[0-9]+_input:/ {print $2}')
        fi

        if (( count == 0 ))
        then

            echo "CPU: N/A"
            exit 0

        fi

        avg="$(awk -v s="$total" -v n="$count" 'BEGIN{printf "%.2f", s/n}')"
        echo "CPU:${RED} ${avg}${RST}ºc"
        exit 0
        ;;

    *)

		cat <<-EOF
			$0 mobo  - to view hdds connected to motherboard
			$0 lsi   - to view hdds connected to LSI
			$0 areca - to view hdds connected to ARECA
			$0 cpu   - to view CPU temp
		EOF

        exit 0
        ;;

esac
