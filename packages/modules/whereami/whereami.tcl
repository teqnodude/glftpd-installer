##############################################################################
# whereami.tcl 1.2 by Turranius                                              #
# If whereami.sh is not located in /glftpd/bin/, then change                 #
# the path to 'set whereamibin' below.                                       #
# See whereami.sh script for more detailed installation instructions.        #
##############################################################################

bind pub - !alup pub:alup
bind pub - !aldn pub:aldn
bind pub - !mnup pub:mnup
bind pub - !mndn pub:mndn
bind pub - !wkup pub:wkup
bind pub - !wkdn pub:wkdn
bind pub - !tdup pub:tdup
bind pub - !tddn pub:tddn
bind pub - !nuketop pub:nuketop

bind pub - !galup pub:galup
bind pub - !galdn pub:galdn
bind pub - !gmnup pub:gmnup
bind pub - !gmndn pub:gmndn
bind pub - !gwkup pub:gwkup
bind pub - !gwkdn pub:gwkdn
bind pub - !gtdup pub:gtdup
bind pub - !gtddn pub:gtddn

set whereamibin {/glftpd/bin/whereami.sh}

#--[ Dont touch below ]--#

proc pub:alup {nick output binary chan text} { 
 global whereamibin
 set who [lindex $text 0]
 set output [exec $whereamibin $who a u]
 putquick "PRIVMSG $chan :$output"
}

proc pub:aldn {nick output binary chan text} { 
 global whereamibin
 set who [lindex $text 0]
 set output [exec $whereamibin $who a d]
 putquick "PRIVMSG $chan :$output"
}

proc pub:mnup {nick output binary chan text} { 
 global whereamibin
 set who [lindex $text 0]
 set output [exec $whereamibin $who m u]
 putquick "PRIVMSG $chan :$output"
}

proc pub:mndn {nick output binary chan text} { 
 global whereamibin
 set who [lindex $text 0]
 set output [exec $whereamibin $who m d]
 putquick "PRIVMSG $chan :$output"
}

proc pub:wkup {nick output binary chan text} { 
 global whereamibin
 set who [lindex $text 0]
 set output [exec $whereamibin $who w u]
 putquick "PRIVMSG $chan :$output"
}

proc pub:wkdn {nick output binary chan text} { 
 global whereamibin
 set who [lindex $text 0]
 set output [exec $whereamibin $who w d]
 putquick "PRIVMSG $chan :$output"
}

proc pub:tdup {nick output binary chan text} { 
 global whereamibin
 set who [lindex $text 0]
 set output [exec $whereamibin $who t u]
 putquick "PRIVMSG $chan :$output"
}

proc pub:tddn {nick output binary chan text} { 
 global whereamibin
 set who [lindex $text 0]
 set output [exec $whereamibin $who t d]
 putquick "PRIVMSG $chan :$output"
}

proc pub:galup {nick output binary chan text} { 
 global whereamibin
 set who [lindex $text 0]
 set output [exec $whereamibin $who A u]
 putquick "PRIVMSG $chan :$output"
}

proc pub:galdn {nick output binary chan text} { 
 global whereamibin
 set who [lindex $text 0]
 set output [exec $whereamibin $who A d]
 putquick "PRIVMSG $chan :$output"
}

proc pub:gmnup {nick output binary chan text} { 
 global whereamibin
 set who [lindex $text 0]
 set output [exec $whereamibin $who M u]
 putquick "PRIVMSG $chan :$output"
}

proc pub:gmndn {nick output binary chan text} { 
 global whereamibin
 set who [lindex $text 0]
 set output [exec $whereamibin $who M d]
 putquick "PRIVMSG $chan :$output"
}

proc pub:gwkup {nick output binary chan text} { 
 global whereamibin
 set who [lindex $text 0]
 set output [exec $whereamibin $who W u]
 putquick "PRIVMSG $chan :$output"
}

proc pub:gwkdn {nick output binary chan text} { 
 global whereamibin
 set who [lindex $text 0]
 set output [exec $whereamibin $who W d]
 putquick "PRIVMSG $chan :$output"
}

proc pub:gtdup {nick output binary chan text} { 
 global whereamibin
 set who [lindex $text 0]
 set output [exec $whereamibin $who T u]
 putquick "PRIVMSG $chan :$output"
}

proc pub:gtddn {nick output binary chan text} { 
 global whereamibin
 set who [lindex $text 0]
 set output [exec $whereamibin $who T d]
 putquick "PRIVMSG $chan :$output"
}

proc pub:nuketop {nick output binary chan text} { 
 global whereamibin
 set who [lindex $text 0]
 set output [exec $whereamibin nuketop $who]
 putquick "PRIVMSG $chan :$output"
}

putlog "WhereAmI.tcl 1.2 by Turranius loaded"