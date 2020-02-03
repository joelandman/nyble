#!/usr/bin/env bash

export _ZFS=0.8.2
export _arch=arch

cd /root/zfs

# zfs
tar -zxf zfs-${_ZFS}.tar.gz
cd zfs-${_ZFS}
./configure
make -j8
make install

