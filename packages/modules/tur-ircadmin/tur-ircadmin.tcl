##############################################################################
# Tur-IrcAdmin.tcl 1.1 by Turranius                                          #
# Change binds below to whatever you want the trigger the script with.       #
# pub is for public chan command & msg is for private msg.                   #
#                                                                            #      
# If tur-ircadmin.sh is not located in /glftpd/bin/, then change the path    #
# in all 'set binary' below.                                                 #
#                                                                            #
# Change mainchania below to your irc channel. Users must be in that chan or #
# they will be ignored. No capital letters in mainchan.                      #
#                                                                            #
# If using a /msg to the bot, the user must be in the mainchan.              #
#                                                                            #
# The o in the binds means that only ops can run it. By ops, I mean users    #
# added to THIS bot with +o in the mainchan. Just being a @ dosnt help.      #
# You can use any flag you want, just make sure the user is added in the bot #
# with that flag, in the #mainchan.                                          #
##############################################################################

bind pub o !site pub:tur-ircadmin
bind msg o !site msg:tur-ircadmin

set mainchania "changeme"

##############################################################################

## Public chan.
proc pub:tur-ircadmin {nick output binary chan text} {
  set binary {/glftpd/bin/tur-ircadmin.sh}
  global mainchania
  if {$chan == $mainchania} {
    foreach line [split [exec $binary $nick $text] "\n"] {
       putquick "PRIVMSG $chan :$line"
    }
  }
}

## /msg to bot.
proc msg:tur-ircadmin { nick host hand text } {
  set binary {/glftpd/bin/tur-ircadmin.sh}
  global mainchania
  set founduser "0"
  foreach user [chanlist $mainchania] {
    if {$nick == $user} {
      set founduser "1"
    }
  }


 if {$founduser == "1"} {
  foreach line [split [exec $binary $nick $text] "\n"] {
       putquick "PRIVMSG $nick :$line"
  }
 }
}

putlog "Tur-IrcAdmin.tcl 1.1 by Turranius loaded"
