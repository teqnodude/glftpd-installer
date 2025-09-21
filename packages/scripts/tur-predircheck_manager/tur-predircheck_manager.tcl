#									     #
# Tur-Predircheck_Manager.tcl by Teqno                                       #
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

# path to the .sh script
set shfile "/glftpd/bin/tur-predircheck_manager.sh"

bind pub o !block pub:tur-predircheck
bind pub - !banned pub:banned
bind pub - !blocked pub:banned

set mainchannel "changeme"

##############################################################################

## Public chan.
proc pub:tur-predircheck {nick output chan text} {

  	global mainchannel shfile
  	
  	if {$chan eq $mainchannel} {
    
    	foreach line [split [exec $shfile $nick $text] "\n"] {
    
       		putquick "PRIVMSG $chan :$line"
	
	    }

  	}

}

proc pub:banned {nick output chan text} {
	
	global shfile
    
    foreach line [split [exec $shfile $nick list groups] "\n"] {
       
       putquick "PRIVMSG $nick :$line"

    }

    foreach line [split [exec $shfile $nick list sections] "\n"] {

       putquick "PRIVMSG $nick :$line"

    }

}

set fh [open $shfile r]
set data [read $fh]
close $fh

if {![regexp -- {VER\s*=\s*([A-Za-z0-9._-]+)} $data -> VERSION]} {
    set VERSION "unknown"
}

putlog "Tur-Predircheck_Manager.tcl $VERSION by Teqno loaded"
