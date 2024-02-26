#!/usr/bin/env bash
if [ "$1" == "" ]; then
    exit 1
fi

##########################################################################
# slv-prebw v1.1 20190712 slv
##########################################################################
# ..based on wspre-bw.sh, from *somewhere* ;)
# + requires a recent version of bash
# + check README.md on how to configure sitebot

GLROOT="/glftpd"
GLLOG="$GLROOT/ftp-data/logs/glftpd.log"
SITEWHO="$GLROOT/bin/sitewho"
XFERLOG="$GLROOT/ftp-data/logs/xferlog"

PREDIR="/site/PRE"		# exclude affils predir
TAILNUM="2500"			# tail xferlog, default is 2500 lines
CAPS="2 3 5 5 5"		# capture output bw and intervals in seconds
SPEED_UNIT="MBPS"		# transfer unit/s, default is MBPS [MBPS|MBIT]
SIZE_UNIT="GB"			# size unit, default is MB [MB|GB]
SHOW_ALWAYS="0"			# also announce if there's no prebw [0/1]
SHOW_BWAVG="1"			# show average bw in announce [0/1]
SHOW_TRAF="1"			# show total pre traffic by number of users [0/1]

# END OF CONFIG			# ONLY EDIT BELOW IF YOU KNOW WHAT YOU'RE DOING
##########################################################################

release="$1"
SAVE_IFS="$IFS"
if [ -z "$SPEED_UNIT" ]; then SPEED_UNIT="MBPS"; fi
if [ -z "$SIZE_UNIT" ]; then SIZE_UNIT="MB"; fi

### DEBUG ###
DEBUG=0
if echo "$@" | grep -q DEBUG; then DEBUG=1; fi
if [ -z "$BWAVG_SHOW" ]; then BWAVG_SHOW="0"; fi
if [ "$DEBUG" -eq 1 ]; then
	#GLLOG="/dev/stdout"
	SITEWHO="func_dbg_swho"
	XFERLOG="test/xfer.txt"
	CAPS="1 1 1 1 1"
fi
func_dbg_swho() { cat test/who.txt; }
############

func_cspeed() {
	if [ "$SPEED_UNIT" = "MBPS" ]; then
		echo | awk -v v="$1" '{ printf "%0.1f", v/1024 }'
	elif [ "$SPEED_UNIT" = "MBIT" ]; then
		echo | awk -v v="$1" '{ printf "%0.0f", v*8/1024 }'
	fi
}

func_csize() {
	if [ "$SIZE_UNIT" = "MB" ]; then
		echo | awk -v v="$1" '{ printf "%0.1f", v/1024/1024 }'
	elif [ "$SIZE_UNIT" = "GB" ]; then
		echo | awk -v v="$1" '{ printf "%0.1f", v/1024/1024/1024 }'
	fi
}

func_ugcount() {
	sed '/^ *$/d' | sort | uniq -c | sort -rnk1 | awk '{ print $2 }' | wc -l | sed 's/  *//g'
}

func_tail() {
	tail -r /dev/null >/dev/null 2>&1 && \
	{ tail -n $TAILNUM -r $XFERLOG; } || \
	{ tail -n $TAILNUM $XFERLOG | tac; }
}

t=0; cnt=0; bwtext=""
for s in ${CAPS}; do
	b=0; u=0
	sleep "$s"
	t=$((t+s))
	IFS=$'\n'
	for dn in $( ${SITEWHO} --raw | grep "${release}" | grep '"DN"' | awk -F\" '{ print $12 }' ); do
		dn="$( echo "${dn}" | awk '{ printf "%0.0f", $1 }' )"
		b="$((b+dn))"
		u="$((u+1))"
	done
	bw_arr[cnt]="${b}"
	cnt=$((cnt+1))
	bwtext="${bwtext}\"${t}\" \"${u}\" \"$(func_cspeed ${b})\" "
done

i=0; bw_total="0"
while [ "${i}" -lt "${#bw_arr[@]}" ]; do
	bw_total=$((bw_total+${bw_arr[$i]}))
	i=$((i+1))
done
bwavg="$((bw_total/cnt))"

if [ "${bwavg}" -ne "0" ] || [ "${SHOW_ALWAYS}" -eq "1" ]; then
	if [ "$SHOW_BWAVG" -eq 1 ]; then
		bwavgtext=" \"$(func_cspeed ${bwavg})\""
	fi
	if [ "${SHOW_TRAF}" -eq "1" ]; then
		i=0; traftext=""; traf_total=0; u_cnt=0; g_cnt=0
		IFS=$'\n'
		for line in $( func_tail | grep -v "${PREDIR}" | grep " o " | grep "${release}" | awk '{ print $8, $14, $15 }' ); do
			IFS=" " read -r traf uname gname <<< "${line}"
			traf_total="$((traf_total+traf))"
			un_arr[i]="${uname}"
			gn_arr[i]="${gname}"
			i="$((i+1))"
		done
		u_cnt="$( printf "%s\n" "${un_arr[@]}" | func_ugcount )"
		g_cnt="$( printf "%s\n" "${gn_arr[@]}" | func_ugcount )"
		traftext=" \"$(func_csize ${traf_total})\" \"${u_cnt}\" \"${g_cnt}\""
	fi
	if [ "$DEBUG" -eq 1 ]; then echo "DEBUG: traf_total=$traf_total bwavgtext=$bwavgtext"; fi
	echo "$( date "+%a %b %d %T %Y" ) PREBW: \"${release}\" ${bwtext/% /}${bwavgtext}${traftext}" >> ${GLLOG}
fi

IFS="$SAVE_IFS"
exit 0

# shellcheck disable=SC2035
/* vim: set noai tabstop=4 shiftwidth=4 softtabstop=4 noexpandtab: */
