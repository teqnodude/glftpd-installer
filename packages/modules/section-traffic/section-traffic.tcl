#                                                                            #
# Section-Traffic.tcl 1.0 by Teqno                                           #
# Change binds below to whatever you want the trigger the script with.       #
#                                                                            #
# If section-traffic.sh is not located in /glftpd/bin/, then                 #
# change the path in 'set binary' below.                                     #
#                                                                            #
# Change stmainchannel below to your irc channel. Users must be in that chan #
# or they will be ignored. No capital letters in mainchan.                   #
#                                                                            #
# If you change irc trigger here then be sure it's the same in the script    #
#                                                                            #
##############################################################################

bind pub o !st pub:section-traffic

set stmainchannel "changeme"

##############################################################################

## Public chan.
proc pub:section-traffic {nick output binary chan text} {

    set binary {/glftpd/bin/section-traffic.sh}
    global stmainchannel

    if {$chan == $stmainchannel} {

	putquick "PRIVMSG $chan : \0037Gathering info, please wait..."

	foreach line [split [exec $binary $nick $text] "\n"] {
    
    	    putquick "PRIVMSG $chan :$line"

	}

    }

}

putlog "section-traffic.tcl 1.3 by Teqno loaded"
