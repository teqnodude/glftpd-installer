#                                                               #
# Ircnick by Teqno                                              #
#                                                               #
# Let's you check what ircnick user has on site, only           #
# works for sites that require users to invite themselves into  #
# channels.                                                     #
#                                                               #
#################################################################

bind pub - !ircnick pub:ircnick

set mainchania "changeme"

proc pub:ircnick {nick uhost handle chan arg} {
global mainchania

if {[matchattr $nick +o]} {
    set binary {/glftpd/bin/ircnick.sh}
    set release [lindex $arg 0]
    set output [exec $binary $release $nick]
    if { $chan == $mainchania } {
        foreach line [split [exec $binary $release] "\n"] {
        putquick "PRIVMSG $chan :$line"
        }
    }
} else { putquick "PRIVMSG $nick :You are not an op" }

}

putlog "Ircnick 1.1 by Teqno loaded"
