#!/bin/bash
VER=1.1
#--[ Intro ]----------------------------------------------------#
#                                                               #
# Section Traffic by Teqno                                      #
#                                                               #
# This script requires the use of xferlog-import to work. It    #
# shows the up / down / total stats for sections on site.       #
#                                                               #
#-[ Install ]---------------------------------------------------#
#                                                               #
# Copy this script to $GLROOT/bin and chmod it 755. Go through  #
# the settings and ensure they are correct. If you change       #
# trigger then ensure that it is the same as in tcl script. To  #
# ensure that stats are up to date you have to run the import   #
# script in crontab. Again, go over the settings and ensure     #
# they are correct. My suggestion is to run the import script   #
# every 30 min in crontab and run a daily cleanup to ensure db  #
# only has the releases that are on site. Put these in crontab. #
#                                                               #
# */30 * * * *    $GLROOT/bin/xferlog-import_3.3.sh             #
# 30 0 * * *      $GLROOT/bin/section-traffic.sh cleanup        #
#                                                               #
#--[ Settings ]-------------------------------------------------#

GLROOT=/glftpd
TMP=$GLROOT/tmp

SQLBIN="mysql"
SQLHOST="localhost"
SQLUSER="transfer"
SQLPASS=""
SQLDB="transfers"
SQLTB="changeme"
SQL="$SQLBIN -u $SQLUSER -p"$SQLPASS" -h $SQLHOST -D $SQLDB -N -s"
SQLEXPIRE="6"

COLOR1=4
COLOR2=14
COLOR3=7
BOLD=

EXCLUDED="PRE|SPEEDTEST|lost\+found|Search_Links|ARCHIVE.EXP|INCOMING|INCOMPLETES|MUSIC.BY.ARTIST|MUSIC.BY.GENRE|!Today_0DAY|!Today_FLAC|!Today_MP3|MOVIES_SORTED"

TRIGGER=`grep "bind pub" $GLROOT/sitebot/scripts/section-traffic.tcl | cut -d " " -f4`

#--[ Script start ]---------------------------------------------#

if [ "`stat -c "%a" $TMP`" != 777 ]
then
    echo "$TMP folder not writeable, do chmod 777 $TMP"
    exit 0
fi

ARGS=`echo "$@" | cut -d ' ' -f2-`

if [ "$ARGS" = "help" ]
then
    echo "${COLOR2}Run without argument to show stats for current month."
    echo "${COLOR2}To check another month: ${COLOR1}$TRIGGER 2020-08"
    echo "${COLOR2}To check a specific user: ${COLOR1}$TRIGGER user <username>"
    echo "${COLOR2}To check a specific user and month: ${COLOR1}$TRIGGER user <username> month 2020-08"
    echo "${COLOR2}To check the top 10 downloaded releases for current month: ${COLOR1}$TRIGGER top"
    echo "${COLOR2}To check the top 10 downloaded releases for specific month: ${COLOR1}$TRIGGER top month 2020-08"
    echo "${COLOR2}To check the top 30 downloaded releases for current month: ${COLOR1}$TRIGGER top 30"
    echo "${COLOR2}To check the top 30 downloaded releases for specific month: ${COLOR1}$TRIGGER top month 2020-08 30"
    echo "${COLOR2}To check stats for specific release: ${COLOR1}$TRIGGER release <releasename> <username>"
    exit 0
fi

if [ "$ARGS" = "cleanup" ]
then
    for cleanup in `$SQL -e "select distinct section FROM $SQLTB"`
    do
        if [ ! -d $GLROOT/site/$cleanup ]
        then
            echo "Removing data for section $cleanup since it no longer exist on site"
            $SQL -e "delete from $SQLTB where section='$cleanup'"
            echo "Done"
        fi
    done
    echo "Removing data older than $SQLEXPIRE months from db"
    $SQL -e "delete from $SQLTB where datetime < now() - interval $SQLEXPIRE month"
    echo "Done"
    exit 0
fi

tunit=GB
iunit=GB
ounit=GB

if [[ "$ARGS" = "release"* ]]
then
    release=`echo $ARGS | cut -d ' ' -f2`
    username=`echo $ARGS | cut -d ' ' -f3`
    echo "${COLOR2}Stats for release${COLOR1} $release ${COLOR2}for user${COLOR1} $username"
    query=`$SQL -e "SELECT distinct(select round(sum(bytes/1024/1024/1024),2) as traffic from $SQLTB where relname='$release' and FTPuser='$username') as traffic,(select round(sum(bytes/1024/1024/1024),2) as incoming from $SQLTB where relname='$release' and direction='i' and FTPuser='$username') as incoming,(select round(sum(bytes/1024/1024/1024),2) as outgoing from $SQLTB where relname='$release' and direction='o' and FTPuser='$username') as outgoing,(select count(id) as files from $SQLTB where relname='$release' and direction='i' and FTPuser='$username') as filesinc,(select count(id) as files from $SQLTB where relname='$release' and direction='o' and FTPuser='$username') as filesout FROM $SQLTB"`

    echo $query | while read -r traffic incoming outgoing filesinc filesout;
    do
        if [ $traffic == "NULL" ]
        then
            traffic=0
        fi
        if [ $incoming == "NULL" ]
        then
            incoming=0
        fi
        if [ $outgoing == "NULL" ]
        then
            outgoing=0
        fi
        if [ "$filesinc" == "NULL" ]
        then
            filesinc="No files"
        fi
        if [ "$filesout" == "NULL" ]
        then
            filesout="No files"
        fi

        if [ `echo $traffic | cut -d'.' -f1` -gt 1024 ]
        then
            rawtraffic=`echo "$traffic / 1024" | bc -l`
            firstnum=`echo $rawtraffic | cut -d'.' -f1`
            secondnum=`echo $rawtraffic | cut -d'.' -f2 | cut -b1-2`
            traffic="$firstnum.$secondnum"
            tunit=TB
        fi

        if [ `echo $incoming | cut -d'.' -f1` -gt 1024 ]
        then
            rawtraffic=`echo "$incoming / 1024" | bc -l`
            firstnum=`echo $rawtraffic | cut -d'.' -f1`
            secondnum=`echo $rawtraffic | cut -d'.' -f2 | cut -b1-2`
            incoming="$firstnum.$secondnum"
            iunit=TB
        fi

        if [ `echo $outgoing | cut -d'.' -f1` -gt 1024 ]
        then
            rawtraffic=`echo "$outgoing / 1024" | bc -l`
            firstnum=`echo $rawtraffic | cut -d'.' -f1`
            secondnum=`echo $rawtraffic | cut -d'.' -f2 | cut -b1-2`
            outgoing="$firstnum.$secondnum"
            ounit=TB
	fi
        echo "${COLOR2}Up:${COLOR1} ${incoming} ${COLOR2}$iunit - Down:${COLOR1} ${outgoing} ${COLOR2}$ounit - Total:${COLOR1} ${traffic} ${COLOR2}$tunit - Files Incoming:${COLOR1} ${filesinc} ${COLOR2} - Files Outgoing: ${COLOR1} ${filesout}"
    done	
    echo "${COLOR3}The statistics have a 30 min delay"
    exit 0
fi

if [[ "$ARGS" = "user"* ]]
then

    if [ "`echo $ARGS | cut -d ' ' -f3`" != "month" ]
    then
	month=`date +%Y-%m`
    else
	month=`echo $ARGS | cut -d ' ' -f4`
    fi
    username=`echo $ARGS | cut -d ' ' -f2`

    echo "${COLOR2}Section stats for${COLOR1} $month ${COLOR2}on${COLOR1} $SQLTB ${COLOR2}for user${COLOR1} $username"

    for section in `ls $GLROOT/site | egrep -v "$EXCLUDED" | sed '/^\s*$/d'`
    do
	query=`$SQL -e "SELECT distinct(select round(sum(bytes/1024/1024/1024),2) as traffic from $SQLTB where section='$section' and datetime like '$month%' and FTPuser='$username') as traffic,(select round(sum(bytes/1024/1024/1024),2) as incoming from $SQLTB where section='$section' and datetime like '$month%' and direction='i' and FTPuser='$username') as incoming,(select round(sum(bytes/1024/1024/1024),2) as outgoing from $SQLTB where section='$section' and datetime like '$month%' and direction='o' and FTPuser='$username') as outgoing,(select datetime from $SQLTB where datetime like '$month%' and direction='i' and section='$section' order by datetime DESC limit 1) as lastup FROM $SQLTB"`

	echo $query | while read -r traffic incoming outgoing lastup;
	do
	    if [ $traffic == "NULL" ]
	    then
		traffic=0
	    fi
	    if [ $incoming == "NULL" ]
	    then
		incoming=0
	    fi
	    if [ $outgoing == "NULL" ]
	    then
		outgoing=0
	    fi
	    if [ "$lastup" == "NULL" ]
	    then
	        lastup="No upload"
	    fi
    
	    if [ `echo $traffic | cut -d'.' -f1` -gt 1024 ]
	    then
		rawtraffic=`echo "$traffic / 1024" | bc -l`
		firstnum=`echo $rawtraffic | cut -d'.' -f1`
		secondnum=`echo $rawtraffic | cut -d'.' -f2 | cut -b1-2`
		traffic="$firstnum.$secondnum"
		tunit=TB
	    fi
    
	    if [ `echo $incoming | cut -d'.' -f1` -gt 1024 ]
	    then
		rawtraffic=`echo "$incoming / 1024" | bc -l`
		firstnum=`echo $rawtraffic | cut -d'.' -f1`
		secondnum=`echo $rawtraffic | cut -d'.' -f2 | cut -b1-2`
		incoming="$firstnum.$secondnum"
		iunit=TB
	    fi
    
	    if [ `echo $outgoing | cut -d'.' -f1` -gt 1024 ]
	    then
		rawtraffic=`echo "$outgoing / 1024" | bc -l`
		firstnum=`echo $rawtraffic | cut -d'.' -f1`
		secondnum=`echo $rawtraffic | cut -d'.' -f2 | cut -b1-2`
		outgoing="$firstnum.$secondnum"
		ounit=TB
	    fi	
	    echo "${COLOR2}Section:${COLOR1} $section ${COLOR2}- Up:${COLOR1} ${incoming} ${COLOR2}$iunit - Down:${COLOR1} ${outgoing} ${COLOR2}$ounit - Total:${COLOR1} ${traffic} ${COLOR2}$tunit - Last upload:${COLOR1} ${lastup}"
	done
    done
    echo "${COLOR3}The statistics have a 30 min delay"
    exit 0
fi

if [[ "$ARGS" = "top"* ]]
then
    if [ "`echo $ARGS | cut -d ' ' -f2`" != "month" ]
    then
	if [[ "`echo $ARGS | cut -d ' ' -f2`" =~ ^-?[0-9]+$ ]]
	then
	    if [ "`echo $ARGS | cut -d ' ' -f2`" -le "30" ]
	    then
		topres=`echo $ARGS | cut -d ' ' -f2`
	    else
		echo "Not allowed to check for more than 30 top releases"
		exit 0
	    fi
	else
	    topres=10
	fi
        month=`date +%Y-%m`
    else
        if [[ "`echo $ARGS | cut -d ' ' -f4`" =~ ^-?[0-9]+$ ]]
        then
            if [ "`echo $ARGS | cut -d ' ' -f4`" -le "30" ]
            then
                topres=`echo $ARGS | cut -d ' ' -f4`
            else
                echo "Not allowed to check for more than 30 top releases"
                exit 0
            fi
        else
            topres=10
        fi
        month=`echo $ARGS | cut -d ' ' -f3`
    fi
    query=`$SQL -t -e "SELECT relname, section, count(*) as download FROM $SQLTB where datetime like '$month%' and direction='o' group by relname order by download desc limit $topres"`
    i=1
    echo "${COLOR2}Top $topres downloaded releases for${COLOR1} $month"
    echo $query > $TMP/section-traffic.tmp
    cat $TMP/section-traffic.tmp | tr -s "-" | sed -e 's|+-+-+-+||g' -e 's/| |/\n/g' -e 's/^ | //' -e 's/ //g' -e 's/|$//' > $TMP/section-traffic2.tmp
    for rel in `cat $TMP/section-traffic2.tmp`
    do
	position="$((i++))"
	position=`printf "%2.0d\n" $position |sed "s/ /0/"`
	relname=`echo $rel | cut -d'|' -f1`
	section=`echo $rel | cut -d'|' -f2`
	download=`echo $rel | cut -d'|' -f3`
	echo "${BOLD}$position${BOLD}.${COLOR1} ${relname} ${COLOR2}- Section:${COLOR1} $section ${COLOR2}- Files:${COLOR1} ${download}"
    done
    rm $TMP/section-traffic*
    echo "${COLOR3}The statistics have a 30 min delay"
    exit 0    
fi

if [ -z $ARGS ]
then
    month=`date +%Y-%m`
else
    month=$ARGS
fi

echo "${COLOR2}Section stats for${COLOR1} $month ${COLOR2}on${COLOR1} $SQLTB"

for section in `ls $GLROOT/site | egrep -v "$EXCLUDED" | sed '/^\s*$/d'`
do

    query=`$SQL -e "SELECT distinct(select round(sum(bytes/1024/1024/1024),2) as traffic from $SQLTB where section='$section' and datetime like '$month%') as traffic,(select round(sum(bytes/1024/1024/1024),2) as incoming from $SQLTB where section='$section' and datetime like '$month%' and direction='i') as incoming,(select round(sum(bytes/1024/1024/1024),2) as outgoing from $SQLTB where section='$section' and datetime like '$month%' and direction='o') as outgoing,(select datetime from $SQLTB where datetime like '$month%' and direction='i' and section='$section' order by datetime DESC limit 1) as lastup FROM $SQLTB"`

    if [ -z "$query" ]
    then
        echo "${COLOR3}No data in db"
        exit 0
    fi

    echo $query | while read -r traffic incoming outgoing lastup;
    do

	if [ $traffic == "NULL" ]
	then
	    traffic=0
	fi
	if [ $incoming == "NULL" ]
	then
    	    incoming=0
	fi
	if [ $outgoing == "NULL" ]
	then
    	    outgoing=0
	fi
	if [ "$lastup" == "NULL" ]
	then
    	    lastup="No upload"
	fi

	if [ `echo $traffic | cut -d'.' -f1` -gt 1024 ]
	then
	    rawtraffic=`echo "$traffic / 1024" | bc -l`
	    firstnum=`echo $rawtraffic | cut -d'.' -f1`
	    secondnum=`echo $rawtraffic | cut -d'.' -f2 | cut -b1-2`
	    traffic="$firstnum.$secondnum"
	    tunit=TB
	fi

	if [ `echo $incoming | cut -d'.' -f1` -gt 1024 ]
	then
	    rawtraffic=`echo "$incoming / 1024" | bc -l`
	    firstnum=`echo $rawtraffic | cut -d'.' -f1`
	    secondnum=`echo $rawtraffic | cut -d'.' -f2 | cut -b1-2`
	    incoming="$firstnum.$secondnum"
	    iunit=TB
	fi

	if [ `echo $outgoing | cut -d'.' -f1` -gt 1024 ]
	then
	    rawtraffic=`echo "$outgoing / 1024" | bc -l`
	    firstnum=`echo $rawtraffic | cut -d'.' -f1`
	    secondnum=`echo $rawtraffic | cut -d'.' -f2 | cut -b1-2`
	    outgoing="$firstnum.$secondnum"
	    ounit=TB
	fi
        echo "${COLOR2}Section:${COLOR1} $section ${COLOR2}- Up:${COLOR1} ${incoming} ${COLOR2}$iunit - Down:${COLOR1} ${outgoing} ${COLOR2}$ounit - Total:${COLOR1} ${traffic} ${COLOR2}$tunit - Last upload:${COLOR1} ${lastup}"
    done
done

query=`$SQL -e "SELECT distinct(select round(sum(bytes/1024/1024/1024),2) as traffic from $SQLTB where datetime like '$month%') as traffic,(select round(sum(bytes/1024/1024/1024),2) as incoming from $SQLTB where datetime like '$month%' and direction='i') as incoming,(select round(sum(bytes/1024/1024/1024),2) as outgoing from $SQLTB where datetime like '$month%' and direction='o') as outgoing,(select datetime from $SQLTB where datetime like '$month%' and direction='i' order by datetime DESC limit 1) as lastup FROM $SQLTB"`

echo $query | while read -r traffic incoming outgoing lastup;
do
    if [ $traffic == "NULL" ]
    then
        traffic=0
    fi
    if [ $incoming == "NULL" ]
    then
	incoming=0
    fi
    if [ $outgoing == "NULL" ]
    then
	outgoing=0
    fi
    if [ "$lastup" == "NULL" ]
    then
        lastup="No upload"
    fi

    if [ `echo $traffic | cut -d'.' -f1` -gt 1024 ]
    then
        rawtraffic=`echo "$traffic / 1024" | bc -l`
	firstnum=`echo $rawtraffic | cut -d'.' -f1`
        secondnum=`echo $rawtraffic | cut -d'.' -f2 | cut -b1-2`
	traffic="$firstnum.$secondnum"
        tunit=TB
    fi

    if [ `echo $incoming | cut -d'.' -f1` -gt 1024 ]
    then
	rawtraffic=`echo "$incoming / 1024" | bc -l`
        firstnum=`echo $rawtraffic | cut -d'.' -f1`
	secondnum=`echo $rawtraffic | cut -d'.' -f2 | cut -b1-2`
        incoming="$firstnum.$secondnum"
	iunit=TB
    fi

    if [ `echo $outgoing | cut -d'.' -f1` -gt 1024 ]
    then
	rawtraffic=`echo "$outgoing / 1024" | bc -l`
        firstnum=`echo $rawtraffic | cut -d'.' -f1`
	secondnum=`echo $rawtraffic | cut -d'.' -f2 | cut -b1-2`
        outgoing="$firstnum.$secondnum"
        ounit=TB
    fi
    echo "${COLOR1}All Sections${COLOR2} - Up:${COLOR1} ${incoming} ${COLOR2}$iunit - Down:${COLOR1} ${outgoing} ${COLOR2}$ounit - Total:${COLOR1} ${traffic} ${COLOR2}$tunit - Last upload:${COLOR1} ${lastup}"
done

echo "${COLOR3}The statistics have a 30 min delay"

exit 0
