#######################################################
# IdleBotKick.                                        #
# If idlebotkick.sh is not in /glftpd/bin, then       #
# change its path in set binary below.                #
# Change !kick to whatever you wish to trigger it     #
# with. The o in "pub o" makes sure only ops can run  #
# it. To make it public, replace o with -             #
#######################################################


bind pub o !kick pub:idlebotkick

proc pub:idlebotkick {nick output binary chan text} { 
 set binary {/glftpd/bin/idlebotkick.sh}
 set who [lindex $text 0]
    if { $who == "" } {
      putquick "PRIVMSG $chan :Checking idle users. Please wait."
    }
 foreach line [split [exec $binary $who] "\n"] {
   putquick "PRIVMSG $chan :$line"
 }
}

putlog "IdleBotKick 1.1 by Turranius loaded"