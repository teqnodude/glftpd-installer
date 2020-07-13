#									     #
# Tur-Predircheck_Manager.tcl 1.6 by Teqno                                   #
# Change binds below to whatever you want the trigger the script with.       #
# pub is for public chan command & msg is for private msg.                   #
#                                                                            #
# If tur-predircheck_manager.sh is not located in /glftpd/bin/, then         #
# change the path in 'set binary' below.                                     #
#                                                                            #
# Change mainchannel below to your irc channel. Users must be in that chan   #
# or they will be ignored. No capital letters in mainchan.                   #
#                                                                            #
# If you change irc trigger here then be sure it's the same in the script    #
# itself under "irctrigger"                                                  #
#                                                                            #
##############################################################################

bind pub o !block pub:tur-predircheck
bind pub - !banned pub:banned
bind pub - !blocked pub:banned

set mainchannel "changeme"

##############################################################################

## Public chan.
proc pub:tur-predircheck {nick output binary chan text} {
  set binary {/glftpd/bin/tur-predircheck_manager.sh}
  global mainchannel
  if {$chan == $mainchannel} {
    foreach line [split [exec $binary $nick $text] "\n"] {
       putquick "PRIVMSG $chan :$line"
    }
  }
}

proc pub:banned {nick output binary chan text} {
  set binary {/glftpd/bin/tur-predircheck_manager.sh}
    foreach line [split [exec $binary $nick list groups] "\n"] {
       putquick "PRIVMSG $nick :$line"
    }
    foreach line [split [exec $binary $nick list sections] "\n"] {
       putquick "PRIVMSG $nick :$line"
    }


}

putlog "Tur-Predircheck_Manager.tcl 1.6 by Teqno loaded"
