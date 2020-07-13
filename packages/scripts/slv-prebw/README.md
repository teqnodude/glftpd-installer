# slv-prebw

## pzs-ng dZBot/ngbot plugin to show bandwidth after pre

So what's so special about ANOTHER PreBW script? Well, this one works
seperate from pre script so you can prolly use it with every pre script
thats out there. Also it's an pzs-ng plugin... or kinda ;)

An other feature is that it doesnt announce anything if there's no output bw
made (can be disabled tho). This is my first public script so if anything
fucks up dont blame me. Also I dont like (obvious) questions about this,
if it doesnt work for you - too bad, it does for me! :p

### You'll need

- linux or freebsd
- a recent version of bash
- pzs-ng (sitewho, sitebot)
- site pre script that logs PRE to glftpd.log (tested with foo-pre)

### Changes

#### Update v1.1 20190712

- small fix if total traffic is 0

#### Update v1.0 20190609

- added options to turn on/off 'always announce' and 'show bwavg'
- added option to show total traffic by number of users/groups
- added setting for speed and size units (MBPS, MBIT and MB, GB)
- moved all theming to sitebot (see Customization below)

* * *

### Installation

1. copy slv-prebw.sh to glftpd/bin dir
2. copy PreBW.tcl to eggdrop/pzs-ng/plugins/PreBW.tcl
3. configure slv-prebw.sh to your liking (paths, announce options etc)

   - "CAPS" controls how many times it captures output bw and intervals in seconds
   - so if its set to `"1 1 1"` you'll sample bw 3 times with 1 second in between and announce after 3 seconds
   - setting it to "30 15 15 15 15" will announce:

         30s: 1@5.3MB/s 45s: 5@11.7MB/s 60s: 3@10.3MB/s 75s: 1@102kb/s 90s: 0@00kb/s

   - other examples:
      - mp3 `"2 3 5 5 5"`
      - iso `"10 10 10 20"`

4. configure PreBW.tcl

   - for **ngBot**: keep this line `variable np [namespace qualifiers [namespace parent]]`
   - *-or-* for **dZSbot**: comment line above and uncomment `#variable np ""`
   - if you put the .sh somewhere else remember to change it's path: `set bashScript "$glroot/bin/slv-prebw.sh"`

5. configure ngBot.conf / dZSbot.conf

   - you need to add "PREBW" to `msgtypes(SECTION)`, copy default from "ngBot.conf.dist" first if needed
   - **-and-** also add these:

   ```tcl
   set redirect(PREBW)  $mainchan
   set disable(PREBW)   0
   set chanlist(PREBW)  $mainchan
   set variables(PREBW) "%pf %t1 %u1 %b1 %t2 %u2 %b2 %t3 %u3 %b3 %t4 %u4 %b4 %t5 %u5 %b5 %bwavg %traffic %numusers %numgroups"
   ```

6. add to sitebot theme:

   ```tcl
    announce.PREBW = "[%b{prebw }][%section] %b{%reldir} :: %t1s: %b{%u1}@%b{%b1}MB/s %t2s: %b{%u2}@%b{%b2}MB/s %t3s: %b{%u3}@%b{%b3}MB/s %t4s: %b{%u4}@%b{%b4}MB/s %t5s: %b{%u5}@%b{%b5}MB/s :: avg: %b{%bwavg}MB/s :: %b{%traffic}MB by %b{%numusers}u/%b{%numgroups}g"
   ```

7. add to eggdrop.conf: `source scripts/pzs-ng/plugins/PreBW.tcl`
8. rehash your eggdrop, done.

* * *

### Customization

#### PreBw.tcl:

If you use a different PRE event/announce you can add it to `variable events [list "PRE"]`

Example: `[list "PRE" "PREMP3" "ISOPRE"]`

- this is only needed in case your "site pre" script (also) logs something else than PRE: to glftpd.conf
- same goes if you use 'msgreplace' to have a difference announce for mp3 using for example "PREMP3"

#### slv-prebw.sh and sitebot

If you change certain settings in slv-prebw.sh you have modify `set variables(PREBW)` in ngBot.conf accordingly:

- if you remove for example 2 numbers from "CAPS", also remove `"%t4 %u4 %b4 %t5 %u5 %b5"`
- if you disable "SHOW_BWAVG" remove `"%bwavg"`
- if you disable "SHOW_TRAF" remove `"%traffic %numusers %numgroup"`

The same changes are needed for `announce.PREBW` in your ngBot theme:

- if you modify "SPEED_UNIT" and/or "SIZE_UNIT" settings change "MB/s" and/or "MB"
- heres an example if you have 3 "CAPS" and disabled all other announce options:

```tcl
   announce.PREBW = "[%b{prebw}][%section] %b{%reldir} :: %t1 %b{%u1}@%b{%b1}MB/s %t2 %b{%u2}@%b{%b2}MB/s %t3 %b{%u3}@%b{%b3}MB/s"
```

* * *

##### PreBW.tcl couldnt have been done without neoxed's example, thnx

###### oh and <3 cpt ;)
