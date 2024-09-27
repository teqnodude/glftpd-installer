##############################################################################
# tur-trial3.tcl 1.0 by Turranius                                            #
# Change !triggers below to whatever you want the trigger the script with.   #
# If tur-trial3.sh is not located in /glftpd/bin/, then change               #
# the path to 'set binary' below.                                            #
##############################################################################

bind pub -|- !passed pub:trialscript3
bind pub -|- !trials pub:trialscriptlist3
bind pub -|- !quota pub:trialscriptqlist3
bind pub o|o !tt3 pub:trialscriptadmin3
bind msg o|o !tt3 msg:trialscriptadmin3
bind pub -|- !quotatopup pub:trialscriptstats
bind pub -|- !quotatopupex pub:trialscriptstatsex

set tt3binary "/glftpd/bin/tur-trial3.sh"

##############################################################################

proc pub:trialscript3 {nick output binary chan text} { 
  global tt3binary
  set who [lindex $text 0]
  foreach line [split [exec $tt3binary check $who] "\n"] {
    if { [lindex $line 0] != "DEBUG:"} {
	putquick "PRIVMSG $chan :$line"
    }
  }
  putquick "NOTICE $nick :Note: Updates on positions are done every 30 minutes."
}

proc pub:trialscriptlist3 {nick output binary chan text} { 
  global tt3binary
  foreach line [split [exec $tt3binary tlist] "\n"] {
    if { [lindex $line 0] != "DEBUG:"} {
	putquick "PRIVMSG $chan :$line"
    }
  }
}

proc pub:trialscriptqlist3 {nick output binary chan text} { 
  putquick "PRIVMSG $chan :Please wait."
  global tt3binary
  set mode [lindex $text 0]
  foreach line [split [exec $tt3binary qlist $mode] "\n"] {
    if { [lindex $line 0] != "DEBUG:"} {
	putquick "PRIVMSG $chan :$line"
    }
  }

}


proc pub:trialscriptadmin3 {nick output binary chan text} { 
  global tt3binary
  set com1 [lindex $text 0]
  set com2 [lindex $text 1]
  set com3 [lindex $text 2]
  foreach line [split [exec $tt3binary $com1 $com2 $com3] "\n"] {
    if { [lindex $line 0] != "DEBUG:"} {
	putquick "PRIVMSG $nick :$line"
    }
  }
}

proc msg:trialscriptadmin3 { nick uhost chan arg } {
  global tt3binary
  set com1 [lindex $arg 0]
  set com2 [lindex $arg 1]
  set com3 [lindex $arg 2]
  foreach line [split [exec $tt3binary $com1 $com2 $com3] "\n"] {
    if { [lindex $line 0] != "DEBUG:"} {
	putquick "PRIVMSG $nick :$line"
    }
  }
}

proc pub:trialscriptstats {nick output binary chan text} { 
  global tt3binary
  set com1 [lindex $text 0]
  foreach line [split [exec $tt3binary stats $com1] "\n"] {
    if { [lindex $line 0] != "DEBUG:"} {
	putquick "PRIVMSG $nick :$line"
    }
  }
}

proc pub:trialscriptstatsex {nick output binary chan text} { 
  global tt3binary
  set com1 [lindex $text 0]
  foreach line [split [exec $tt3binary statsex $com1] "\n"] {
    if { [lindex $line 0] != "DEBUG:"} {
	putquick "PRIVMSG $nick :$line"
    }
  }
}


putlog "tur-trial3.tcl 1.0 by Turranius loaded"
