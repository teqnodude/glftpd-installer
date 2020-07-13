################################################################################
# slv-prebw v1.0 20190609 for ngBot/dZSbot
################################################################################

namespace eval ::ngBot::plugin::PreBW {
    variable ns [namespace current]
    ## Config Settings ###############################
    ##
    ## Choose one of two settings: the first when using ngBot, the second when using dZSbot
    variable np [namespace qualifiers [namespace parent]]
    #variable np ""
    ##
    variable bashScript "$::ngBot::glroot/bin/slv-prebw.sh"
    variable scriptName ${ns}::LogEvent
    variable events [list "PRE"]
    ## If you use a different PRE event/announce you can add it above
    ## Example: [list "PRE" "PREMP3" "ISOPRE"]

    #bind evnt -|- prerehash ${ns}::DeInit

    if {[string equal "" $np]} {
        bind evnt -|- prerehash ${ns}::deinit
    }

    proc init {} {
        variable np
        variable events
        variable scriptName
        variable ${np}::precommand
        putlog "\[ngBot\] PreBW :: Loaded successfully."
        foreach event $events {
            lappend precommand($event) $scriptName
        }
        return
    }

    proc deinit {} {
        variable ns
        variable np
        variable events
        variable scriptName
        variable ${np}::precommand
        foreach event $events {
            if {[info exists precommand($event)] && [set pos [lsearch -exact $precommand($event) $scriptName]] !=  -1} {
               set precommand($event) [lreplace $precommand($event) $pos $pos]
            }
        }
        namespace delete $ns
        #catch {unbind evnt -|- prerehash ${ns}::deinit}
        return
    }

    proc LogEvent {event section logData} {
        variable bashScript
        variable events
        if {[lsearch $events $event] != -1} {
            exec $bashScript [lindex $logData 0] &
        }
        return 1
    }
}

if {[string equal "" $::ngBot::plugin::PreBW::np]} {
        ::ngBot::plugin::PreBW::init
}
