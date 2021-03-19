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
    instmods zram
    instmods ext4
    instmods xfs
}

install() {
    inst_hook cmdline 29 "$moddir/parse-ramdisk.sh"
    inst_hook pre-mount 85 "$moddir/ramdiskroot.sh"
    inst_multiple bzip2 pbzip2 pigz gzip zstd tar mkfs.ext3 mke2fs mkfs.xfs mkfs.ext4 lsscsi lsmod df find which wc env md5sum
    inst "$moddir/unpack.sh" /sbin/unpack_ramdisk_payload.sh
#    inst "/nyble_snap.tar.bz2" /nyble_snap.tar.bz2
    inst "/nyble_snap.tar.zst" /nyble_snap.tar.zst
    dracut_need_initqueue
}
