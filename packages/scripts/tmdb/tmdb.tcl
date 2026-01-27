################################################################################
#                                                                              #
#                TMDB - Movie Info pzs-ng Plug-in                              #
#            Based on TVMaze.tcl by Meij, MrCode, Teqno, TeRRaNoVA, etc.       #
#                Adapted for TMDB by Teqno                                     #
#                                                                              #
# APIs https://developer.themoviedb.org/docs/getting-started                   #
#                                                                              #
################################################################################
#
# Description:
# - Announce movie information obtained from themoviedb.org on pre and new releases.
#
# Installation:
# 1. Copy this file (tmdb.tcl) and the plugin theme (tmdb.zpt) into your
#    pzs-ng sitebots 'plugins' folder.
#
# 2. Edit the configuration options below (especially the API key).
#
# 3. Add the following to your eggdrop.conf:
#    source pzs-ng/plugins/tmdb.tcl
#
# 4. Rehash or restart your eggdrop for the changes to take effect.
#
#################################################################################

namespace eval ::ngBot::plugin::TMDB {
	variable ns [namespace current]
	variable tmdb

	## Config Settings ###############################
	##
	## Choose one of two settings, the first when using ngBot, the second when using dZSbot
	variable np [namespace qualifiers [namespace parent]]
	#variable np ""
	##
	## TMDB API Key (REQUIRED)
	set tmdb(apikey) ""
	##
	## Proxy settings
	## If you set proxy host it will use proxy. Keep it "" for no proxy.
	## For the type, options are http/socks4/socks5 or others depending on the TclCurl version
	set tmdb(proxytype) "socks5"
	set tmdb(proxyhost) ""
	set tmdb(proxyport) 8080
	set tmdb(proxyuser) "username"
	set tmdb(proxypass) "password"
	##
	set tmdb(sections) {}
	##
	## Timeout in milliseconds. (default: 3000)
	set tmdb(timeout)  3000
	##
	## Announce when no data was found. (default: false)
	set tmdb(announce-empty) false
	##
	## Channel trigger. (Leave blank to disable)
	set tmdb(ctrigger) "!imdb"
	##
	## Private message trigger. (Leave blank to disable)
	set tmdb(ptrigger) ""
	##
	## Date format. (URL: http://tcl.tk/man/tcl8.4/TclCmd/clock.htm)
	set tmdb(date)     "%Y-%m-%d"
	##
	## Skip announce for these directories.
	set tmdb(ignore_dirs) {cd[0-9] dis[ck][0-9] dvd[0-9] codec cover covers extra extras sample subs vobsub vobsubs proof}
	##
	## Genre splitter.
	set tmdb(splitter) " / "
	## 
	## Creation of .imdb file with TMDB info that require tmdb.sh external script in /glftpd/bin
	set tmdb(imdbfile) true
	##
	## Pre line regexp.
	##  We need to reconstruct the full path to the release. Since not all
	##  pre scripts use the same format we'll use regexp to extract what we
	##  need from the pre logline and reconstuct it ourselves.
	##
	## Default f00-pre example:
	set tmdb(pre-regexp) {^"(.[^"]+)" ".[^"]*" ".[^"]*" "(.[^"]+)"}
	set tmdb(pre-path)   "%2/%1"
	##
	## Default eur0-pre example:
	#set tmdb(pre-regexp) {^"(.[^"]+)"}
	#set tmdb(pre-path)   "%1"
	##
	## Disable announces. (0 = No, 1 = Yes)
	## TMDB is used on NEWDIR, TMDB-PRE on PRE,
	## TMDB-MSGFULL is used with !movie-trigger with specific movie
	## and TMDB-MSGSHOW is used with !movie-trigger with only a moviename or invalid year
	set ${np}::disable(TMDB)                                  	0   
	set ${np}::disable(TMDB-PRE)                             	0   
	set ${np}::disable(TMDB-MSGFULL)                          	0   
	set ${np}::disable(TMDB-MSGSHOW)                          	0   
	##
	## Convert empty or zero variables into something else.
	set ${np}::zeroconvert(%tmdb_movie_title)                 	"N/A"
	set ${np}::zeroconvert(%tmdb_movie_id)                   	"N/A"
	set ${np}::zeroconvert(%tmdb_movie_genres)               	"N/A"
	set ${np}::zeroconvert(%tmdb_movie_country)              	"N/A"
	set ${np}::zeroconvert(%tmdb_movie_language)             	"N/A"
	set ${np}::zeroconvert(%tmdb_movie_status)               	"N/A"
	set ${np}::zeroconvert(%tmdb_movie_release_date)         	"N/A"
	set ${np}::zeroconvert(%tmdb_movie_year)                 	"N/A"
	set ${np}::zeroconvert(%tmdb_movie_runtime)              	"N/A"
	set ${np}::zeroconvert(%tmdb_movie_rating)               	"N/A"
	set ${np}::zeroconvert(%tmdb_movie_vote_count)           	"N/A"
	set ${np}::zeroconvert(%tmdb_movie_popularity)           	"N/A"
	set ${np}::zeroconvert(%tmdb_movie_tagline)              	"N/A"
	set ${np}::zeroconvert(%tmdb_movie_overview)             	"N/A"
	set ${np}::zeroconvert(%tmdb_movie_imdb_id)              	"N/A"
	set ${np}::zeroconvert(%tmdb_movie_tmdb_url)              	"N/A"
	set ${np}::zeroconvert(%tmdb_movie_cast)              		"N/A"
	##
	##################################################

	## Version
	set tmdb(version) "20260127"
	## Useragent
	set tmdb(useragent) "Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US; rv:1.9.0.5) Gecko/2008120122 Firefox/3.0.5"

	variable events [list "NEWDIR" "PRE"]

	variable scriptFile [info script]
	variable scriptName ${ns}::LogEvent

	if {[string equal "" $np]} {
		bind evnt -|- prerehash ${ns}::deinit
	}

	proc init {} {
		variable ns
		variable np
		variable ${np}::postcommand
		variable ${np}::variables

		variable events
		variable tmdb
		variable scriptName
		variable scriptFile

		if {[catch {package require json 1.2}]} {
			${ns}::Error "\"json\" package not found, unloading script."
			return -code -1
		}
		if {[string length $tmdb(proxyhost)]} {
			if {[catch {package require TclCurl}]} {
				${ns}::Error "\"TclCurl\" package not found, unloading script."
				return -code -1
			}
		} else {
			if {[catch {package require http 2}]} {
				${ns}::Error "\"http\" package not found, unloading script."
				return -code -1
			}
			# We want at least protocol TLS 1.X
			if {[catch {package require tls 1.7}]} {
				${ns}::Error "\"tls\" package not found, unloading script."
				return -code -1
			}
		}

		set variables(TMDB-MSGFULL) "%tmdb_movie_title %tmdb_movie_id %tmdb_movie_genres %tmdb_movie_country %tmdb_movie_language %tmdb_movie_status %tmdb_movie_release_date %tmdb_movie_year %tmdb_movie_runtime %tmdb_movie_rating %tmdb_movie_vote_count %tmdb_movie_popularity %tmdb_movie_tagline %tmdb_movie_overview %tmdb_movie_imdb_id %tmdb_movie_tmdb_url %tmdb_movie_cast"
		set variables(TMDB) "$variables(NEWDIR) $variables(TMDB-MSGFULL)"
		set variables(TMDB-PRE) "$variables(PRE) $variables(TMDB-MSGFULL)"
		set variables(TMDB-MSGSHOW) $variables(TMDB-MSGFULL)

		set theme_file [file normalize "[pwd]/[file rootname $scriptFile].zpt"]
		if {[file isfile $theme_file]} {
			${np}::loadtheme $theme_file true
		}

		## Register the event handler.
		foreach event $events {
			lappend postcommand($event) $scriptName
		}

		if {([info exists tmdb(ctrigger)]) && (![string equal $tmdb(ctrigger) ""])} {
			bind pub -|- $tmdb(ctrigger) ${ns}::Trigger
		}
		if {([info exists tmdb(ptrigger)]) && (![string equal $tmdb(ptrigger) ""])} {
			bind msg -|- $tmdb(ptrigger) ${ns}::Trigger
		}

		${ns}::Debug "Loaded successfully (Version: $tmdb(version))."
	}

	proc deinit {args} {
		variable ns
		variable np
		variable ${np}::postcommand

		variable events
		variable scriptName

		## Remove the script event from postcommand.
		foreach event $events {
			if {[info exists postcommand($event)] && [set pos [lsearch -exact $postcommand($event) $scriptName]] !=  -1} {
				set postcommand($event) [lreplace $postcommand($event) $pos $pos]
			}
		}
		namespace delete $ns
	}

	proc Debug {msg} {
		putlog "\[ngBot\] TMDB :: $msg"
	}

	proc Error {error} {
		putlog "\[ngBot\] TMDB Error :: $error"
	}

	proc ConvertDate {string} {
		variable tmdb
		if {![string equal "$string" ""] && [catch {clock format [clock scan $string] -format $tmdb(date)} result] == 0} {
			set string $result
		}
		return $string
	}

	proc Trigger {args} {
	    variable ns
	    variable np
	    variable tmdb

	    if {[llength $args] == 5} {
		${np}::checkchan [lindex $args 2] [lindex $args 3]
		set trigger $tmdb(ctrigger)
	    } else {
		set trigger $tmdb(ptrigger)
	    }

	    set text [lindex $args [expr { [llength $args] - 1 }]]
	    set target [lindex $args [expr { [llength $args] - 2 }]]

	    if {[string equal $text ""]} {
		${np}::sndone $target "TMDB Syntax :: $trigger <movie title> [year] (eg: $trigger The Matrix 1999) or $trigger \"Class of 1999\" 1990"
		return 1
	    }

	    # Format user input to look like a release name
	    # Replace spaces with dots (like release names)
	    set search_str [string map {" " "."} [string trim $text]]
	    
	    # Debug
	    putlog "\[TMDB\] DEBUG: Trigger search string: '$search_str'"
	    
	    # Call FindInfo - it will parse the string like a release name
	    if {[catch {${ns}::FindInfo $search_str [list] "false"} logData] != 0} {
		${np}::sndone $target "TMDB Error :: $logData"
		return 0
	    }

	    ${np}::sndone $target [${np}::ng_format "TMDB-MSGFULL" "none" $logData]
	    return 1
	}

	proc LogEvent {event section logData} {
		variable ns
		variable np
		variable tmdb
		
		if {[string compare -nocase $event "NEWDIR"] == 0} {
			set target "TMDB"
			set release [lindex $logData 0]
		} else {
			set target "TMDB-PRE"
			if {(![info exists tmdb(pre-regexp)]) || (![info exists tmdb(pre-path)])} {
				${ns}::Error "Your pre-regexp or pre-path variables are not set"
				return 0
			}
			if {[catch {regexp -inline -nocase -- $tmdb(pre-regexp) $logData} error] != 0} {
				${ns}::Error $error
				return 0
			}
			if {[set cookies [regexp -inline -all -- {%([0-9]+)} $tmdb(pre-path)]] == ""} {
				${ns}::Error "Your pre-path contains no valid cookies"
				return 0
			}
			set release $tmdb(pre-path)
			foreach {cookie number} $cookies {
				regsub -- $cookie $release [lindex $error $number] release
			}
		}

		## Check the release directory is ignored.
		foreach ignore [split $tmdb(ignore_dirs) " "] {
			if {[string match -nocase $ignore [file tail $release]]} {
				return 1
			}
		}

		foreach path $tmdb(sections) {
			if {[string match -nocase "$path*" $release]} {
				set logLen [llength $logData]
				if {[catch {${ns}::FindInfo [file tail $release] $logData} logData] != 0} {
					${ns}::Error "$logData. ($release)"
					return 0
				}
				set empty 1
				foreach piece [lrange $logData $logLen end] {
					if {![string equal $piece ""]} {
						set empty 0
						break
					}
				}
				if {($empty == 0) || ([string is true -strict $tmdb(announce-empty)])} {
					set listlength [llength $logData]
					if {$listlength > 20} {
						append rls_name [string map {" " _} [lindex $logData 0]]
						append user [string map {" " _} [lindex $logData 1]]
						append group [string map {" " _} [lindex $logData 2]]
						append other_tagline [string map {" " _} [lindex $logData 3]]
						append movie_title [string map {" " _} [lindex $logData 4]]
						append movie_id [string map {" " _} [lindex $logData 5]]
						append movie_genres [string map {" " _} [lindex $logData 6]]
						append movie_country [string map {" " _} [lindex $logData 7]]
						append movie_language [string map {" " _} [lindex $logData 8]]
						append movie_status [string map {" " _} [lindex $logData 9]]
						append movie_release_date [string map {" " _} [lindex $logData 10]]
						append movie_year [string map {" " _} [lindex $logData 11]]
						append movie_runtime [string map {" " _} [lindex $logData 12]]
						append movie_rating [string map {" " _} [lindex $logData 13]]
						append movie_vote_count [string map {" " _} [lindex $logData 14]]
						append movie_popularity [string map {" " _} [lindex $logData 15]]
						append movie_tagline [string map {" " _} [lindex $logData 16]]
						append movie_overview [string map {" " _} [lindex $logData 17]]
						append movie_imdb_id [string map {" " _} [lindex $logData 18]]
						append movie_tmdb_url [string map {" " _} [lindex $logData 19]]
						append movie_cast [string map {" " _} [lindex $logData 20]]

						if {[string equal $tmdb(imdbfile) "true"]} {
							if {[file exists /glftpd/bin/tmdb.sh]} {
								exec /glftpd/bin/tmdb.sh $rls_name $movie_title $movie_genres $movie_country $movie_language $movie_status $movie_release_date $movie_rating $movie_imdb_id $movie_tmdb_url $movie_tagline $movie_overview $movie_runtime $movie_cast
							}
						}
						if {[file exists /glftpd/bin/tmdb-nuker.sh]} {
							exec /glftpd/bin/tmdb-nuker.sh $rls_name $movie_genres $movie_country $movie_language $movie_status $movie_release_date $movie_rating
						}
					}
					${np}::sndall $target $section [${np}::ng_format $target $section $logData]
				}
				break
			}
		}
		return 1
	}
	
	proc FindInfo {string logData {strict true} {year ""}} {
	    variable tmdb
	    set output_order [list movie_title movie_id movie_genres movie_country movie_language movie_status movie_release_date movie_year movie_runtime movie_rating movie_vote_count movie_popularity movie_tagline movie_overview movie_imdb_id movie_tmdb_url movie_cast]
	    
	    # If year is provided, use it
	    if {$year ne ""} {
		set movie_str $string
		set movie_year $year
	    } else {
		# Clean up the release name to extract movie title and year
		set movie_str $string
		set movie_year ""

		# Remove group name (everything after last dash)
		regsub -- {-[^-]+$} $movie_str "" movie_str

		# The pattern is: TitleParts.ReleaseYear.ResolutionAndFormat
		# We want everything before .ReleaseYear.
		if {[regexp -- {^(.*)\.((19|20)[0-9]{2})\..+$} $movie_str match title_parts movie_year]} {
		    # Found release year with stuff after it
		    set movie_str $title_parts
		} elseif {[regexp -- {^(.*)\.((19|20)[0-9]{2})$} $movie_str match title_parts movie_year]} {
		    # Release year at the end (no resolution/format after it)
		    set movie_str $title_parts
		}

		# Convert remaining dots to spaces (handles titles like "Class.Of.1999")
		set movie_str [string map {"." " "} $movie_str]
		set movie_str [string trim $movie_str]

		# Clean up any extra spaces
		regsub -all -- {\s+} $movie_str " " movie_str
		set movie_str [string trim $movie_str]
	    }
	    
	    array set info [::ngBot::plugin::TMDB::GetMovieInfo $movie_str $movie_year]

	    foreach key $output_order {
		if {(![info exists info($key)]) || \
		    ([string equal -nocase $info($key) "&nbsp;"])} {
		    set info($key) ""
		}
		lappend logData $info($key)
	    }
	    return $logData
	}
		
	proc GetMovieInfo {title year} {
		variable tmdb
		if {[string equal $tmdb(apikey) "YOUR_TMDB_API_KEY_HERE"]} {
			return -code error "TMDB API key not set in configuration"
		}
		
		# Clean title further for API search
		set clean_title [regsub -all {[^a-zA-Z0-9\s]} $title ""]
		set clean_title [string trim $clean_title]
		
		# URL encode the query
		set query [string map {" " "%20"} $clean_title]
		set url "https://api.themoviedb.org/3/search/movie?api_key=$tmdb(apikey)&query=$query&include_adult=false"
		if {$year != "" && [string is integer $year] && $year >= 1900 && $year <= 2100} {
			append url "&year=$year"
		}
		
		::ngBot::plugin::TMDB::Debug "Searching TMDB for: '$clean_title' Year: '$year'"
		
		set data [::ngBot::plugin::TMDB::GetFromApi $url ""]
		if {[string equal "Connection" [string range $data 0 9]]} {
			return -code error $data
		}
		
		# Parse JSON response
		if {[catch {set parsed_data [::json::json2dict $data]} error]} {
			::ngBot::plugin::TMDB::Debug "JSON parse error: $error"
			::ngBot::plugin::TMDB::Debug "Raw response: $data"
			return -code error "Failed to parse TMDB response"
		}
		
		# Check if we have results
		if {![dict exists $parsed_data results] || [llength [dict get $parsed_data results]] == 0} {
			# Try without year if first search fails
			if {$year != ""} {
				set url "https://api.themoviedb.org/3/search/movie?api_key=$tmdb(apikey)&query=$query&include_adult=false"
				set data [::ngBot::plugin::TMDB::GetFromApi $url ""]
				if {[string equal "Connection" [string range $data 0 9]]} {
					return -code error $data
				}
				
				if {[catch {set parsed_data [::json::json2dict $data]} error]} {
					return -code error "Failed to parse TMDB response"
				}
			}
			
			if {![dict exists $parsed_data results] || [llength [dict get $parsed_data results]] == 0} {
				return -code error "No results found for \"$title\""
			}
		}
		
		# Take first result (most relevant)
		set movie [lindex [dict get $parsed_data results] 0]
		set movie_id [dict get $movie id]
		
		::ngBot::plugin::TMDB::Debug "Found movie ID: $movie_id - [dict get $movie title] ([dict get $movie release_date])"
		
		# Get full movie details
		set url "https://api.themoviedb.org/3/movie/$movie_id?api_key=$tmdb(apikey)&append_to_response=credits"
		set data [::ngBot::plugin::TMDB::GetFromApi $url ""]
		if {[string equal "Connection" [string range $data 0 9]]} {
			return -code error $data
		}
		
		if {[catch {set movie [::json::json2dict $data]} error]} {
			return -code error "Failed to parse TMDB movie details"
		}

		array set info {}
		
		# Basic info with safety checks
		if {[dict exists $movie title]} {
			set info(movie_title) [dict get $movie title]
		} else {
			set info(movie_title) "Unknown"
		}
		
		set info(movie_id) $movie_id
		
		# Date and year
		if {[dict exists $movie release_date] && [dict get $movie release_date] != ""} {
			set release_date [dict get $movie release_date]
			set info(movie_release_date) $release_date
			set info(movie_year) [string range $release_date 0 3]
		} elseif {$year != ""} {
			set info(movie_year) $year
			set info(movie_release_date) "$year-01-01"
		} else {
			set info(movie_year) "N/A"
			set info(movie_release_date) "N/A"
		}
		
		# Other details with defaults
		set info(movie_status) [expr {[dict exists $movie status] ? [dict get $movie status] : "Released"}]
		if {[dict exists $movie runtime] && [set runtime_min [dict get $movie runtime]] > 0} {
		    set hours [expr {$runtime_min / 60}]
		    set minutes [expr {$runtime_min % 60}]
		    if {$hours > 0} {
			if {$minutes > 0} {
			    set info(movie_runtime) "${hours}h ${minutes}m"
			} else {
			    set info(movie_runtime) "${hours}h"
			}
		    } else {
			set info(movie_runtime) "${minutes}m"
		    }
		} else {
		    set info(movie_runtime) "N/A"
		}
		
		if {[dict exists $movie vote_average]} {
			set vote_avg [dict get $movie vote_average]
			set info(movie_rating) [expr {$vote_avg > 0 ? [format "%.1f" $vote_avg] : "N/A"}]
		} else {
			set info(movie_rating) "N/A"
		}
		
		set info(movie_vote_count) [expr {[dict exists $movie vote_count] ? [dict get $movie vote_count] : "N/A"}]
		set info(movie_popularity) [expr {[dict exists $movie popularity] ? [format "%.0f" [dict get $movie popularity]] : "N/A"}]
		set info(movie_tagline) [expr {[dict exists $movie tagline] ? [dict get $movie tagline] : "N/A"}]
		set info(movie_overview) [expr {[dict exists $movie overview] ? [dict get $movie overview] : "N/A"}]
		
		# IMDb ID
		if {[dict exists $movie imdb_id] && [set imdb_id [dict get $movie imdb_id]] != ""} {
			set info(movie_imdb_id) "https://www.imdb.com/title/$imdb_id/"
		} else {
			set info(movie_imdb_id) "N/A"
		}
		
        # TMDB URL
        set info(movie_tmdb_url) "https://www.themoviedb.org/movie/$movie_id"
		
		# Genres
		set genres [list]
		if {[dict exists $movie genres]} {
			foreach genre [dict get $movie genres] {
				if {[dict exists $genre name]} {
					lappend genres [dict get $genre name]
				}
			}
		}
		if {[llength $genres] > 0} {
			set info(movie_genres) [join $genres $tmdb(splitter)]
		} else {
			set info(movie_genres) "N/A"
		}
		
        # Origin Country - use origin_country field and convert to full name
        set info(movie_country) "N/A"
        if {[dict exists $movie origin_country]} {
            set origin_countries [dict get $movie origin_country]
            if {[llength $origin_countries] > 0} {
                # Get first origin country code
                set country_code [lindex $origin_countries 0]
                
                # Try to find full country name from production_countries
                set country_name $country_code  ;# Default to code if name not found
                
                if {[dict exists $movie production_countries]} {
                    foreach prod_country [dict get $movie production_countries] {
                        if {[dict exists $prod_country iso_3166_1] && 
                            [dict get $prod_country iso_3166_1] == $country_code} {
                            if {[dict exists $prod_country name]} {
                                set country_name [dict get $prod_country name]
                            }
                            break
                        }
                    }
                }
                
                set info(movie_country) $country_name
            }
        } elseif {[dict exists $movie production_countries]} {
            # Fallback to first production country if origin_country doesn't exist
            set countries [dict get $movie production_countries]
            if {[llength $countries] > 0} {
                set first_country [lindex $countries 0]
                if {[dict exists $first_country name]} {
                    set info(movie_country) [dict get $first_country name]
                } elseif {[dict exists $first_country iso_3166_1]} {
                    set info(movie_country) [dict get $first_country iso_3166_1]
                }
            }
        }
        		
		# Spoken languages
		if {[dict exists $movie spoken_languages]} {
			set spoken_langs [dict get $movie spoken_languages]
			
			# Check for invalid values first
			if {$spoken_langs eq "null" || $spoken_langs eq "No Language" || [llength $spoken_langs] == 0} {
				set info(movie_language) "N/A"
			} else {
				set language_list {}
				foreach lang_dict $spoken_langs {
					if {[dict exists $lang_dict english_name]} {
						lappend language_list [dict get $lang_dict english_name]
					}
				}
				
				if {[llength $language_list] > 0} {
					set info(movie_language) [join $language_list ", "]
				} else {
					set info(movie_language) "N/A"
				}
			}
		} else {
			set info(movie_language) "N/A"
		}
        		
		# Get top 5 cast members
		set cast_members [list]
		if {[dict exists $movie credits cast]} {
		    set cast_count 0
		    foreach cast_member [dict get $movie credits cast] {
			if {$cast_count >= 5} {
			    break
			}
			if {[dict exists $cast_member name]} {
			    lappend cast_members [dict get $cast_member name]
			    incr cast_count
			}
		    }
		}

		if {[llength $cast_members] > 0} {
		    set info(movie_cast) [join $cast_members ", "]
		} else {
		    set info(movie_cast) "N/A"
		}		

		return [array get info]
	}

	proc GetFromApi {uri query} {
		variable tmdb

		# init data
		set data ""

		if {[string length $tmdb(proxyhost)]} {
			if {![string equal "" "$query"]} {
				# Verify if we can use quoteString or the older mapReply
				# else fallback to the original formatQuery
				# Use "commands" as quoteString is an alias (of mapReply)
				if {[string length [info commands ::http::quoteString]]} {
					set uri "$uri[::http::quoteString $query]"
				} elseif {[string length [info procs ::http::mapReply]]} {
					set uri "$uri[::http::mapReply $query]"
				} else {
					set uri "$uri[::http::formatQuery $query]"
				}
			}
			
			# For TMDB API, we need to handle the JSON response properly
			curl::transfer -url "$uri" \
				-proxy $tmdb(proxyhost):$tmdb(proxyport) \
				-proxytype $tmdb(proxytype) \
				-proxyuserpwd $tmdb(proxyuser):$tmdb(proxypass) \
				-useragent $tmdb(useragent) \
				-bodyvar token \
				-timeoutms $tmdb(timeout) \
				-followlocation 1 \
				-maxredirs 5 \
				-httpheader [list "Accept: application/json"]
			
			set data $token
		} else {
			if {![string equal "" "$query"]} {
				# Verify if we can use quoteString or the older mapReply
				# else fallback to the original formatQuery
				# Use "commands" as quoteString is an alias (of mapReply)
				if {[string length [info commands ::http::quoteString]]} {
					set uri "$uri[::http::quoteString $query]"
				} elseif {[string length [info procs ::http::mapReply]]} {
					set uri "$uri[::http::mapReply $query]"
				} else {
					set uri "$uri[::http::formatQuery $query]"
				}
			}
			
			::http::config -useragent $tmdb(useragent)
			::http::register https 443 [list ::tls::socket -autoservername true]
			
			# For TMDB API with proper headers
			set token [::http::geturl "$uri" \
				-timeout $tmdb(timeout) \
				-headers [list \
					"Accept" "application/json" \
					"Content-Type" "application/json;charset=utf-8" \
				] \
			]

			if {![string equal -nocase [::http::status $token] "ok"]} {
				return "Connection [::http::status $token]"
			}

			## Check HTTP status code
			set httpCode [::http::ncode $token]
			if {$httpCode != 200} {
				::http::cleanup $token
				return "Connection HTTP $httpCode"
			}

			set data [::http::data $token]
			::http::cleanup $token
		}

		return $data
	}
}

if {[string equal "" $::ngBot::plugin::TMDB::np]} {
	::ngBot::plugin::TMDB::init
}
