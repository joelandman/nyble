#!/bin/bash -x

pwd
. ./kernel.data

echo TARGET = $TARGET
echo URL    = $KERNEL_URL
echo K VERS = $KERNEL_VERSION
echo KV     = $KV
echo NYBLE K= $NK
echo DISTRO = $DISTRO


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
		install linux-base linux-image-oem   initramfs-tools        \
		libgtk2.0-dev libslang2-dev libperl-dev libpython-dev       \
		libelf-dev python-dev libiberty-dev libdw-dev binutils-dev  \
		linux-source linux-libc-dev module-assistant linux-tools-oem   
	KERNEL_VERSION=`${TARGET}/root/get_kver.bash ${TARGET}`
	KV=`echo ${KERNEL_VERSION} | cut -d"." -f1,2`
	echo NYBLE_KERNEL=${NYBLE_KERNEL}           > ${TARGET}/root/kernel.data
        echo TARGET=${TARGET}                      >> ${TARGET}/root/kernel.data
        echo KERNEL_URL=${KERNEL_URL}              >> ${TARGET}/root/kernel.data
        echo KERNEL_VERSION=${KERNEL_VERSION}      >> ${TARGET}/root/kernel.data
        echo KV=${KV}                              >> ${TARGET}/root/kernel.data
        echo NK=${NYBLE_KERNEL}                    >> ${TARGET}/root/kernel.data
        echo DISTRO=${DISTRO}                      >> ${TARGET}/root/kernel.data
	cp -fv ${TARGET}/root/kernel.data kernel.data
	chroot ${TARGET} module-assistant -i -l ${KERNEL_VERSION} prepare
	chroot ${TARGET} ln -s /lib/modules/${KERNEL_VERSION}/build  /lib/modules/${KERNEL_VERSION}/source

	############################################################################
	# create a /usr/src/build/linux directory with kernel sources, .config
	# from the header directories, and prepare these sources for module building

	mkdir -p ${TARGET}/usr/src/build/linux
	cd ${TARGET}/usr/src/build/ ;\
		tar -jxf `ls ${TARGET}/usr/src/*bz2` ;\
		mv ${TARGET}/usr/src/build/linux* ${TARGET}/usr/src/build/linux ;\
		cp ${TARGET}/usr/src/build/linux-headers-${KERNEL_VERSION}/.config ${TARGET}/usr/src/build/linux
	cd ${TARGET}/usr/src/build/linux ;\
		make oldconfig
		make scripts
		make prepare
	mv ${TARGET}/lib/modules/${KERNEL_VERSION}/source ${TARGET}/lib/modules/${KERNEL_VERSION}/source.original
	mv ${TARGET}/lib/modules/${KERNEL_VERSION}/build ${TARGET}/lib/modules/${KERNEL_VERSION}/build.original
	chroot  ${TARGET} ln -s /usr/src/build/linux /lib/modules/${KERNEL_VERSION}/source
	chroot  ${TARGET} ln -s /usr/src/build/linux /lib/modules/${KERNEL_VERSION}/build
	
fi
