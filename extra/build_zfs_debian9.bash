#!/usr/bin/env bash

export _SPL=0.6.4.2
export _ZFS=0.6.4.2
export _arch=arch

# spl
tar -zxf spl-${_SPL}.tar.gz
cd spl-${_SPL}
./configure
make deb-utils deb-kmod
dpkg -i kmod-spl-devel-${_SPL}.${_arch}.deb \
	kmod-spl-devel-kernel-${_SPL}.${_arch}.deb \
	kmod-spl-kernel-${_SPL}.${_arch}.deb \
	spl--${_SPL}.${_arch}.deb


cd ../

# zfs
tar -zxf spl-${_ZFS}.tar.gz
./configure
make deb-utils deb-kmod
dpkg -i kmod-zfs-kernel-${_ZFS}.${_arch}.deb \
	kmod-zfs-devel-${_ZFS}.${_arch}.deb  \
	kmod-zfs-devel-kernel-${_ZFS}.${_arch}.deb


