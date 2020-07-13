##############################################################################
# tur-oneline_stats.tcl 1.0 by Turranius tweaked by Teqno                    #
##############################################################################

bind pub -|- !top pub:tur-onelinemnup


set turonelinestatsbinary "/glftpd/bin/tur-oneline_stats.sh"

proc pub:tur-onelinemnup {nick output binary chan text} {

 global turonelinestatsbinary
    if {$text == ""} {

        putquick "PRIVMSG $chan :Getting information, please wait..."
        putquick "PRIVMSG $chan :This Month Top 10 Stats (Upload)"
        foreach line [split [exec $turonelinestatsbinary -m -u -x 10] "\n"] {
        putquick "PRIVMSG $chan :$line"
        }

    }
    if {$text != ""} {

        if {$text >= "31"} {
        putquick "PRIVMSG $chan :Max 30 results are allowed"
        }

        if {$text <= "30"} {
        putquick "PRIVMSG $chan :Getting information, please wait..."
        putquick "PRIVMSG $chan :This Month Top $text Stats (Upload)"
        foreach line [split [exec $turonelinestatsbinary -m -u -x $text] "\n"] {
        putquick "PRIVMSG $chan :$line"
        }

        }
    }
}


putlog "Tur-Oneline_Stats.tcl 1.0 by Turranius loaded"
