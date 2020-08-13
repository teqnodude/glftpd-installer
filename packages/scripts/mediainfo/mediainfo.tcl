#################################################################
#                                                               #
# Mediainfo by Teqno                                            #
#                                                               #
# It extracts info from *.rar file for related releases to      #
# give the user ability to compare quality.                     #
#                                                               #
#################################################################

bind pub - !mediainfo pub:mediainfo
bind pub - !mi pub:mediainfo

proc pub:mediainfo {nick output binary chan text} {
  set binary {/glftpd/bin/mediainfo.sh}
  putquick "PRIVMSG $chan :Getting info, please wait..."
    foreach line [split [exec $binary $nick $text] "\n"] {
       putquick "PRIVMSG $chan :$line"
    }
}

putlog "Mediainfo.tcl 1.6 by Teqno loaded"
