##############################################################################
# Tur-Free.tcl 1.0 by Turranius                                              #
# Change !free and/or !df  below to whatever you want the trigger the script #
# with.                                                                      #
# If tur-free.sh is not located in /glftpd/bin/, then change the path        #
# to 'set binary' below.                                                     #
##############################################################################

bind pub - !df pub:turfreecheck
bind pub - !free pub:turfreecheck
bind msg - !df msg:turfreecheck
bind msg - !free msg:turfreecheck

proc pub:turfreecheck {nick uhost handle chan arg} {
 set binary {/glftpd/bin/tur-free.sh}
 set section [lindex $arg 0]
 foreach line [split [exec $binary $section] "\n"] {
      putquick "PRIVMSG $chan :$line"
 }
}

proc msg:turfreecheck { nick host hand arg } {
 set binary {/glftpd/bin/tur-free.sh}
 set section [lindex $arg 0]
 foreach line [split [exec $binary $section] "\n"] {
      putquick "PRIVMSG $nick :$line"
 }
}

putlog "Tur-Free.tcl 1.0 by Turranius loaded"
