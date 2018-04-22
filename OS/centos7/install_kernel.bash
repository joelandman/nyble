#!/bin/bash -x

pwd
. ./kernel.data

echo TARGET = $TARGET
echo URL    = $KERNEL_URL
echo K VERS = $KERNEL_VERSION
echo KV     = $KV
echo NYBLE K= $NK
echo DISTRO = $DISTRO

# common to all
yum install -y --installroot=${TARGET} dracut dracut-network 							\
		dracut-config-generic dracut-tools dracut-config-rescue
cp -fv get_kern.pl ${TARGET}/root

if [[ $NK -eq 1 ]]; then
	# use custom kernel
	pushd .
	mkdir ${TARGET}/root/k
	cd ${TARGET}/root/k
  wget -c ${KERNEL_URL}/kernel-${KERNEL_VERSION}-1.x86_64.rpm 					\
					${KERNEL_URL}/kernel-headers-${KERNEL_VERSION}-1.x86_64.rpm		\
					${KERNEL_URL}/kernel-devel-${KERNEL_VERSION}-1.x86_64.rpm
	chroot ${TARGET} rpm -ivh --force --nodeps \
					/root/k/kernel-headers-${KERNEL_VERSION}-1.x86_64.rpm \
					/root/kernel-${KERNEL_VERSION}-1.x86_64.rpm \
					/root/kernel-devel-${KERNEL_VERSION}-1.x86_64.rpm
	echo KV=${KV} > ${TARGET}/root/kv.data
	popd
	rm -rf ${TARGET}/root/k
else
	# base kernel install (NK ~= 1)
	yum install -y --installroot=${TARGET} kernel kernel-devel kernel-headers   \
			kernel-tools kernel-tools-libs kernel-tools-libs-devel
fi
