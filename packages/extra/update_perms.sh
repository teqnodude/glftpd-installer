#!/bin/bash

# path to glftpd
glroot=/glftpd

# set ownership
chown -R root:root "$glroot/bin"

# ensure scripts are executable
chmod 755 "$glroot"/bin/*.sh 2>/dev/null

# setuid on selected binaries (ignore missing ones quietly)
for f in undupe sed nuker cleanup chown foo-pre
do

    if [[ -f "$glroot/bin/$f" ]]
    then

        chmod u+s "$glroot/bin/$f"

    fi

done
