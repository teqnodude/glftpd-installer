##############################################################################
# Tur-DirAllow.tcl 1.0 by Turranius                                          #
# Change !dirallow below to whatever you want the trigger the script with.   #
# If tur-dirallow.sh is not located in /glftpd/bin/, then change the path    #
# to 'set binary' below.                                                     #
##############################################################################

bind pub - !dirallow pub:turdirallow
bind msg - !dirallow msg:turdirallow


proc pub:turdirallow {nick uhost handle chan arg} {
 set binary {/glftpd/bin/tur-dirallow.sh}
 set what [lindex $arg 0]
 foreach line [split [exec $binary $what] "\n"] {
      putquick "PRIVMSG $chan :$line"
 }
}

proc msg:turdirallow { nick host hand arg } {
 set binary {/glftpd/bin/tur-dirallow.sh}
 set what [lindex $arg 0]
 foreach line [split [exec $binary $what] "\n"] {
      putquick "PRIVMSG $nick :$line"
 }
}

putlog "Tur-DirAllow.tcl 1.0 by Turranius loaded"
