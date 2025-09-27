#!/bin/bash
VER=1.0
#--[ Info ]-----------------------------------------------------
#
# tag-empty-inc by Teqno
#
# This allow sites to tag new directories as incomplete during creation 
# before any files have been uploaded to them by using pzs-ng rescan. 
# This opens up the ability for scripts like incomplete-list-nuker.sh 
# to nuke totally empty directories. This in turn removes the necessity 
# for scripts like tur-autonuke and similar scripts that are far more 
# resource heavy. Why is that? Because they have to rely on linux "find" 
# that not only drains the cpu, but it also makes the hdds really busy. 
#
#-[ Install ]---------------------------------------------------
#
# Put this script in /glftpd/bin and ensure that you have set this in 
# zsconfig.h in pzs-ng, if you haven't yet, please do and then 
# recompile pzs-ng:
#
# #define mark_empty_dirs_as_incomplete_on_rescan TRUE
#
# and in glftpd.conf you set this:
# cscript MKD post /bin/tag-empty-inc.sh
#
# Next you can go through the list of directories below that shouldn't be 
# tagged as incomplete during creation.
#
#--[ Settings ]-------------------------------------------------

# What directories should not be tagged as incomplete during creation?
subdirs="cd[0-9]{1,2}|disc[0-9]{1,2}|disk[0-9]{1,2}|dvd[0-9]{1,2}|extra[0-9]?|sub[0-9]?|subtitle[0-9]?|vobsub[0-9]?|sample[0-9]?|subpack[0-9]?|s[0-9]{1,2}|proof|cover[0-9]?|tools"
words="dirfix|nfofix|prooffix|proofix|subfix|dir.fix|nfo.fix|proof.fix|sample.fix|samplefix|readnfo|ac3|audioaddon|addon|ac3addon"

#--[ Script start ]---------------------------------------------

target=$(echo $1 | awk '{print $2}' | tr '[:upper:]' '[:lower:]')

# Skip common subdirs using improved regex matching
if [[ "$target" =~ (^(${subdirs})|${words}) ]]
then

    exit 0

fi

# Fire-and-forget so MKD isn’t slowed down.
# IMPORTANT: cd into the dir and then call rescan --quick (no --dir=)

cd $target && /bin/rescan --quick >/dev/null 2>&1
