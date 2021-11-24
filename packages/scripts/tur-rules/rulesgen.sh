#!/bin/bash
function GENERAL
{
cat << EOF > site.rules
GENERAL :
01.0 Site does *NOT* exist! Talk about this site/channel..........................................................[DELUSER]
01.1 All Releases Max 2 hours from PRE ...........................................................................[NUKE 5X]
01.2 All uploads to be completed within 12 Hours .................................................................[NUKE 5X]
01.3 Siteops have the power, don't be a fool .....................................................................[INFO]
01.4 Affil PRE'S are exempt from ALL rules .......................................................................[INFO]
01.5 Accounts inactive for longer than 3 months are deleted ......................................................[INFO]
01.6 Accounts inactive for longer than 6 months are purged........................................................[INFO]

EOF
sed -i 's/sections="/sections="\nGENERAL:^01./' packages/scripts/tur-rules/tur-rules.sh
}

function 0DAY
{
cat << EOF >> site.rules
0DAY :
02.1 Main language: English/Nordic................................................................................[NUKE 5X]
02.2 NO Trial, Freeware, Alpha, Beta, or Demo Software............................................................[NUKE 5X]
02.3 NO MULTi/iNTERNALs...........................................................................................[NUKE 5X]
02.4 Windows/Linux/Android Platform only!.........................................................................[NUKE 5X]

EOF
sed -i 's/sections="/sections="\n0DAY:^02./' packages/scripts/tur-rules/tur-rules.sh
}

function ANIME
{
cat << EOF >> site.rules
ANIME :
03.1 Spoken language: English and Japanese with eng subs..........................................................[NUKE 5X]
03.2 Encoded in: 720p & 1080p only!...............................................................................[NUKE 5X]
03.3 DUBBED not allowed...........................................................................................[NUKE 5X]

EOF
sed -i 's/sections="/sections="\nANIME:^03/' packages/scripts/tur-rules/tur-rules.sh
}

function APPS
{
cat << EOF >> site.rules
APPS :
04.1 Main language: English/Nordic................................................................................[NUKE 5X]
04.2 NO Trial, Freeware, Alpha, Beta, or Demo Software............................................................[NUKE 5X]
04.3 NO MULTi/iNTERNALs...........................................................................................[NUKE 5X]
04.4 Windows Platform only!.......................................................................................[NUKE 5X]
04.5 No Ebooks, tutorials, bookware, training, elearning and similar things.......................................[NUKE 5X]

EOF
sed -i 's/sections="/sections="\nAPPS:^04./' packages/scripts/tur-rules/tur-rules.sh
}

function EBOOKS
{
cat << EOF >> site.rules
EBOOKS :
05.1 Language: English............................................................................................[NUKE 5X]

EOF
sed -i 's/sections="/sections="\nEBOOKS:^05./' packages/scripts/tur-rules/tur-rules.sh
}

function FLAC
{
cat << EOF >> site.rules
FLAC :
06.1 All Genres and ALL Years.....................................................................................[INFO]
06.2 All Sources..................................................................................................[ALLOWED]
06.3 No HOMEMADE Stuff............................................................................................[NUKE 5X]
06.4 No limitation................................................................................................[INFO]

EOF
sed -i 's/sections="/sections="\nFLAC:^06./' packages/scripts/tur-rules/tur-rules.sh
}

function GAMES
{
cat << EOF >> site.rules
GAMES :
07.1 Main language: English/Nordic................................................................................[NUKE 5X]
07.2 NO Trial, Freeware, Alpha, Beta, or Demo Software............................................................[NUKE 5X]
07.3 NO MULTi/iNTERNALs...........................................................................................[NUKE 5X]
07.4 Windows Platform only!.......................................................................................[NUKE 5X]

EOF
sed -i 's/sections="/sections="\nGAMES:^07./' packages/scripts/tur-rules/tur-rules.sh
}

function MBLURAY
{
cat << EOF >> site.rules
MBLURAY :
08.1 Spoken language: English/Nordic..............................................................................[NUKE 5X]
08.2 Encoded in: 1080p and 2160p only!............................................................................[NUKE 5X]
08.3 Releases tagged in: MULTi/DUAL not allowed...................................................................[NUKE 5X]
08.4 iNTERNALs....................................................................................................[ALLOWED]
08.5 All sources..................................................................................................[ALLOWED]

EOF
sed -i 's/sections="/sections="\nMBLURAY:^08./' packages/scripts/tur-rules/tur-rules.sh
}

function MP3
{
cat << EOF >> site.rules
MP3 :
09.1 All Genres and ALL Years.....................................................................................[INFO]
09.2 All Sources..................................................................................................[ALLOWED]
09.3 No HOMEMADE Stuff............................................................................................[NUKE 5X]
09.4 No limitation................................................................................................[INFO]

EOF
sed -i 's/sections="/sections="\nMP3:^09./' packages/scripts/tur-rules/tur-rules.sh
}

function NSW
{
cat << EOF >> site.rules
NSW :
10.1 Main language: English.......................................................................................[NUKE 5X]
10.2 NO Trial, Freeware, Alpha, Beta, or Demo Software............................................................[NUKE 5X]
10.3 MULTi allowed: Only if English is Present!...................................................................[NUKE 5X]
10.4 Only cracked releases........................................................................................[NUKE 5X]

EOF
sed -i 's/sections="/sections="\nNSW:^10./' packages/scripts/tur-rules/tur-rules.sh
}

function PS4
{
cat << EOF >> site.rules
PS4 :
11.1 Main language: English/Nordic................................................................................[NUKE 5X]
11.2 NO Trial, Freeware, Alpha, Beta, or Demo Software............................................................[NUKE 5X]
11.3 NO MULTi/iNTERNALs...........................................................................................[NUKE 5X]
11.4 EU/USA Releases Only!........................................................................................[NUKE 5X]

EOF
sed -i 's/sections="/sections="\nPS4:^11./' packages/scripts/tur-rules/tur-rules.sh
}

function PS5
{
cat << EOF >> site.rules
PS5 :
12.1 Main language: English/Nordic................................................................................[NUKE 5X]
12.2 NO Trial, Freeware, Alpha, Beta, or Demo Software............................................................[NUKE 5X]
12.3 NO MULTi/iNTERNALs...........................................................................................[NUKE 5X]
12.4 EU/USA Releases Only!........................................................................................[NUKE 5X]

EOF
sed -i 's/sections="/sections="\nPS5:^12./' packages/scripts/tur-rules/tur-rules.sh
}

function TV-720
{
cat << EOF >> site.rules
TV-720 :
13.1 Spoken language: English.....................................................................................[NUKE 5X]
13.2 Encoded in: 720p only!.......................................................................................[NUKE 5X]
13.3 Sources: HDTV/UHDTV/WEB......................................................................................[ALLOWED]
13.4 NO MULTi.....................................................................................................[NUKE 5X]

EOF
sed -i 's/sections="/sections="\nTV-720:^13./' packages/scripts/tur-rules/tur-rules.sh
}

function TV-1080
{
cat << EOF >> site.rules
TV-1080 :
14.1 Spoken language: English.....................................................................................[NUKE 5X]
14.2 Encoded in: 1080p only!......................................................................................[NUKE 5X]
14.3 Sources: HDTV/UHDTV/WEB......................................................................................[ALLOWED]
14.4 NO MULTi.....................................................................................................[NUKE 5X]

EOF
sed -i 's/sections="/sections="\nTV-1080:^14./' packages/scripts/tur-rules/tur-rules.sh
}

function TV-HD
{
cat << EOF >> site.rules
TV-HD :
15.1 Spoken language: English.....................................................................................[NUKE 5X]
15.2 Encoded in: 720p,1080p only!.................................................................................[NUKE 5X]
15.3 Sources: HDTV/UHDTV/WEB......................................................................................[ALLOWED]
15.4 NO MULTi.....................................................................................................[NUKE 5X]

EOF
sed -i 's/sections="/sections="\nTV-HD:^15./' packages/scripts/tur-rules/tur-rules.sh
}

function TV-NL
{
cat << EOF >> site.rules
TV-NL :
16.1 Spoken language: Dutch ......................................................................................[NUKE 5X]
16.2 Encoded in: 720p, 1080p only!................................................................................[NUKE 5X]
16.3 All sources..................................................................................................[ALLOWED]
16.4 NO iNTERNALs.................................................................................................[NUKE 5X]
16.5 iMDB/TVmaze no limitation....................................................................................[INFO]

EOF
sed -i 's/sections="/sections="\nTV-NL:^16./' packages/scripts/tur-rules/tur-rules.sh
}

function X264
{
cat << EOF >> site.rules
X264 :
17.1 Spoken language: English.....................................................................................[NUKE 5X]
17.2 Releases tagged in: MULTi/DUAL/HDTV/DUBBED/3D not allowed....................................................[NUKE 5X]
17.3 Encoded in: 720p,1080p only!.................................................................................[NUKE 5X]

EOF
sed -i 's/sections="/sections="\nX264:^17./' packages/scripts/tur-rules/tur-rules.sh
}

function X264-1080
{
cat << EOF >> site.rules
X264-1080 :
18.1 Spoken language: English.....................................................................................[NUKE 5X]
18.2 Releases tagged in: MULTi/DUAL/HDTV/DUBBED/3D not allowed....................................................[NUKE 5X]
18.3 Encoded in: 1080p only!......................................................................................[NUKE 5X]

EOF
sed -i 's/sections="/sections="\nX264-1080:^18./' packages/scripts/tur-rules/tur-rules.sh
}

function X264-720
{
cat << EOF >> site.rules
X264-720 :
19.1 Spoken language: English.....................................................................................[NUKE 5X]
19.2 Releases tagged in: MULTi/DUAL/HDTV/DUBBED/3D not allowed....................................................[NUKE 5X]
19.3 Encoded in: 720p only!.......................................................................................[NUKE 5X]

EOF
sed -i 's/sections="/sections="\nX264-720:^19./' packages/scripts/tur-rules/tur-rules.sh
}

function X265-2160
{
cat << EOF >> site.rules
X265-2160 :
20.1 Spoken language: English.....................................................................................[NUKE 5X]
20.2 Releases tagged in: MULTi/DUAL/HDTV not allowed..............................................................[NUKE 5X]
20.3 Encoded in: 2160p only!......................................................................................[NUKE 5X]

EOF
sed -i 's/sections="/sections="\nX265-2160:^20./' packages/scripts/tur-rules/tur-rules.sh
}

function XVID
{
cat << EOF >> site.rules
XVID :
21.1 Spoken language: English.....................................................................................[NUKE 5X]
21.2 Foreign allowed if english subs are present..................................................................[NUKE 5X]
21.3 NO iNTERNALs.................................................................................................[NUKE 5X]
21.4 All sources..................................................................................................[ALLOWED]

EOF
sed -i 's/sections="/sections="\nXVID:^21./' packages/scripts/tur-rules/tur-rules.sh
}

function XXX
{
cat << EOF >> site.rules
XXX :
22.1 Spoken language: English/Nordic..............................................................................[NUKE 5X]
22.2 NO Animal/Gay/Trans/Child Porn (male w/ male)! Lesbian is fine...............................................[DELUSER]
22.3 NO iNTERNALs.................................................................................................[NUKE 5X]
22.4 All sources in SD............................................................................................[ALLOWED]
22.5 Porn ratio no limitation.....................................................................................[INFO]

EOF
sed -i 's/sections="/sections="\nXXX:^22./' packages/scripts/tur-rules/tur-rules.sh
}

function XXX-PAYSITE
{
cat << EOF >> site.rules
XXX-PAYSITE :
23.1 Spoken language: English/Nordic..............................................................................[NUKE 5X]
23.2 NO Animal/Gay/Trans/Child Porn (male w/ male)! Lesbian is fine...............................................[DELUSER]
23.3 All sources in HD WEB 1080/2160p.............................................................................[ALLOWED]

EOF
sed -i 's/sections="/sections="\nXXX-PAYSITE:^23./' packages/scripts/tur-rules/tur-rules.sh
}

function MISC
{
cat << EOF >> site.rules
Changelog :
90.1 Rules updated 2021-11-24.....................................................................................[INFO]

EOF
sed -i 's/sections="/sections="\nChangelog:^90./' packages/scripts/tur-rules/tur-rules.sh
}

if [ "$1" = "" ]
then
	echo
else
	$1
fi

exit 0
