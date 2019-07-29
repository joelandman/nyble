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
	pushd .
	cd ${TARGET}/t ; cat bootoptions | ./buildcfg.pl  >> syslinux.cfg
	popd
	umount ${TARGET}/t
	losetup -d /dev/loop3	
	touch usbkey
	

osinst: ramdisk_build_1 osinst_last
	touch osinst

finalizebase: osinst fb_last
	touch finalizebase

#  pull in any additional config options
include config/all.conf
include kernel/kernel.conf

#  define server URLs for major components
include urls.conf

# attach to distro specific build
include OS/${DISTRO}/base.conf
include OS/${DISTRO}/config.conf

#  place new packages to install in the packages/ directory
include packages/packages.conf



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
	cp -fv scripts/*.pl  ${TARGET}/opt/nyble/bin
	chmod +x ${TARGET}/opt/nyble/bin/*.pl
	chroot ${TARGET} ln -s /opt/nyble/bin/lsnet.pl /usr/bin/lsnet.pl
	chroot ${TARGET} ln -s /opt/nyble/bin/lsbond.pl /usr/bin/lsbond.pl
	chroot ${TARGET} ln -s /opt/nyble/bin/lsbr.pl /usr/bin/lsbr.pl

	touch ramdisk_build_2


ramdisk_build_3:	ramdisk_build_2

ifndef PHYSICAL
ifneq ($(DISTRO),centos7)
	umount -l ${TARGET}/dev
	umount -l ${TARGET}/sys
	umount -l ${TARGET}/proc
endif
	rm -f /mnt/nyble_snap.tar.xz
ifeq ($(DISTRO),debian9)
	rm -rf ${TARGET}/usr/games ${TARGET}/usr/local/games
ifeq ($(ONLYCORE),1)
	rm -rf ${TARGET}/var/cache/apt ${TARGET}/var/lib/apt 		\
				 ${TARGET}/usr/share/doc
endif
endif
ifeq ($(DISTRO),ubuntu18.04)
	rm -rf ${TARGET}/usr/games ${TARGET}/usr/local/games
ifeq ($(ONLYCORE),1)
	rm -rf ${TARGET}/var/cache/apt ${TARGET}/var/lib/apt	    \
				 ${TARGET}/usr/share/doc
endif
endif

ifeq ($(DISTRO),debian9)	
	cd ${TARGET} ;	 tar -I /usr/bin/pbzip2 -cSf /mnt/nyble_snap.tar.bz2  --exclude="^./run/docker*" \
		--exclude="./run/samba/winbindd/pipe*" --exclude="^./sys/*" \
		--exclude="^./proc/*" --exclude="./dev/*"  \
		--exclude="^./var/lib/docker/devicemapper/devicemapper/*"  \
		bin  boot  data dev  etc  home  lib lib64  media  mnt  opt  proc root \
		run  sbin  srv sys tmp  usr  var
endif
ifeq ($(DISTRO),ubuntu18.04)
	cd ${TARGET} ;   tar -I /usr/bin/pbzip2 -cSf /mnt/nyble_snap.tar.bz2  --exclude="^./run/docker*" \
		--exclude="./run/samba/winbindd/pipe*" --exclude="^./sys/*" \
		--exclude="^./proc/*" --exclude="./dev/*"  \
		--exclude="^./var/lib/docker/devicemapper/devicemapper/*"  \
		bin  boot  data dev  etc  home  lib lib64  media  mnt  opt  proc root \
		run  sbin  srv sys tmp  usr  var
endif
ifeq ($(DISTRO),centos7)
	rm -fr  ${TARGET}/var/cache/yum  ${TARGET}/usr/games 
	cd ${TARGET} ;   tar -I /usr/bin/pbzip2 -cSf /mnt/nyble_snap.tar.bz2  \
		bin boot data etc home lib lib64 media mnt opt root \
		run sbin srv tmp usr var
endif
	mv -fv /mnt/nyble_snap.tar.bz2 ${TARGET}
endif
	touch ramdisk_build_3

ramdisk_build_final: ramdisk_build_3
ifndef PHYSICAL
	# for ramdisk based booting
ifeq ($(DISTRO),debian9)
	cp -vf OS/debian9/nyble.hook ${TARGET}/usr/share/initramfs-tools/hooks/nyble
	cp -vf OS/debian9/tools.hook ${TARGET}/usr/share/initramfs-tools/hooks/tools
	chmod +x ${TARGET}/usr/share/initramfs-tools/hooks/nyble
	chmod +x ${TARGET}/usr/share/initramfs-tools/hooks/tools
	mkdir -p ${TARGET}/usr/share/initramfs-tools/scripts/local-top/
	cp -vf OS/debian9/ramboot.initramfs \
		${TARGET}/usr/share/initramfs-tools/scripts/local-top/ramboot

	chmod +x ${TARGET}/usr/share/initramfs-tools/scripts/local-top/ramboot
	#cp local.ramboot  ${TARGET}/usr/share/initramfs-tools/scripts/local
	#chmod +x ${TARGET}/usr/share/initramfs-tools/scripts/local
endif
ifeq ($(DISTRO),ubuntu18.04)
	cp -vf OS/ubuntu18.04/nyble.hook ${TARGET}/usr/share/initramfs-tools/hooks/nyble
	cp -vf OS/ubuntu18.04/tools.hook ${TARGET}/usr/share/initramfs-tools/hooks/tools
	chmod +x ${TARGET}/usr/share/initramfs-tools/hooks/nyble
	chmod +x ${TARGET}/usr/share/initramfs-tools/hooks/tools
	mkdir -p ${TARGET}/usr/share/initramfs-tools/scripts/local-top/
	cp -vf OS/ubuntu18.04/ramboot.initramfs \
		${TARGET}/usr/share/initramfs-tools/scripts/local-top/ramboot

	chmod +x ${TARGET}/usr/share/initramfs-tools/scripts/local-top/ramboot
	#cp local.ramboot  ${TARGET}/usr/share/initramfs-tools/scripts/local
	#chmod +x ${TARGET}/usr/share/initramfs-tools/scripts/local
endif

ifeq ($(DISTRO),centos7)
	#cat OS/${DISTRO}/dracut-functions.patch | chroot ${TARGET} /usr/bin/patch -p1
	cp -fv OS/${DISTRO}/dracut-functions.sh \
		${TARGET}/usr/lib/dracut/dracut-functions.sh
	chroot ${TARGET} yum clean all
	rm -rf ${TARGET}/var/cache/yum
	chroot ${TARGET} /usr/sbin/dracut -v --force --regenerate-all
endif
endif
	#
	# remove the policy bits now to allow ramdisk and other services to rebuild
	rm -f ${TARGET}/usr/sbin/policy-rc.d
	#
ifeq ($(DISTRO),debian9)
	chroot ${TARGET} /usr/sbin/mkinitramfs -v -o \
		/boot/initramfs-ramboot-${KERNEL_VERSION} ${KERNEL_VERSION}
endif
ifeq ($(DISTRO),ubuntu18.04)
	chroot ${TARGET} /usr/sbin/mkinitramfs -v -o \
		/boot/initramfs-ramboot-${KERNEL_VERSION} ${KERNEL_VERSION}
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
