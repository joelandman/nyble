#!/bin/bash -x

pwd
. ./kernel.data

echo TARGET       = $TARGET
echo URL          = $KERNEL_URL
echo K VERS       = $KERNEL_VERSION
echo KV           = $KV
echo NYBLE_KERNEL = $NK
echo DISTRO       = $DISTRO

		dracut-config-generic dracut-tools dracut-config-rescue

if [[ $NK -eq 1 ]]; then
	# use custom kernel
	pushd .
	# remove old kernel
	rpm -ev --nodeps `rpm -qa --root=${TARGET} | grep kernel` --root=${TARGET}
  	rpm -ivh ${KERNEL_URL}/kernel-${KERNEL_VERSION}-1.x86_64.rpm 		\
		 ${KERNEL_URL}/kernel-headers-${KERNEL_VERSION}-1.x86_64.rpm    \
		 ${KERNEL_URL}/kernel-devel-${KERNEL_VERSION}-1.x86_64.rpm    \
		 --force --nodeps --root=${TARGET}
		# kernel-devel will make ramdisk very large
#		 ${KERNEL_URL}/kernel-devel-${KERNEL_VERSION}-1.x86_64.rpm      \
	echo KV=${KV} > ${TARGET}/root/kv.data
	cd ${TARGET}/usr/src/kernel/${KERNEL_VERSION}
	make modules_prepare
	popd
else
	# base kernel install (NK ~= 1)
	yum install -y --installroot=${TARGET} kernel kernel-devel kernel-headers   \
			kernel-tools kernel-tools-libs kernel-tools-libs-devel
fi

# common to all
yum install -y --installroot=${TARGET} dracut dracut-network                    \
                dracut-config-generic dracut-tools dracut-config-rescue

