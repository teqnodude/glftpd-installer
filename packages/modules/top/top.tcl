#########################################################################
#                                                                       #
# Top.tcl by Teqno                                                  	#
#                                                                       #
#########################################################################

namespace eval topstats {

    variable shfile "/glftpd/bin/top.sh"
    variable VERSION "unknown"
    
    # Initialize the namespace
    proc init {} {
        variable shfile
        variable VERSION
        
        # Read version from script file
        set fh [open $shfile r]
        set data [read $fh]
        close $fh
        
        if {[regexp -- {VER\s*=\s*([A-Za-z0-9._-]+)} $data -> version]} {
            set VERSION $version
        }
        
        # Set up binds
        bind pub -|- !top [namespace current]::pub_topup
        bind pub -|- !topdn [namespace current]::pub_topdn
        
        putlog "Top $VERSION by Teqno loaded"
    }
    
    # Top upload command
    proc pub_topup {nick host handle chan text} {
        variable shfile
        
        if {$text == ""} {
            putquick "PRIVMSG $chan :Getting information, please wait..."
            putquick "PRIVMSG $chan :This Month Top 10 Stats (Upload)"
            
            foreach line [split [exec $shfile -m -u -x 10] "\n"] {
                putquick "PRIVMSG $chan :$line"
            }
        }
        
        if {$text != ""} {
            if {$text >= "31"} {
                putquick "PRIVMSG $chan :Max 30 results are allowed"
            } else {
                putquick "PRIVMSG $chan :Getting information, please wait..."
                putquick "PRIVMSG $chan :This Month Top $text Stats (Upload)"
                
                foreach line [split [exec $shfile -m -u -x $text] "\n"] {
                    putquick "PRIVMSG $chan :$line"
                }
            }
        }
    }
    
    # Top download command
    proc pub_topdn {nick host handle chan text} {
        variable shfile
        
        if {$text == ""} {
            putquick "PRIVMSG $chan :Getting information, please wait..."
            putquick "PRIVMSG $chan :This Month Top 10 Stats (Download)"
            
            foreach line [split [exec $shfile -m -d -x 10] "\n"] {
                putquick "PRIVMSG $chan :$line"
            }
        }
        
        if {$text != ""} {
            if {$text >= "31"} {
                putquick "PRIVMSG $chan :Max 30 results are allowed"
            } else {
                putquick "PRIVMSG $chan :Getting information, please wait..."
                putquick "PRIVMSG $chan :This Month Top $text Stats (Download)"
                
                foreach line [split [exec $shfile -m -d -x $text] "\n"] {
                    putquick "PRIVMSG $chan :$line"
                }
            }
        }
    }

}

# Initialize the namespace
topstats::init