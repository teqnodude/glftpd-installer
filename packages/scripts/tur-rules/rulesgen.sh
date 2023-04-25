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

function MISC
{
cat << EOF >> site.rules
Changelog :
90.1 Rules updated 2022-04-22.....................................................................................[INFO]

EOF
sed -i 's/sections="/sections="\nChangelog:^90./' packages/scripts/tur-rules/tur-rules.sh
}

[ ! -z "$1" ] && $1

exit 0
