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

namespace eval precheck {

    variable shfile "/glftpd/bin/precheck.sh"
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
        bind pub - !precheck [namespace current]::pub_precheck
        
        putlog "Precheck $VERSION by Teqno loaded"
    }
    
    # Precheck command
    proc pub_precheck {nick host handle chan text} {
        variable shfile
        
        set who [lindex $text 0]
        foreach line [split [exec $shfile $who] "\n"] {
            putquick "PRIVMSG $nick :$line"
        }
    }

}

# Initialize the namespace
precheck::init		     