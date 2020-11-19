#!/bin/bash

if ( -e /etc/debian_version ); then
. /root/kernel.data
cd /usr/src/linux-source-${KV}
make modules_prepare
fi
