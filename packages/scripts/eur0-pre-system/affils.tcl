#################################################################################
#                                                                               #
# Affils by Teqno                                                               #
#                                                                               #
# A script that list added affils on irc                                        #
#                                                                               #
#################################################################################
bind pub - !affils pub:affils

proc pub:affils {nick uhost hand chan args} {

    set output [exec /glftpd/bin/listaffils.sh]
    putquick "PRIVMSG $chan :$output"
}

putlog "Affils.tcl 1.0 by Teqno loaded"
