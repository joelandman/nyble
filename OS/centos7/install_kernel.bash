#!/bin/bash -x
set -e

pwd

[[ -e kernel.data ]] && . ./kernel.data

echo TARGET       = $TARGET
echo URL          = $KERNEL_URL
echo K VERS       = $KERNEL_VERSION
echo KV           = $KV
echo NYBLE_KERNEL = $NK
echo DISTRO       = $DISTRO


# thanks to yum/rpm insanity, you need this ...
cp -f /etc/resolv.conf ${TARGET}/etc/resolv.conf

if [[ $NK -eq 1 ]]; then
	# use custom kernel
	pushd .
	# remove old kernel
	rpm -ev --nodeps `rpm -qa --root=${TARGET} | grep kernel` --root=${TARGET}
	mkdir ${TARGET}/root/k
	cd ${TARGET}/root/k
	wget ${KERNEL_URL}/kernel-${KERNEL_VERSION}-1.x86_64.rpm
	wget ${KERNEL_URL}/kernel-headers-${KERNEL_VERSION}-1.x86_64.rpm
	wget ${KERNEL_URL}/kernel-devel-${KERNEL_VERSION}-1.x86_64.rpm
	rpm -ivh --nodeps --force *.rpm --root=${TARGET}
	cd ${TARGET}/root
	rm -rf k
  	#rpm -ivh ${KERNEL_URL}/kernel-${KERNEL_VERSION}-1.x86_64.rpm 		\
	#	 ${KERNEL_URL}/kernel-headers-${KERNEL_VERSION}-1.x86_64.rpm    \
	#	 ${KERNEL_URL}/kernel-devel-${KERNEL_VERSION}-1.x86_64.rpm    \
	#	 --force --nodeps --root=${TARGET}
		# kernel-devel will make ramdisk very large
#		 ${KERNEL_URL}/kernel-devel-${KERNEL_VERSION}-1.x86_64.rpm      \
	echo KV=${KV} > ${TARGET}/root/kv.data
	cd ${TARGET}/usr/src/kernels/${KERNEL_VERSION}
	make modules_prepare
	popd
else
	# base kernel install (NK ~= 1)
	yum install -y --installroot=${TARGET} kernel kernel-devel kernel-headers   \
			kernel-tools kernel-tools-libs kernel-tools-libs-devel
	rpm -qa | grep kernel  | perl -lane 's/kernel-.*?(\d.*?).x86_64/$1/g;print' | sort | uniq > k.d
	cat k.d | perl -lane 's/\.el7//g;print' > kv.d

	# create the kernel.data
	echo DISTRO=${DISTRO}	> ${TARGET}/root/meta.data
	echo TARGET=${TARGET}
	echo NK=0		>>${TARGET}/root/meta.data
	echo KERNEL_URL=	>>${TARGET}/root/meta.data
	echo KERNEL_VERSION=$(cat k.d) >>${TARGET}/root/meta.data
	echo KV=$(cat kv.d | perl -lane 's/^(\d+\.\d+)(.*?)$/$1/g;print') >>${TARGET}/root/meta.data
fi

# common to all
yum install -y --installroot=${TARGET} dracut dracut-network                    \
                dracut-config-generic dracut-tools dracut-config-rescue 

# clean up name servers ...
rm -f ${TARGET}/etc/resolv.conf
