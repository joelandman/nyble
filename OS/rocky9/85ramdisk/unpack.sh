#!/bin/sh
NR=$1
/usr/bin/pbzip2 -dc /nyble_snap.tar.bz2 | /usr/bin/tar -xS -C $NR
#/usr/bin/tar -I /usr/bin/pbzip2 -xS -C $NR
rm -f /nyble_snap.tar.bz2
