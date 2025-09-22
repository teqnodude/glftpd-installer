#                                                               #
# Ircnick by Teqno                                              #
#                                                               #
# Let's you check what ircnick user has on site, only           #
# works for sites that require users to invite themselves into  #
# channels.                                                     #
#                                                               #
#################################################################

namespace eval ircnick {
    variable shfile "/glftpd/bin/ircnick.sh"
    variable mainchan "changeme"
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
        bind pub - !ircnick [namespace current]::pub_ircnick
        
        putlog "Ircnick $VERSION by Teqno loaded"
    }
    
    # Ircnick command
    proc pub_ircnick {nick uhost handle chan arg} {
        variable mainchan
        variable shfile
        
        if {[matchattr $handle o|o $chan]} {
            set release [lindex $arg 0]
            
            if {$release == ""} {
                putquick "PRIVMSG $chan :Usage: !ircnick <release>"
                return
            }
            
            if {$chan eq $mainchan} {
                foreach line [split [exec $shfile $release $nick] "\n"] {
                    putquick "PRIVMSG $chan :$line"
                }
            }
        } else {
            putquick "PRIVMSG $chan :$nick: You are not an op"
        }
    }
}

# Initialize the namespace
ircnick::init