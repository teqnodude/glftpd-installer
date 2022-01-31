#!/bin/bash

chown -R root:root /glftpd/bin
chmod 755 /glftpd/bin/*.sh
chmod u+s /glftpd/bin/undupe /glftpd/bin/sed /glftpd/bin/nuker /glftpd/bin/foo-pre /glftpd/bin/cleanup

exit 0
