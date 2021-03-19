#!/bin/sh
NR=$1
#[[ -e /nyble_snap.tar.bz2 ]] && /usr/bin/pbzip2 -dc /nyble_snap.tar.bz2 | /usr/bin/tar -xS -C $NR
/usr/bin/zstd -d --stdout /nyble_snap.tar.zst | /usr/bin/tar -xS -C $NR
#/usr/bin/tar -I /usr/bin/pbzip2 -xS -C $NR
if (grep -q image=keep /proc/cmdline); then
	echo "Keeping image"
#	[[ -e /nyble_snap.tar.bz2 ]] && mv -fv /nyble_snap.tar.bz2 $NR
	mv -fv /nyble_snap.tar.zst $NR
   else
	echo "Removing image"
        rm -f  /nyble_snap.tar*
endif
