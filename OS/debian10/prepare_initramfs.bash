#!/bin/bash

TARGET=$1
NYBLE_SNAP=$2
COMP_BIN=$3

cp -vf OS/debian10/nyble.hook ${TARGET}/usr/share/initramfs-tools/hooks/nyble
cp -vf OS/debian10/tools.hook ${TARGET}/usr/share/initramfs-tools/hooks/tools
 # insert our modified local script to insure that ROOT=ram doesn't error out
cp -vf OS/debian10/local ${TARGET}/usr/share/initramfs-tools/scripts

chmod +x ${TARGET}/usr/share/initramfs-tools/hooks/nyble
chmod +x ${TARGET}/usr/share/initramfs-tools/hooks/tools
mkdir -p ${TARGET}/usr/share/initramfs-tools/scripts/local-top/
cp -vf OS/debian10/ramboot.initramfs \
       ${TARGET}/usr/share/initramfs-tools/scripts/local-top/ramboot
sed -i "s|__NYBLE_SNAP__|${NYBLE_SNAP}|g" ${TARGET}/usr/share/initramfs-tools/scripts/local-top/ramboot
sed -i "s|__COMP_BIN__|${COMP_BIN}|g" ${TARGET}/usr/share/initramfs-tools/scripts/local-top/ramboot
chmod +x ${TARGET}/usr/share/initramfs-tools/scripts/local-top/ramboot
