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
subdirs="cd??|disc??|disk??|dvd??|extra?|sub?|subtitle?|vobsub?|sample?|subpack?|s??|ac3|audioaddon|addon|ac3addon|proof|cover?|tools|dirfix|nfofix|prooffix|proofix|subfix|dir.fix|nfo.fix|proof.fix|SAMPLE.FiX|SAMPLEFIX|readnfo"

#--[ Script start ]---------------------------------------------

target=$(echo $1 | awk '{print $2}')

# Skip common subdirs (mirror of your subdir_list)
case "$(echo "$target" | tr '[:upper:]' '[:lower:]')" in
	
	$subdirs)
    exit 0
    ;;
    
esac

# Fire-and-forget so MKD isn’t slowed down.
# IMPORTANT: cd into the dir and then call rescan --quick (no --dir=)

cd $target && /bin/rescan --quick >/dev/null 2>&1
