#!/bin/bash -x
set -e

[[ -e kernel.data ]] && . ./kernel.data


pwd

echo TARGET       = $TARGET
echo URL          = $KERNEL_URL
echo K VERS       = $KERNEL_VERSION
echo KV           = $KV
echo NYBLE_KERNEL = $NK
echo DISTRO       = $DISTRO


rpm -qa --installroot=${TARGET}  | grep kernel  | perl -lane 's/kernel-.*?(\d.*?).x86_64/$1/g;print' | sort | uniq > k.d
cat k.d | perl -lane 's/\.el7//g;print' > kv.d

# create the kernel.data
echo DISTRO=${DISTRO}	> ${TARGET}/root/kernel.data2
echo NK=${NK}		>>${TARGET}/root/kernel.data2
echo KERNEL_URL=${KERNEL_URL}	>>${TARGET}/root/kernel.data2
echo KERNEL_VERSION=$(cat k.d) >>${TARGET}/root/kernel.data2
echo KV=$(cat kv.d | perl -lane 's/^(\d+\.\d+)(.*?)$/$1/g;print') >>${TARGET}/root/kernel.data2
	
