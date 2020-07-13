##############################################################################
# Tur-Rules.tcl 1.0 by Turranius                                             #
# Change !rules below to whatever you want the trigger the script with.      #
# If tur-rules.sh is not located in /glftpd/bin/, then change the path       #
# to 'set binary' below.                                                     #
##############################################################################

bind pub - !rules pub:turrules
bind msg - !rules msg:turrules

proc pub:turrules {nick uhost handle chan arg} {
 set binary {/glftpd/bin/tur-rules.sh}
 set section [lindex $arg 0]
 set searchword [lindex $arg 1]
 foreach line [split [exec $binary $section $searchword] "\n"] {
      putquick "PRIVMSG $nick :$line"
 }
}

proc msg:turrules { nick host hand arg } {
 set binary {/glftpd/bin/tur-rules.sh}
 set section [lindex $arg 0]
 set searchword [lindex $arg 1]
 foreach line [split [exec $binary $section $searchword] "\n"] {
      putquick "PRIVMSG $nick :$line"
 }
}

putlog "Tur-Rules.tcl 1.0 by Turranius loaded"
