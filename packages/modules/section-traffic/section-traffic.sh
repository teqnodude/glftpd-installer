#!/bin/bash
VER=1.32
#--[ Info ]-----------------------------------------------------
# Section Traffic by Teqno
#
# Requires xferlog-import. Shows up/down/total stats per section.
# See original header for install/cron instructions.
#--[ Settings ]-------------------------------------------------

GLROOT=/glftpd
TMP=$GLROOT/tmp

SQLBIN="mysql"
SQLHOST="localhost"
SQLUSER="transfer"
SQLPASS=""
SQLDB="transfers"
SQLTB="changeme"
SQL="$SQLBIN -P 3307 --ssl=0 -u $SQLUSER -p$SQLPASS -h $SQLHOST -D $SQLDB -N -s"
SQLEXPIRE="6"

COLOR1="4"
COLOR2="14"
COLOR3="7"
BOLD=""

EXCLUDED="PRE|SPEEDTEST|lost\+found|Search_Links|ARCHIVE.EXP|INCOMING|INCOMPLETES|MUSIC.BY.ARTIST|MUSIC.BY.GENRE|!Today_0DAY|!Today_FLAC|!Today_MP3|MOVIES_SORTED"

TRIGGER=$(grep "::pub_section_traffic" "$GLROOT/sitebot/scripts/section-traffic.tcl" | awk '{print $4}')

#--[ Helpers ]--------------------------------------------------

# Convert a GiB value to GiB or TiB. Sets HUMAN_VAL and HUMAN_UNIT.
human_size() {
    local val="$1"
    if [[ -z "$val" || "${val,,}" == "null" ]]; then
        HUMAN_VAL=0; HUMAN_UNIT=GiB; return
    fi
    if awk -v v="$val" 'BEGIN { exit !(v > 1024) }'; then
        HUMAN_VAL=$(awk -v v="$val" 'BEGIN { printf "%.2f", v/1024 }')
        HUMAN_UNIT=TiB
    else
        HUMAN_VAL=$(awk -v v="$val" 'BEGIN { printf "%.2f", v }')
        HUMAN_UNIT=GiB
    fi
}

# Normalize a possibly-null value to a default string.
normalize() {
    local val="$1" def="$2"
    if [[ -z "$val" || "${val,,}" == "null" ]]; then
        echo "$def"
    else
        echo "$val"
    fi
}

# Run the standard per-row traffic query. $1 = WHERE clause.
traffic_query() {
    $SQL -e "SELECT
                ROUND(SUM(bytes / 1024 / 1024 / 1024), 2) AS traffic,
                ROUND(SUM(CASE WHEN direction = 'i' THEN bytes / 1024 / 1024 / 1024 ELSE 0 END), 2) AS incoming,
                ROUND(SUM(CASE WHEN direction = 'o' THEN bytes / 1024 / 1024 / 1024 ELSE 0 END), 2) AS outgoing,
                MAX(CASE WHEN direction = 'i' THEN datetime END) AS lastup
             FROM $SQLTB
             WHERE $1"
}

# Print one per-section line. Args: word name traffic incoming outgoing lastup
print_stats() {
    local word="$1" name="$2" traffic="$3" incoming="$4" outgoing="$5" lastup="$6"
    local iv iu ov ou tv tu
    human_size "$incoming"; iv=$HUMAN_VAL; iu=$HUMAN_UNIT
    human_size "$outgoing"; ov=$HUMAN_VAL; ou=$HUMAN_UNIT
    human_size "$traffic";  tv=$HUMAN_VAL; tu=$HUMAN_UNIT
    lastup=$(normalize "$lastup" "No upload")
    echo "${COLOR2}${word}:${COLOR1} ${name} ${COLOR2}- Up:${COLOR1} ${iv} ${COLOR2}${iu} - Down:${COLOR1} ${ov} ${COLOR2}${ou} - Total:${COLOR1} ${tv} ${COLOR2}${tu} - Last upload:${COLOR1} ${lastup}"
}

#--[ Script start ]---------------------------------------------

if [[ "$(stat -c "%a" "$TMP")" != 777 ]]; then
    echo "$TMP folder not writeable, do chmod 777 $TMP"
    exit 1
fi

ARGS=$(echo "$@" | cut -d ' ' -f2-)

case "$ARGS" in
help)
    cat <<-EOF
	${COLOR2}Run without argument to show stats for current month.
	${COLOR2}To check another month:${COLOR1}$TRIGGER 2020-08
	${COLOR2}To check a specific user:${COLOR1}$TRIGGER user <username>
	${COLOR2}To check a specific user and month:${COLOR1}$TRIGGER user <username> month 2020-08
	${COLOR2}To check the top 10 downloaded releases for current month:${COLOR1}$TRIGGER top
	${COLOR2}To check the top 10 downloaded releases for specific month:${COLOR1}$TRIGGER top month 2020-08
	${COLOR2}To check the top 30 downloaded releases for current month:${COLOR1}$TRIGGER top 30
	${COLOR2}To check the top 30 downloaded releases for specific month:${COLOR1}$TRIGGER top month 2020-08 30
	${COLOR2}To check stats for specific release:${COLOR1}$TRIGGER release <releasename> <username>
	${COLOR2}To check the last upload for a specific section:${COLOR1}$TRIGGER section <section>
	EOF
    exit 0
    ;;
cleanup)
    for cleanup in $($SQL -e "select distinct section FROM $SQLTB"); do
        if [[ ! -d $GLROOT/site/$cleanup ]]; then
            echo "Removing data for section $cleanup since it no longer exist on site"
            $SQL -e "delete from $SQLTB where section='$cleanup'"
            echo "Done"
        fi
    done
    echo "Removing data older than $SQLEXPIRE months from db"
    $SQL -e "delete from $SQLTB where datetime < now() - interval $SQLEXPIRE month"
    echo "Done"
    exit 0
    ;;
esac

#--[ release <releasename> <username> ]-------------------------
if [[ "$ARGS" = release* ]]; then
    release=$(echo "$ARGS" | cut -d ' ' -f2)
    username=$(echo "$ARGS" | cut -d ' ' -f3)
    echo "${COLOR2}Stats for release${COLOR1} $release ${COLOR2}for user${COLOR1} $username"

    query=$($SQL -e "SELECT
                ROUND(SUM(bytes / 1024 / 1024 / 1024), 2) AS traffic,
                ROUND(SUM(CASE WHEN direction = 'i' THEN bytes / 1024 / 1024 / 1024 ELSE 0 END), 2) AS incoming,
                ROUND(SUM(CASE WHEN direction = 'o' THEN bytes / 1024 / 1024 / 1024 ELSE 0 END), 2) AS outgoing,
                COUNT(CASE WHEN direction = 'i' THEN id END) AS filesinc,
                COUNT(CASE WHEN direction = 'o' THEN id END) AS filesout
             FROM $SQLTB
             WHERE relname = '$release' AND FTPuser = '$username'")

    echo "$query" | while read -r traffic incoming outgoing filesinc filesout; do
        human_size "$incoming"; incoming="$HUMAN_VAL $HUMAN_UNIT"
        human_size "$outgoing"; outgoing="$HUMAN_VAL $HUMAN_UNIT"
        human_size "$traffic";  traffic="$HUMAN_VAL $HUMAN_UNIT"
        filesinc=$(normalize "$filesinc" "No files")
        filesout=$(normalize "$filesout" "No files")
        echo "${COLOR2}Up:${COLOR1} ${incoming} - Down:${COLOR1} ${outgoing} - Total:${COLOR1} ${traffic} - Files Incoming:${COLOR1} ${filesinc} ${COLOR2} - Files Outgoing: ${COLOR1} ${filesout}"
    done

    echo "${COLOR3}The statistics have a 30 min delay"
    exit 0
fi

#--[ user <username> [month YYYY-MM] ]-------------------------
if [[ "$ARGS" = user* ]]; then
    if [[ "$(echo "$ARGS" | cut -d ' ' -f3)" != "month" ]]; then
        month=$(date +%Y-%m)
    else
        month=$(echo "$ARGS" | cut -d ' ' -f4)
    fi
    username=$(echo "$ARGS" | cut -d ' ' -f2)
    echo "${COLOR2}Section stats for${COLOR1} $month ${COLOR2}on${COLOR1} $SQLTB ${COLOR2}for user${COLOR1} $username"

    for section in $(ls "$GLROOT/site" | grep -Ev "$EXCLUDED" | sed '/^\s*$/d'); do
        query=$(traffic_query "section = '$section' AND datetime LIKE '$month%' AND FTPuser = '$username'")
        echo "$query" | while read -r traffic incoming outgoing lastup; do
            print_stats "Section" "$section" "$traffic" "$incoming" "$outgoing" "$lastup"
        done
    done

    echo "${COLOR3}The statistics have a 30 min delay"
    exit 0
fi

#--[ top [N] [month YYYY-MM] [N] ]-----------------------------
if [[ "$ARGS" = top* ]]; then
    topres=10
    month=$(date +%Y-%m)
    f2=$(echo "$ARGS" | cut -d ' ' -f2)
    if [[ "$f2" = "month" ]]; then
        month=$(echo "$ARGS" | cut -d ' ' -f3)
        f4=$(echo "$ARGS" | cut -d ' ' -f4)
        if [[ "$f4" =~ ^-?[0-9]+$ ]]; then
            if [[ "$f4" -le 30 ]]; then topres=$f4; else
                echo "Not allowed to check for more than 30 top releases"; exit 0
            fi
        fi
    elif [[ "$f2" =~ ^-?[0-9]+$ ]]; then
        if [[ "$f2" -le 30 ]]; then topres=$f2; else
            echo "Not allowed to check for more than 30 top releases"; exit 0
        fi
    fi

    query=$($SQL -t -e "SELECT relname, section, count(*) as download FROM $SQLTB where datetime like '$month%' and direction='o' group by relname order by download desc limit $topres")
    i=1
    echo "${COLOR2}Top $topres downloaded releases for${COLOR1} $month"
    echo "$query" > "$TMP/section-traffic.tmp"
    tr -s "-" < "$TMP/section-traffic.tmp" \
        | sed -e 's|+-+-+-+||g' -e 's/| |/\n/g' -e 's/^ | //' -e 's/ //g' -e 's/|$//' \
        > "$TMP/section-traffic2.tmp"

    while IFS= read -r rel; do
        position=$(printf "%02d" "$i"); i=$((i+1))
        relname=$(echo "$rel" | cut -d'|' -f1)
        section=$(echo "$rel" | cut -d'|' -f2)
        download=$(echo "$rel" | cut -d'|' -f3)
        echo "${BOLD}$position${BOLD}.${COLOR1} ${relname} ${COLOR2}- Section:${COLOR1} $section ${COLOR2}- Files:${COLOR1} ${download}"
    done < "$TMP/section-traffic2.tmp"

    rm -f "$TMP"/section-traffic*
    echo "${COLOR3}The statistics have a 30 min delay"
    exit 0
fi

#--[ section <section> ]---------------------------------------
if [[ "$ARGS" = section* ]]; then
    section=$(echo "$ARGS" | cut -d ' ' -f2)
    datetime=$($SQL -t -e "SELECT datetime FROM $SQLTB WHERE section = '$section' AND direction='i' ORDER BY datetime DESC LIMIT 1" | grep -oP '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}')
    if [[ -z "$datetime" ]]; then
        echo "${COLOR2}No records found for section:${COLOR1} $section"
    else
        echo "${COLOR2}Section:${COLOR1} $section ${COLOR2}- Last upload:${COLOR1} $datetime"
    fi
    exit 0
fi

#--[ default: all sections for a month ]-----------------------
if [[ -z "$ARGS" ]]; then
    month=$(date +%Y-%m)
else
    month=$ARGS
fi

echo "${COLOR2}Section stats for${COLOR1} $month ${COLOR2}on${COLOR1} $SQLTB"

for section in $(ls "$GLROOT/site" | grep -Ev "$EXCLUDED" | sed '/^\s*$/d'); do
    query=$(traffic_query "section = '$section' AND datetime LIKE '$month%'")
    if [[ -z "$query" ]]; then
        echo "${COLOR3}No data in db"
        exit 0
    fi
    echo "$query" | while read -r traffic incoming outgoing lastup; do
        print_stats "Section" "$section" "$traffic" "$incoming" "$outgoing" "$lastup"
    done
done

# Grand total
query=$(traffic_query "datetime LIKE '$month%'")
echo "$query" | while read -r traffic incoming outgoing lastup; do
    human_size "$incoming"; iv=$HUMAN_VAL; iu=$HUMAN_UNIT
    human_size "$outgoing"; ov=$HUMAN_VAL; ou=$HUMAN_UNIT
    human_size "$traffic";  tv=$HUMAN_VAL; tu=$HUMAN_UNIT
    lastup=$(normalize "$lastup" "No upload")
    echo "${COLOR1}All Sections${COLOR2} - Up:${COLOR1} ${iv} ${COLOR2}${iu} - Down:${COLOR1} ${ov} ${COLOR2}${ou} - Total:${COLOR1} ${tv} ${COLOR2}${tu} - Last upload:${COLOR1} ${lastup}"
done

echo "${COLOR3}The statistics have a 30 min delay"