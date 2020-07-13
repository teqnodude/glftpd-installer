#################################################################
#                                                               #
# Precheck by Teqno                                             #
#                                                               #
# Adds !precheck cmd to irc, to search for a group's pre's      #
# on site. Just copy the precheck.sh in to /glftpd/bin and put  #
# the tcl in your sitebot/scripts dir. Then put this line in to #
# your eggdrop.conf                                             #
#                                                               #
#################################################################

bind pub - !precheck pub:precheck

proc pub:precheck {nick output binary chan text} {
	set binary {/glftpd/bin/precheck.sh}
	set who [lindex $text 0]
	foreach line [split [exec $binary $who] "\n"] {
		putquick "PRIVMSG $nick :$line"
	}
}

putlog "Precheck 1.0 by Teqno loaded"

		     