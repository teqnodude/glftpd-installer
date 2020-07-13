##############################################################################
# Tur-Undupe.tcl 1.0 by Turranius                                            #
# Change !undupe below to whatever you want the trigger the script with.     #
# If tur-undupe.sh is not located in /glftpd/bin/, then change the path      #
# to 'set binary' below.                                                     #
##############################################################################

bind pub - !undupe pub:turundupe

## Msg undupe disabled by default. We want to see it in channel.
# bind msg - !undupe msg:turundupe


proc pub:turundupe {nick uhost handle chan arg} {
 set binary {/glftpd/bin/tur-undupe.sh}
 set what [lindex $arg 0]
 foreach line [split [exec $binary $what] "\n"] {
      putquick "PRIVMSG $chan :$line"
 }
}

proc msg:turundupe { nick host hand arg } {
 set binary {/glftpd/bin/tur-undupe.sh}
 set what [lindex $arg 0]
 foreach line [split [exec $binary $what] "\n"] {
      putquick "PRIVMSG $nick :$line"
 }
}

putlog "Tur-Undupe.tcl 1.0 by Turranius loaded"
