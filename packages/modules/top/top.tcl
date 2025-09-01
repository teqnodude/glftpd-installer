#########################################################################
#                                                                       #
# Top.tcl 1.1 by Teqno                                                  #
#                                                                       #
#########################################################################

bind pub -|- !top pub:topup
bind pub -|- !topdn pub:topdn

set topbinary "/glftpd/bin/top.sh"

proc pub:topup {nick output binary chan text} {
 
    global topbinary
    
    if {$text == ""} {

	putquick "PRIVMSG $chan :Getting information, please wait..."
	putquick "PRIVMSG $chan :This Month Top 10 Stats (Upload)"

	foreach line [split [exec $topbinary -m -u -x 10] "\n"] {

	    putquick "PRIVMSG $chan :$line"

        }

    }

    if {$text != ""} {

	if {$text >= "31"} {

	    putquick "PRIVMSG $chan :Max 30 results are allowed"

	} else {

    	    putquick "PRIVMSG $chan :Getting information, please wait..."
	    putquick "PRIVMSG $chan :This Month Top $text Stats (Upload)"

	    foreach line [split [exec $topbinary -m -u -x $text] "\n"] {

		putquick "PRIVMSG $chan :$line"

	    }

	}

    }

}

proc pub:topdn {nick output binary chan text} {

    global topbinary
    
    if {$text == ""} {
    
        putquick "PRIVMSG $chan :Getting information, please wait..."
        putquick "PRIVMSG $chan :This Month Top 10 Stats (Download)"
    
        foreach line [split [exec $topbinary -m -d -x 10] "\n"] {
    
    	    putquick "PRIVMSG $chan :$line"
    
        }
    
    }
    
    if {$text != ""} {
    
        if {$text >= "31"} {
    
    	    putquick "PRIVMSG $chan :Max 30 results are allowed"
    
        } else {

	    putquick "PRIVMSG $chan :Getting information, please wait..."
    	    putquick "PRIVMSG $chan :This Month Top $text Stats (Download)"

            foreach line [split [exec $topbinary -m -d -x $text] "\n"] {

	        putquick "PRIVMSG $chan :$line"

            }

        }

    }

}

putlog "Top 1.1 by Teqno loaded"

