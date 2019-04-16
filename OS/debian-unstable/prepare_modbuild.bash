#!/bin/bash -x

pwd
. /root/kernel.data

echo K VERS = $KERNEL_VERSION
echo NYBLE K= $NK

if [[ $NK -eq 1 ]]; then
	pushd .
	#rm -f /lib/modules/${KERNEL_VERSION}/build
	#ln -s /usr/src/linux-${KERNEL_VERSION} /lib/modules/${KERNEL_VERSION}/build
	cd /lib/modules/${KERNEL_VERSION}/build
	cp .config /tmp
	make clean
	cp /tmp/.config .
	make modules_prepare
	popd
fi
