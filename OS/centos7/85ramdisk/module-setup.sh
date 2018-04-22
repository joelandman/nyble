#!/bin/bash
# module-setup.sh for ramdisk

check() {
    return 0
}

depends() {
    return 0
}

installkernel() {
    instmods loop
}

install() {
    inst_hook cmdline 29 "$moddir/parse-ramdisk.sh"
    inst_hook pre-mount 91 "$moddir/ramdiskroot.sh"
    inst_multiple pbzip2 pigz gzip tar mkfs.ext3 mke2fs mkfs.xfs mkfs.ext4 lsscsi lsmod df
    inst "$moddir/unpack.sh" /sbin/unpack_ramdisk_payload.sh
    inst "/nyble_snap.tar.bz2" /nyble_snap.tar.bz2
    dracut_need_initqueue
}
