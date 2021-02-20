#!/usr/bin/tclsh

set input {
my.filename-group.mkv
geckos-btbr2010-1080.r10
geckos-btbr2010-1080.rar
indiana.jones.and.the.kingdom.of.the.crystal.skull.2008.1080p.bluray.x264-sinners.part01.rar
indiana.jones.and.the.kingdom.of.the.crystal.skull.2008.1080p.bluray.x264-sinners.part02.rar
indiana.jones.and.the.kingdom.of.the.crystal.skull.2008.1080p.bluray.x264-sinners.part1.rar
indiana.jones.and.the.kingdom.of.the.crystal.skull.2008.1080p.bluray.x264-sinners.part001.rar
indiana.jones.and.the.kingdom.of.the.crystal.skull.2008.1080p.bluray.x264-sinners.part0001.rar
indiana.jones.and.the.kingdom.of.the.crystal.skull.2008.1080p.bluray.x264-sinners.part00001.rar
indiana.testfile.sfv
}

set expectedZip {/bin/zipscript-c my.filename-group.mkv MyDirName0 0
/bin/zipscript-c geckos-btbr2010-1080.r10 MyDirName1 123456789
/bin/zipscript-c geckos-btbr2010-1080.rar MyDirName2 246913578
/bin/zipscript-c indiana.jones.and.the.kingdom.of.the.crystal.skull.2008.1080p.bluray.x264-sinners.part01.rar MyDirName3 370370367
/bin/zipscript-c indiana.jones.and.the.kingdom.of.the.crystal.skull.2008.1080p.bluray.x264-sinners.part02.rar MyDirName4 493827156
/bin/zipscript-c indiana.jones.and.the.kingdom.of.the.crystal.skull.2008.1080p.bluray.x264-sinners.part1.rar MyDirName5 617283945
/bin/zipscript-c indiana.jones.and.the.kingdom.of.the.crystal.skull.2008.1080p.bluray.x264-sinners.part001.rar MyDirName6 740740734
/bin/zipscript-c indiana.jones.and.the.kingdom.of.the.crystal.skull.2008.1080p.bluray.x264-sinners.part0001.rar MyDirName7 864197523
/bin/zipscript-c indiana.jones.and.the.kingdom.of.the.crystal.skull.2008.1080p.bluray.x264-sinners.part00001.rar MyDirName8 987654312
/bin/zipscript-c indiana.testfile.sfv MyDirName9 1111111101}

set expectedGL {MKV_DONE: MyDirName0 my.filename-group.mkv ???
FIRST_RAR: MyDirName2 geckos-btbr2010-1080.rar
FIRST_RAR: MyDirName3 indiana.jones.and.the.kingdom.of.the.crystal.skull.2008.1080p.bluray.x264-sinners.part01.rar
FIRST_RAR: MyDirName5 indiana.jones.and.the.kingdom.of.the.crystal.skull.2008.1080p.bluray.x264-sinners.part1.rar
FIRST_RAR: MyDirName6 indiana.jones.and.the.kingdom.of.the.crystal.skull.2008.1080p.bluray.x264-sinners.part001.rar
FIRST_RAR: MyDirName7 indiana.jones.and.the.kingdom.of.the.crystal.skull.2008.1080p.bluray.x264-sinners.part0001.rar
FIRST_RAR: MyDirName8 indiana.jones.and.the.kingdom.of.the.crystal.skull.2008.1080p.bluray.x264-sinners.part00001.rar}


set zipscriptLog "rud-filedone-zipscript.log"
set glftpdLog    "rud-filedone-glftpd.log"

if {[file exists $zipscriptLog]} {
	file delete -force $zipscriptLog
}

if {[file exists $glftpdLog]} {
	file delete -force $glftpdLog
}

set i 0
foreach filename [split $input \n] {
	if {[string trim $filename] != ""} {
		exec [lindex $argv 0] $filename MyDirName$i [expr 123456789*$i] test
		incr i
	}
}
set timeStr [clock format [clock seconds] -format "%a %b %e %T %Y"]

set errorCount 0

set fp [open $zipscriptLog r]
set data [split [read $fp] \n]
set expectedZip [split $expectedZip \n]
close $fp
for {set i 0} {$i < [llength $expectedZip]} {incr i} {
	if {[lindex $expectedZip $i] != [lindex $data $i]} {
		puts "ERROR ziplog:"
		puts "    Expected: '[lindex $expectedZip $i]'"
		puts "    Got:      '[lindex $data $i]'"
		incr errorCount
	}
}

set fp [open $glftpdLog r]
set data [split [read $fp] \n]
set expectedGL [split $expectedGL \n]
close $fp
for {set i 0} {$i < [llength $expectedGL]} {incr i} {
        if {"$timeStr [lindex $expectedGL $i]" != [lindex $data $i]} {
                puts "ERROR gllog:"
                puts "    Expected: '$timeStr [lindex $expectedGL $i]'"
                puts "    Got:      '[lindex $data $i]'"
		incr errorCount
        }
}

if {$errorCount > 0} {
	puts "-------------------------"
	puts "Found $errorCount errors."
} else {
	puts "No error encountered."
}

if {[file exists $zipscriptLog]} {
	file delete -force $zipscriptLog
}

if {[file exists $glftpdLog]} {
	file delete -force $glftpdLog
}

