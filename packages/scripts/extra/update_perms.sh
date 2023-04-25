#!/bin/bash

chown -R root:root /glftpd/bin
chmod 755 /glftpd/bin/*.sh
chmod u+s /glftpd/bin/undupe /glftpd/bin/sed /glftpd/bin/nuker /glftpd/bin/cleanup /glftpd/bin/chown /glftpd/bin/foo-pre /glftpd/bin/foo-pre >/dev/null 2>&1

exit 0
