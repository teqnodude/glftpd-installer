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

namespace eval section_traffic {

    variable shfile "/glftpd/bin/section-traffic.sh"
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
        bind pub o !st [namespace current]::pub_section_traffic
        
        putlog "section-traffic.tcl $VERSION by Teqno loaded"
    }
    
    # Section traffic command
    proc pub_section_traffic {nick host handle chan text} {
        variable mainchan
        variable shfile
        
        if {$chan eq $mainchan} {
            putquick "PRIVMSG $chan : \0037Gathering info, please wait..."
            
            foreach line [split [exec $shfile $nick $text] "\n"] {
                putquick "PRIVMSG $chan :$line"
            }
        }
    }

}

# Initialize the namespace
section_traffic::init