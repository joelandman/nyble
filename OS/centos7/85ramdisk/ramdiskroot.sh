#!/bin/sh
# ramdiskroot - create a ramdisk in $NEWROOT and uncompress the
# payload file to it.

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin

# skip non-ramdisk
[ $root != "ram" ] && exit 0
info "resizing ..."
mount -o remount,size=4G /
mount -o remount,size=4G /sys
mount -o remount,size=4G /dev
mount -o remount,size=4G /dev/shm
info " ... done resizing"

info "preparing ramdisk:"
MEMSIZE=4


info " - creating directory $NEWROOT"
mkdir -p $NEWROOT

#
# zram version of NEWROOT (non resizeable)
#ZRAM=`modprobe zram --first-time num_devices=1`

# check if zram loaded, if so use this, otherwise use the regular mount
#if $ZRAM ; then
# info " - found zram, building compressed root ramdisk"
# echo ${MEMSIZE}G > /sys/block/zram0/disksize
# echo ${MEMSIZE}G > /sys/block/zram0/mem_limit
# mkfs.ext4 -q -m 0 -b 4096 -O sparse_super,dir_index,extent -L root /dev/zram0
# mount -o relatime /dev/zram0 $NEWROOT
#else
 #
 # regular uncompressed NEWROOT (resizeable)
# info " - did not find zram, building uncompressed root ramdisk"
 mount -t tmpfs -o size=${MEMSIZE}G,mode=0755 tmpfs $NEWROOT
#fi


info " - unpacking image into $NEWROOT"
/usr/sbin/unpack_ramdisk_payload.sh $NEWROOT

info " - completed unpacking"

info " - moving sys, proc, dev, run to $NEWROOT"
#mount --make-private $NEWROOT
mount --bind /sys  $NEWROOT/sys
mount --bind /proc $NEWROOT/proc
mount --bind /dev  $NEWROOT/dev
mount --bind /run  $NEWROOT/run
#mount --bind /var  $NEWROOT/var
info " - done moving mounts to $NEWROOT"

# inject new exit_if_exists
echo 'settle_exit_if_exists="--exit-if-exists=/dev/root"; rm -- "$job"' > $hookdir/initqueue/ramdisk.sh
# force udevsettle to break
> $hookdir/initqueue/work
