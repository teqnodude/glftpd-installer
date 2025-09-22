#################################################################
#                                                               #
# Mediainfo by Teqno                                            #
#                                                               #
# It extracts info from *.rar file for related releases to      #
# give the user ability to compare quality.                     #
#                                                               #
#################################################################

namespace eval mediainfo {

    variable shfile "/glftpd/bin/mediainfo.sh"
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
        bind pub - !mediainfo [namespace current]::pub_mediainfo
        bind pub - !mi [namespace current]::pub_mediainfo
        
        putlog "Mediainfo.tcl $VERSION by Teqno loaded"
    }
    
    # Mediainfo command
    proc pub_mediainfo {nick host handle chan text} {
        variable shfile
        
        putquick "PRIVMSG $chan :Getting info, please wait..."
        
        foreach line [split [exec $shfile $nick $text] "\n"] {
            putquick "PRIVMSG $chan :$line"
        }
    }

}

# Initialize the namespace
mediainfo::init