#!/usr/bin/env bash

export _SPL=0.7.8
export _ZFS=0.7.8
export _arch=arch

cd /root/zfs
# spl
tar -zxf spl-${_SPL}.tar.gz
cd spl-${_SPL}
./configure
make -j8
make install

cd ../

# zfs
tar -zxf zfs-${_ZFS}.tar.gz
cd spl-${_ZFS}
./configure
make -j8
make install

