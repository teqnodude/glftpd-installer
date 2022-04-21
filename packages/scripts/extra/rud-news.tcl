##################
#  rud-news.tcl  #
##################
#
##########
#  Info  #
##########
#
# webpage: http://www.distorted.se/tcl/
#
# !news script for displaying news in your irc channel(s), !addnews for easy adding
# security for adding either by host or by channel, and by user flags in the bind also
# the delay for displaying the news is configureable, and most output is configureable
# enjoy
#
#############
#  Licence  #
#############
#
# Feel free to do whatever with this script as long as I'm credited as original author
#
###############
#  Changelog  #
###############
#
# 2011-06-29 - 1.2.1
#  Apparently there was two places that said pytserv instead of putserv, dunno how that lasted 4½ years.
#
# 2006-12-03 - 1.2
#  Added !delnews triggers, takes an integer for argument, 1 deleted the newest news, 2 the second newest, 3 the one after that and so on
#  Made some code changes to reuse some code, better for future updates :)
#
# 2006-11-30 - 1.1a
#   Added text to show if nothing is found while searching (threw an error in 1.1)
#   Added support for turning off the timed news announce
#
# 2006-11-28 - 1.1
#   Added search function, ie. !news affils , to get all news with "affils" in the somewhere
#   Added help text on !news help
#
# 2006-11-07 - 1.0.1
#   Added !addnews as a msg command
#
# 2006-11-06 - 1.0
#   Initial release, security settings not throughtly tested.
#
#####################
#  Config Settings  #
#####################

## file to store the news in ?
set news(file) "data.news"

## space seperated list of channels to announce news in
set news(channels) "#changeme"

## set number of news to show when triggered by timer (consider anti-flood protection)
set news(showtimer) 4

## max number of news to show when triggered by !news (consider anti-flood protection)
set news(shownotice) 20

## how many news do we display by default in reply to !news
set news(noticedefault) 20

## how many news to show if the user is searching for something (usually just a few matches needed)
set news(searchdefault) 4

## from what channel are news allowed to be added and deleted (!addnews, !delnews)
set news(addchan) "#personal"

## from what hosts are news allowed to be added ande deleted no matter channel
set news(addhosts) "my@host.com *@my.1337.vhost.net"

## what delay between the news in minutes (I like to have this at something odd so it moves every day), 0 disables timed announce
set news(timer) 0

## what delay in minutes from loading this script till it prints the news first time, 0 disables timed announce
set news(firstrun) 0

## headerstyle
set news(header) "\00313\002NEWS:\002 - !news for a longer list\003"

## dateformat (default is: 06 Nov 03:20) http://www.tcl.tk/man/tcl8.4/TclCmd/clock.htm#M6 for help
set news(dateformat) "%Y-%m-%d %H:%M"

## linestyle, %time %user and %news are valid cookies
set news(line) "\[%time\] %user - %news"

## add news style, %user and %news are valid cookies
set news(addstyle) "\00313\002News added by %user:\002\003 %news"

## text to display if nothing is found while searching, %search for the search string
set news(nothingfound) "Sorry but nothing was found when searching for %search"

## help text
set news(help) {
!news usage:
!news [number] [search]
!news  - get a list of latest news
!news <number>  - get a list of <number> latest news
!news <search>  - get a list of latest news matching <search>, wildcards * and ?
!news <number> <search>  - get a list of <number> latest news matching <search>, wildcards * and ?
}

##############
#  Bindings  #
##############

# the o means that only users the bot recognize as op will be allowed to use the command
# set this to - to allow all users no matter the status in the bot to run the command

bind pub - !news rud:pub:news
bind pub o !addnews rud:pub:addnews
bind msg o !addnews rud:msg:addnews
bind pub o !delnews rud:pub:delnews
bind msg o !delnews rud:msg:delnews

###############################
#  No edit below here needed  #
###############################

set news(version) 1.2.1

proc rud:pub:news { nick uhost handle chan arg } {
	global news

	set fp [open $news(file) r]
	set data [split [read $fp] "\n"]
        set size [file size $news(file)]
        if { $size eq 0 } {
        putserv "NOTICE $nick :No news added."
        }
	close $fp

  if { $arg eq "help" } {
  	foreach line [split $news(help) \n] {
			if { [string trim $line] != "" } {
	  		putserv "NOTICE $nick :$line"
			}
  	}
  	return
  }

	if { [string trim $arg] == "" } { 
		set numreplies $news(noticedefault)
  } elseif { [string is integer [set numreplies [lindex [split $arg] 0]]] } {
  	if { $numreplies > $news(shownotice) } { 
  		set numreplies $news(shownotice) 
  	}
		if { $numreplies > [llength $data] } { 
			set numreplies [llength $data] 
		} 
		if { [llength [split $arg]] > 1 } { 
			set searchstring [lrange [split $arg] 1 end]
		}
	} elseif { [string is integer [set numreplies [lindex [split $arg] end]]] } {
  	if { $numreplies > $news(shownotice) } { 
  		set numreplies $news(shownotice) 
  	}
		if { $numreplies > [llength $data] } { 
			set numreplies [llength $data] 
		} 
		if { [llength [split $arg]] > 1 } { 
			set searchstring [lrange [split $arg] 0 end-1]
		}
	} else {
		set numreplies $news(searchdefault)
		set searchstring $arg
	}

  if { [info exists searchstring] } {
  	foreach line $data {
  		if { [string match -nocase "*$searchstring*" [lrange [split $line] 2 end]] } {
  			lappend newdata $line
  		}
  	}
  	
  	if { ![info exists newdata] } { putserv "NOTICE $nick :[string map [list "%search" $searchstring] $news(nothingfound)]" ; return }
  	
  	if { $numreplies > [llength $newdata] } { set numreplies [llength $newdata] }
  	
  	for { set i [expr [llength $newdata] -1] } { $i >= [expr [llength $newdata] - $numreplies] } { incr i -1 } {
			set line [lindex $newdata $i]
			if { $line != "" } { putserv "NOTICE $nick :[string map [list "%time" [clock format [lindex $line 0] -format $news(dateformat)] "%user" [lindex $line 1] "%news" [join [lrange $line 2 end]]] $news(line)]" }
  	}
  	
  } else {
		for { set i [expr [llength $data] - 2] } { $i >= [expr [llength $data] - $numreplies - 1] } { incr i -1 } {
			set line [lindex $data $i]
			if { $line != "" } { putserv "NOTICE $nick :[string map [list "%time" [clock format [lindex $line 0] -format $news(dateformat)] "%user" [lindex $line 1] "%news" [join [lrange $line 2 end]]] $news(line)]" }
		}
	} 
}

proc rud:msg:addnews { nick uhost handle arg } {
	global news

	foreach addhost [split $news(addhosts)] {
		if { [string match -nocase $addhost $uhost] } {
			set adder 1;
		}
	}

	if { ![catch {onchan $nick $news(addchan)}] } {
		if { [onchan $nick $news(addchan)] } {
			set adder 1;
		}
	}

	if { [llength $arg] == 0 } {
		putserv "NOTICE $nick :Usage: !addnews <news>"
		return 0
	}

	if { [info exists adder] } {
		set fp [open $news(file) a]
		puts $fp "[clock seconds] $nick $arg"
		close $fp
	
		putserv "NOTICE $nick :News added!"
		foreach newschan [split $news(channels)] {
			putserv "PRIVMSG $newschan :[string map [list "%user" $nick "%news" $arg] $news(addstyle)]"
		}
	}
}

proc rud:pub:addnews { nick uhost handle chan arg } {
	rud:msg:addnews $nick $uhost $handle $arg
}

proc rud:msg:delnews { nick uhost handle arg } {
	global news

	foreach addhost [split $news(addhosts)] {
		if { [string match -nocase $addhost $uhost] } {
			set adder 1;
		}
	}

	if { ![catch { onchan $nick $news(addchan) }] } {
		if { [onchan $nick $news(addchan)] } {
			set adder 1;
		}
	}

	if { [llength $arg] != 1 || ![string is integer $arg] } {
		putserv "NOTICE $nick :Usage: !delnews <number>, 1 is the lastest news added, 2 seconds latest etc."
		return 0
	}

	if { [info exists adder] } {
		set fp [open $news(file) r]
		set data [split [read $fp] \n]
		close $fp
		
		set fp [open $news(file).new w]
		set line [expr [llength $data] - $arg - 1]
		for { set i 0 } { $i < [expr [llength $data]-1] } { incr i } {
			if { $i == $line } {
				set line [lrange [lindex $data $i] 2 end]
			} else {
				puts $fp [lindex $data $i]
			}
		}
		close $fp
		
		file rename -force $news(file).new $news(file)

		putserv "NOTICE $nick :Deleted: [join $line]"
	}
}

proc rud:pub:delnews { nick uhost handle chan arg } {
	rud:msg:delnews $nick $uhost $handle $arg
}

proc rud:timer:news { arg } {
	global news 
	
	set fp [open $news(file) r]
	set data [split [read $fp] "\n"]
	close $fp

	foreach chan [split $news(channels)] {
		putserv "PRIVMSG $chan :$news(header)"
	}

	for { set i [expr [llength $data] - 2] } { $i >= [expr [llength $data] - $arg - 1] } { incr i -1 } {
		if { [lindex $data $i] != "" } {
			set line [lindex $data $i]
			set output [string map [list "%time" [clock format [lindex $line 0] -format $news(dateformat)] "%user" [lindex $line 1] "%news" [lrange $line 2 end]] $news(line)]
			foreach chan [split $news(channels)] {
				 putserv "PRIVMSG $chan :$output" 
			}
		}
	}

	timer $news(timer) { rud:timer:news $news(showtimer) }
}

if { ![string match *rud:timer:news* [utimers]] && ![string match *rud:timer:news* [timers]] && $news(firstrun) > 0 && $news(timer) > 0 } {
	timer $news(firstrun) { rud:timer:news $news(showtimer) }
}

if { ![file isfile $news(file)] } {
	set fp [open $news(file) w]
	close $fp
}

putlog "rud-news.tcl $news(version) by rudenstam loaded..."
