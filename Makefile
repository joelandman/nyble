# Nlytiq Base Linux Environment (NyBLE)
#  This is the image building makefile.
#
LODEV	= $(shell scripts/lodev.sh)

all:	finalizebase ramdisk_build_final

usbkey:	finalizebase ramdisk_build_final
	# assume an (at least) 4GB USB drive
	fallocate  -l 4G ${TARGET}/nyble.usb
	losetup ${LODEV} ${TARGET}/nyble.usb
	parted ${LODEV} mklabel msdos
	parted ${LODEV} mkpart primary fat32 1MB 2GB
	mkfs.fat ${LODEV}p1
	syslinux -i ${LODEV}p1
	dd conv=notrunc bs=440 count=1 if=usb/mbr.bin of=${LODEV}
	parted ${LODEV} set 1 boot on
	mkdir ${TARGET}/t
	mount ${LODEV}p1 ${TARGET}/t
	cp -vf ${TARGET}/boot/vmlinuz* ${TARGET}/boot/initramfs* ${TARGET}/t
	cp usb/bootoptions usb/buildcfg.pl usb/vesamenu.c32 usb/menu.c32 ${TARGET}/t
	cp usb/top ${TARGET}/t/syslinux.cfg
	cd ${TARGET}/t ; cat bootoptions | ./buildcfg.pl  >> syslinux.cfg
	umount ${TARGET}/t
	losetup -d ${LODEV}
	touch usbkey
	

osinst: ramdisk_build_1 osinst_last
	touch osinst

finalizebase: osinst fb_last
	touch finalizebase

#  pull in any additional config options
include config/all.conf
include kernel/kernel.conf

# attach to distro specific build
include OS/${DISTRO}/base.conf
include OS/${DISTRO}/config.conf

#  place new packages to install in the packages/ directory
include packages/packages.conf

######################
# compressor file extension and binary
#
ifeq (${COMP},bzip2)
COMP_BIN=$(shell which bzip2)
COMP_EXT=bz2
endif
ifeq (${COMP},pbzip2)
COMP_BIN=$(shell which  pbzip2)
COMP_EXT=bz2
endif
ifeq (${COMP},lbzip2)
COMP_BIN=$(shell which  lbzip2)
COMP_EXT=bz2
endif
ifeq (${COMP},gzip)
COMP_BIN=$(shell which  gzip)
COMP_EXT=gz
endif
ifeq (${COMP},pigz)
COMP_BIN=$(shell which pigz)
COMP_EXT=gz
endif
ifeq (${COMP},xz)
COMP_BIN=$(shell which  xz)
COMP_EXT=xz
endif
ifeq (${COMP},pxz)
COMP_BIN=$(shell which  pxz)
COMP_EXT=xz
endif
ifeq (${COMP},zstd)
COMP_BIN=$(shell which zstd)
COMP_EXT=zst
endif

NYBLE_SNAP=nyble_snap.tar.${COMP_EXT}



ramdisk_build_1:
	# create the ramdisk for the OS image construction
ifndef PHYSICAL
  # this will wipe ${TARGET} if it is already mounted (it shouldn't be unless
	# it is a physcal device )
	bash -c "if [ `grep -q  ${TARGET} /proc/mounts ` ]; then rm -rf ${TARGET} ;	fi"
	rm -f ${TARGET}/nyble_snap.tar*
	echo TARGET = ${TARGET}
	mkdir -p ${TARGET}
	touch /mnt/nyble_snap.tar
	mount -o size=24g -t tmpfs none ${TARGET}
endif
	touch ramdisk_build_1


ramdisk_build_2:	finalizebase

ifndef PHYSICAL
	# mask off systemd-udev-settle ... yes it is broken
	chroot ${TARGET} systemctl mask systemd-udev-settle
endif

	# place scripts where they need to be for startup
	mkdir -p ${TARGET}/opt/nyble/bin
	cp -fv scripts/*.pl scripts/spark  ${TARGET}/opt/nyble/bin
	chmod +x ${TARGET}/opt/nyble/bin/*.pl
	chroot ${TARGET} ln -s /opt/nyble/bin/lsnet.pl /usr/bin/lsnet.pl
	chroot ${TARGET} ln -s /opt/nyble/bin/lsbond.pl /usr/bin/lsbond.pl
	chroot ${TARGET} ln -s /opt/nyble/bin/lsbr.pl /usr/bin/lsbr.pl
	chroot ${TARGET} ln -s /opt/nyble/bin/pcilist.pl /usr/bin/pcilist.pl
	chroot ${TARGET} ln -s /opt/nyble/bin/lsint.pl /usr/bin/lsint.pl
	chroot ${TARGET} ln -s /opt/nyble/bin/spark /usr/bin/spark
	touch ramdisk_build_2


ramdisk_build_3:	ramdisk_build_2

ifndef PHYSICAL
ifneq ($(DISTRO),centos7)
	umount -l ${TARGET}/dev
	umount -l ${TARGET}/sys
	umount -l ${TARGET}/proc
endif
	rm -f /mnt/${NYBLE_SNAP}

ifeq ($(DISTRO),debian9)
	rm -rf ${TARGET}/usr/games ${TARGET}/usr/local/games
endif
ifeq ($(DISTRO),debian10)
	rm -rf ${TARGET}/usr/games ${TARGET}/usr/local/games
endif
ifeq ($(DISTRO),ubuntu18.04)
	rm -rf ${TARGET}/usr/games ${TARGET}/usr/local/games
ifeq ($(ONLYCORE),1)
	rm -rf ${TARGET}/var/cache/apt ${TARGET}/var/lib/apt	    \
				 ${TARGET}/usr/share/doc
endif
endif
ifeq ($(DISTRO),ubuntu20.04)
	rm -rf ${TARGET}/usr/games ${TARGET}/usr/local/games
ifeq ($(ONLYCORE),1)
	rm -rf ${TARGET}/var/cache/apt ${TARGET}/var/lib/apt	\
				 ${TARGET}/usr/share/doc
endif
endif



ifneq ($(DISTRO),centos7)	
	cd ${TARGET} ;	 tar -I "${COMP_BIN}" -cSf /mnt/${NYBLE_SNAP}  --exclude="^./run/docker*" \
		--exclude="./run/samba/winbindd/pipe*" --exclude="^./sys/*" \
		--exclude="^./proc/*" --exclude="./dev/*"  \
		--exclude="^./var/lib/docker/devicemapper/devicemapper/*"  \
		bin  boot  data dev  etc  home  lib lib64  media  mnt  opt  proc root \
		run  sbin  srv sys tmp  usr  var
endif
ifeq ($(DISTRO),centos7)
	rm -fr  ${TARGET}/var/cache/yum  ${TARGET}/usr/games 
	cd ${TARGET} ;   tar -I "${COMP_BIN}" -cSf /mnt/${NYBLE_SNAP}  \
		bin boot data etc home lib lib64 media mnt opt root \
		run sbin srv tmp usr var
endif
	mv -fv /mnt/${NYBLE_SNAP} ${TARGET}
endif
	touch ramdisk_build_3

ramdisk_build_final: ramdisk_build_3
	#
	# remove the policy bits now to allow ramdisk and other services to rebuild
	rm -f ${TARGET}/usr/sbin/policy-rc.d
	#

ifndef PHYSICAL
	# for ramdisk based booting
ifneq ($(DISTRO),centos7)
	OS/${DISTRO}/prepare_initramfs.bash ${TARGET} ${NYBLE_SNAP} ${COMP_BIN}
	chroot ${TARGET} /usr/sbin/mkinitramfs -v -o \
		/boot/initramfs-ramboot-${KERNEL_VERSION} ${KERNEL_VERSION}
else
	#cat OS/${DISTRO}/dracut-functions.patch | chroot ${TARGET} /usr/bin/patch -p1
	cp -fv OS/${DISTRO}/dracut-functions.sh \
		${TARGET}/usr/lib/dracut/dracut-functions.sh
	chroot ${TARGET} yum clean all
	rm -rf ${TARGET}/var/cache/yum
	chroot ${TARGET} /usr/sbin/dracut --force --regenerate-all
endif
endif
	touch ramdisk_build_final


ramdisk_build_last:	ramdisk_build_final
	touch ramdisk_build_last


clean:
	rm -f osinst finalizebase fb_* osinst_* ramdisk_build_* /mnt/nyble_snap.tar* \
		ramdisk_build_* kernel.data usbkey
	cd packages ; $(MAKE) clean
	$(shell umount ${TARGET}/dev ${TARGET}/proc ${TARGET}/sys ${TARGET} )
	$(shell if [[ -e ${LODEV} ]]; then losetup -d ${LODEV} ; fi )
	rm -f lodev.data
	umount -l -f ${TARGET}

test_clean:
	grep  ${TARGET}  /proc/mounts


###################################################
## debugging targets

print-%  : ; @echo $* = $($*)
# use as "make print-VARIABLE_NAME" to see variable name
