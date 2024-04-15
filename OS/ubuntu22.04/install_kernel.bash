#!/bin/bash -x

pwd
. ./kernel.data

echo TARGET = $TARGET
echo URL    = $KERNEL_URL
echo K VERS = $KERNEL_VERSION
echo KV     = $KV
echo NYBLE K= $NK
echo DISTRO = $DISTRO

groupadd stapusr
useradd _lldpd
groupadd Debian-exim

if [[ $NK -eq 1 ]]; then
	pushd .
	mkdir -p ${TARGET}/root/k
	cd ${TARGET}/root/k
	wget -c ${KERNEL_URL}/linux-headers-${KERNEL_VERSION}_${KERNEL_VERSION}-1_amd64.deb
	wget -c ${KERNEL_URL}/linux-libc-dev_${KERNEL_VERSION}-1_amd64.deb
	wget -c ${KERNEL_URL}/linux-image-${KERNEL_VERSION}_${KERNEL_VERSION}-1_amd64.deb
	wget -c ${KERNEL_URL}/linux-source-${KV}.tar.gz
	dpkg --root=${TARGET} -i ${TARGET}/root/k/*.deb
	popd

	cd ${TARGET}/lib/modules/${KERNEL_VERSION} ; rm -f build source
	#chroot ${TARGET} ln -s /usr/src/linux-headers-${KERNEL_VERSION} \
	#		/lib/modules/${KERNEL_VERSION}/build
	#chroot ${TARGET} ln -s /usr/src/linux-headers-${KERNEL_VERSION} \
	#		/lib/modules/${KERNEL_VERSION}/source

	# now build/install perf and friends
	export DEBIAN_FRONTEND=noninteractive ;  chroot ${TARGET} apt-get -y install \
		libgtk2.0-dev libslang2-dev libperl-dev libpython-dev libelf-dev     \
		python-dev libiberty-dev libdw-dev libbfd-dev perf-tools-unstable
	tar -zxf ${TARGET}/root/k/linux-source-${KV}.tar.gz -C  ${TARGET}/usr/src
	_BKV=`echo ${KV} | perl -pe 's/\.\d+$//g' `
	mv ${TARGET}/usr/src/linux-${_BKV} ${TARGET}/usr/src/linux-${KERNEL_VERSION}
	chroot ${TARGET} ln -s /usr/src/linux-${KERNEL_VERSION} \
		/lib/modules/${KERNEL_VERSION}/build
	chroot ${TARGET} ln -s /usr/src/linux-${KERNEL_VERSION} \ 
                /lib/modules/${KERNEL_VERSION}/source

	/bin/rm -f ${TARGET}/root/k/*.deb  ${TARGET}/root/linux-source-${KV}.tar.gz
	echo KV=${KV} > ${TARGET}/root/kv.data
	
	#chroot ${TARGET} /root/install_perf.bash
	chroot ${TARGET} /root/prepare_modbuild.bash
	rm -f ${TARGET}/root/install_perf.bash
	rm -rf ${TARGET}/root/k
	

else
	export DEBIAN_FRONTEND=noninteractive ; chroot ${TARGET} apt-get -y \
		install linux-base \
			linux-image-generic-hwe-22.04 \
			initramfs-tools        \
			libgtk2.0-dev \
			libslang2-dev \
			libperl-dev        \
			libelf-dev \
			python-dev-is-python3 \
			libiberty-dev \
		       	libdw-dev \
			binutils-dev  \
			module-assistant \
			linux-libc-dev \
			libelf-dev  	 	    
	# linux-source

	cp get_kver.bash ${TARGET}/root
	KERNEL_VERSION=`${TARGET}/root/get_kver.bash ${TARGET}`
        KV=`echo ${KERNEL_VERSION} | cut -d"." -f1,2`
        echo NYBLE_KERNEL=${NYBLE_KERNEL}          > ${TARGET}/root/kernel.data
        echo TARGET=${TARGET}                 >> ${TARGET}/root/kernel.data
        echo KERNEL_URL=${KERNEL_URL}         >> ${TARGET}/root/kernel.data
        echo KERNEL_VERSION=${KERNEL_VERSION}      >> ${TARGET}/root/kernel.data
        echo KV=${KV}                         >> ${TARGET}/root/kernel.data
        echo NK=${NYBLE_KERNEL}             >> ${TARGET}/root/kernel.data
        echo DISTRO=${DISTRO}                 >> ${TARGET}/root/kernel.data
        cp -fv ${TARGET}/root/kernel.data kernel.data
        
	# unpack kernel source, and prepare modules
	#pushd .
	#cd ${TARGET}/usr/src
	#tar -I /usr/bin/xz -xf linux-source-${KV}.tar.xz
	#rm -f linux-source-${KV}.tar.xz linux-patch-${KV}-rt.patch.xz
	#cd linux-source-${KV}
	#make mrproper
	#cp ../linux-headers-${KERNEL_VERSION}/.config .
	#make oldconfig
	#make modules_prepare
	#cp ../linux-headers-${KERNEL_VERSION}/Module.symvers .
	chroot ${TARGET} m-a prepare --non-inter -l ${KERNEL_VERSION}
	#popd

	# remove the current build/source from /lib/modules/`uname -r`/ and replace them with the real
	# one we just constructed
	#rm -f ${TARGET}/lib/modules/${KERNEL_VERSION}/build ${TARGET}/lib/modules/${KERNEL_VERSION}/source
        #chroot ${TARGET} ln -s /usr/src/linux-source-${KV}  /lib/modules/${KERNEL_VERSION}/source
	#chroot ${TARGET} ln -s /usr/src/linux-source-${KV}  /lib/modules/${KERNEL_VERSION}/build
	#chroot ${TARGET} /root/prepare_modbuild.bash
fi
