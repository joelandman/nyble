#!/bin/sh
# ramdiskroot - create a ramdisk in $NEWROOT and uncompress the
# payload file to it.

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin

# skip non-ramdisk
info " - in ramdiskroot.sh"
echo " - in ramdiskroot.sh"
[ $root != "ram" ] && exit 0

/bin/env

info "RAMDISK: "
export MEMSIZE=12
export ACTSIZE=16

info " - creating directory $NEWROOT"
mkdir -p $NEWROOT

ramdisktype=$(getarg ramdisktype=)

if [ "$ramdisktype" == "zram" ] ; then
info " - zram"
 modprobe -v zram num_devices=1
 modprobe -v ext4
 modprobe -v xfs
 echo "creating ${MEMSIZE}G zram drive"
 echo "with space for ${ACTSIZE}G capacity"
 echo ${MEMSIZE}G > /sys/block/zram0/disksize
 echo ${ACTSIZE}G > /sys/block/zram0/mem_limit
 info "creating ${MEMSIZE}G zram drive"
 info "with space for ${ACTSIZE}G capacity"

 #mkfs.ext4 -q -m 0 -b 4096 -O sparse_super,dir_index,extent -L root /dev/zram0
 mkfs.xfs -f -K /dev/zram0
 mount -o relatime /dev/zram0 $NEWROOT
 df -h
else
 #
 # regular uncompressed NEWROOT (resizeable)
 info " - did not find zram, building uncompressed root ramdisk"
 mount -t tmpfs -o size=${MEMSIZE}G,mode=0755 tmpfs $NEWROOT
fi


info " - unpacking image into $NEWROOT"
/usr/sbin/unpack_ramdisk_payload.sh $NEWROOT

info " - completed unpacking"

info " - moving sys, proc, dev, run to $NEWROOT"
mkdir -p $NEWROOT/sys
mkdir -p $NEWROOT/proc
mkdir -p $NEWROOT/dev
mkdir -p $NEWROOT/run
mount --bind /sys  $NEWROOT/sys
mount --bind /proc $NEWROOT/proc
mount --bind /dev  $NEWROOT/dev
mount --bind /run  $NEWROOT/run
info " - done moving mounts to $NEWROOT"

# inject new exit_if_exists
echo 'settle_exit_if_exists="--exit-if-exists=/dev/root"; rm -- "$job"' > $hookdir/initqueue/ramdisk.sh
# force udevsettle to break
> $hookdir/initqueue/work
