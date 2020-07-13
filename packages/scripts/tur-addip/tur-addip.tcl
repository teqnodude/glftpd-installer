##############################################################################
# Tur-AddIp.tcl 1.1 by Turranius                                             #
# Change binds below to whatever you want the trigger the script with.       #
# pub is for public chan command & msg is for private msg.                   #
#                                                                            #      
# If tur-addip.sh is not located in /glftpd/bin/, then change the path       #
# in 'set binary' below.                                                     #
#                                                                            #
# Change mainchan below to your irc channel. Users must be in that chan or   #
# they will be ignored. No capital letters in mainchan.                      #
##############################################################################

bind pub - !addip pub:tur-addip
bind msg - !addip msg:tur-addip

set mainchan "changeme"

##############################################################################

## In public = no no
proc pub:tur-addip {nick output binary chan text} {
  global mainchan
  putlog "$nick runs !addip from $chan - Mainchan: $mainchan"
  if {$chan == $mainchan} {
    putquick "PRIVMSG $chan :Use a PM for this command please."
  }
}

## /msg to bot.
proc msg:tur-addip { nick host hand text } {
  set binary {/glftpd/bin/tur-addip.sh}
  global mainchan
  set founduser "0"
  foreach user [chanlist $mainchan] {
    if {$nick == $user} {
      set founduser "1"
    }
  }


 if {$founduser == "1"} {
  set action [lindex $text 0]
  set username [lindex $text 1]
  set password [lindex $text 2]
  set curip [lrange $text 3 end]
  foreach line [split [exec $binary $action $username $password $curip] "\n"] {
       putquick "PRIVMSG $nick :$line"
  }
 }
}

putlog "Tur-AddIp.tcl 1.1 by Turranius loaded"
