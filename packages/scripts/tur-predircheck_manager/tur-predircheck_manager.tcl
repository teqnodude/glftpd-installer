#									     									 #
# Tur-Predircheck_Manager.tcl by Teqno                                       #
# Change binds below to whatever you want the trigger the script with.       #
# pub is for public chan command & msg is for private msg.                   #
#                                                                            #
# If tur-predircheck_manager.sh is not located in /glftpd/bin/, then         #
# change the path in 'set binary' below.                                     #
#                                                                            #
# Change mainchannel below to your irc channel. Users must be in that chan   #
# or they will be ignored. No capital letters in mainchan.                   #
#                                                                            #
# If you change irc trigger here then be sure it's the same in the script    #
# itself under "irctrigger"                                                  #
#                                                                            #
##############################################################################

namespace eval tur_predircheck {
    variable shfile      "/glftpd/bin/tur-predircheck_manager.sh"
    variable mainchan    "changeme"
    variable VERSION     "unknown"
    
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
        bind pub o !block [namespace current]::pub_tur_predircheck
        bind pub - !banned [namespace current]::pub_banned
        bind pub - !blocked [namespace current]::pub_banned
        
        putlog "Tur-Predircheck_Manager.tcl $VERSION by Teqno loaded"
    }
    
    # Main block command
    proc pub_tur_predircheck {nick host handle chan text} {
        variable mainchan
        variable shfile
        
        if {$chan eq $mainchan} {
            foreach line [split [exec $shfile $nick $text] "\n"] {
                putquick "PRIVMSG $chan :$line"
            }
        }
    }
    
    # Banned/blocked list command
    proc pub_banned {nick host handle chan text} {
        variable shfile
        
        foreach line [split [exec $shfile $nick list groups] "\n"] {
            putquick "PRIVMSG $nick :$line"
        }
        
        foreach line [split [exec $shfile $nick list sections] "\n"] {
            putquick "PRIVMSG $nick :$line"
        }
    }
}

# Initialize the namespace
tur_predircheck::init