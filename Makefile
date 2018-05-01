# Nlytiq Base Linux Environment (NyBLE)
#  This is the image building makefile.
#

# by default, build complete system
ONLYCORE=0
# alternative, comment above line out, and uncomment below to build
# minimum system
#ONLYCORE=1

### default build target
ifndef TARGET
TARGET=/mnt/root
endif

all:	finalizebase ramdisk_build_final

osinst: ramdisk_build_1 osinst_last
	touch osinst

finalizebase: osinst fb_last
	touch finalizebase


DISTRO=debian9
#DISTRO=ubuntu16.04
#DISTRO=centos7
#DISTRO=rhel7


#  define server URLs for major components
include urls.conf

# attach to distro specific build
include OS/${DISTRO}/base.conf
include OS/${DISTRO}/config.conf


#  Select the kernel to use by modifying the kernel/kernel.conf file
include kernel/kernel.conf

#  place new drivers to install in the drivers/ directory
include drivers/driver.conf

#  place new packages to install in the packages/ directory
include packages/packages.conf

#  pull in any additional config options
include config/all.conf



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
	touch ramdisk_build_2


ramdisk_build_3:	ramdisk_build_2

ifndef PHYSICAL
	umount -l ${TARGET}/dev
	umount -l ${TARGET}/sys
	umount -l ${TARGET}/proc
	rm -f /mnt/nyble_snap.tar.xz
ifeq ($(DISTRO),debian9)
	rm -rf ${TARGET}/usr/games ${TARGET}/usr/local/games
ifeq ($(ONLYCORE),1)
	rm -rf ${TARGET}/var/cache/apt ${TARGET}/var/lib/apt 		\
				 ${TARGET}/usr/share/doc
endif
endif
	cd ${TARGET} ;	 tar -I /usr/bin/pbzip2 -cSf /mnt/nyble_snap.tar.bz2  --exclude="^./run/docker*" \
		--exclude="^./run/samba/winbindd/pipe*" --exclude="^./sys/*" \
		--exclude="^./proc/*" \
		--exclude="^./var/lib/docker/devicemapper/devicemapper/*"  \
		bin  boot  data dev  etc  home  lib lib64  media  mnt  opt  proc root \
		run  sbin  srv sys tmp  usr  var
	mv -fv /mnt/nyble_snap.tar.bz2 ${TARGET}
endif
	touch ramdisk_build_3

ramdisk_build_final: ramdisk_build_3
ifndef PHYSICAL
	# for ramdisk based booting
ifeq ($(DISTRO),debian9)
	cp OS/debian9/nyble.hook ${TARGET}/usr/share/initramfs-tools/hooks/nyble
	cp OS/debian9/tools.hook ${TARGET}/usr/share/initramfs-tools/hooks/tools
	chmod +x ${TARGET}/usr/share/initramfs-tools/hooks/nyble
	chmod +x ${TARGET}/usr/share/initramfs-tools/hooks/tools
	mkdir -p ${TARGET}/usr/share/initramfs-tools/scripts/local-top/
	cp OS/debian9/ramboot.initramfs ${TARGET}/usr/share/initramfs-tools/scripts/local-top/ramboot

	chmod +x ${TARGET}/usr/share/initramfs-tools/scripts/local-top/ramboot
	#cp local.ramboot  ${TARGET}/usr/share/initramfs-tools/scripts/local
	#chmod +x ${TARGET}/usr/share/initramfs-tools/scripts/local
endif

ifeq ($(DISTRO),centos7)
	#cat OS/${DISTRO}/dracut-functions.patch | chroot ${TARGET} /usr/bin/patch -p1 
	cp OS/${DISTRO}/dracut-functions.sh ${TARGET}/usr/lib/dracut/dracut-functions.sh
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
	chroot ${TARGET} /usr/sbin/mkinitramfs -v -o /boot/initramfs-ramboot-${KERNEL_VERSION} ${KERNEL_VERSION}
endif
	touch ramdisk_build_final


ramdisk_build_last:	ramdisk_build_final
	touch ramdisk_build_last


clean:
	rm -f osinst finalizebase fb_* osinst_* ramdisk_build_* /mnt/nyble_snap.tar* \
		ramdisk_build_* kernel.data
	cd drivers  ; $(MAKE) clean
	cd packages ; $(MAKE) clean
	$(shell umount ${TARGET}/dev ${TARGET}/proc ${TARGET}/sys ${TARGET} )
	umount -l -f ${TARGET}

test_clean:
	grep  ${TARGET}  /proc/mounts


###################################################
## debugging targets

print-%  : ; @echo $* = $($*)
# use as "make print-VARIABLE_NAME" to see variable name
