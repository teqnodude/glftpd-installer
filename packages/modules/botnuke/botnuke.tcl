#############################################################################
# BotNuke by Turranius                                                      #
# Change !triggers below to whatever you want the trigger the script with.  #
# If botnuke.sh is not located in /glftpd/bin/, then change the paths       #
# to 'set binary' below.                                                    #
#############################################################################

namespace eval botnuker {
    variable shfile     "/glftpd/bin/botnuke.sh"
    variable VERSION    "unknown"

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
        bind pub o !nuke [namespace current]::pub_nuke
        bind msg o !nuke [namespace current]::msg_nuke
        bind pub o !unnuke [namespace current]::pub_unnuke
        bind msg o !unnuke [namespace current]::msg_unnuke

        putlog "BotNuker.tcl $VERSION by Turranius loaded"
    }

    # Public nuke command
    proc pub_nuke {nick uhost handle chan arg} {
        variable shfile

        if {[matchattr $handle o|o $chan]} {
            set release [lindex $arg 0]
            set multip [lindex $arg 1]
            set reason [lindex $arg 2]

            if {$release eq "" || $multip eq "" || $reason eq ""} {
                putquick "PRIVMSG $chan :Usage: !nuke <release> <multiplier> <reason>"
                return
            }

            foreach line [split [exec $shfile NUKE $release $multip $reason] "\n"] {
                putquick "PRIVMSG $nick :$line"
            }
        } else {
            putquick "PRIVMSG $chan :$nick: You are not an op"
        }
    }

    # Private message nuke command
    proc msg_nuke {nick host handle arg} {
        variable shfile

        if {[matchattr $handle o]} {
            set release [lindex $arg 0]
            set multip [lindex $arg 1]
            set reason [lindex $arg 2]

            if {$release eq "" || $multip eq "" || $reason eq ""} {
                putquick "PRIVMSG $nick :Usage: !nuke <release> <multiplier> <reason>"
                return
            }

            foreach line [split [exec $shfile NUKE $release $multip $reason] "\n"] {
                putquick "PRIVMSG $nick :$line"
            }
        } else {
            putquick "PRIVMSG $nick :You are not an op"
        }
    }

    # Public unnuke command
    proc pub_unnuke {nick uhost handle chan arg} {
        variable shfile

        if {[matchattr $handle o|o $chan]} {
            set release [lindex $arg 0]
            set reason [lindex $arg 1]

            if {$release eq "" || $reason eq ""} {
                putquick "PRIVMSG $chan :Usage: !unnuke <release> <reason>"
                return
            }

            foreach line [split [exec $shfile UNNUKE $release $reason] "\n"] {
                putquick "PRIVMSG $nick :$line"
            }
        } else {
            putquick "PRIVMSG $chan :$nick: You are not an op"
        }
    }

    # Private message unnuke command
    proc msg_unnuke {nick host handle arg} {
        variable shfile

        if {[matchattr $handle o]} {
            set release [lindex $arg 0]
            set reason [lindex $arg 1]

            if {$release eq "" || $reason eq ""} {
                putquick "PRIVMSG $nick :Usage: !unnuke <release> <reason>"
                return
            }

            foreach line [split [exec $shfile UNNUKE $release $reason] "\n"] {
                putquick "PRIVMSG $nick :$line"
            }
        } else {
            putquick "PRIVMSG $nick :You are not an op"
        }
    }
}

# Initialize the namespace
botnuker::init
