#!/bin/bash

# Create a ramdisk from the sysroot created with create-sysroot.sh
#
# Usage:
#   create-ramdisk.sh <PATH> <RAMDISK>

if [ $# -ne 2 ]; then
	echo "usage: create-sysroot.sh <PATH> <RAMDISK>"
	exit 1
fi

SYSROOT=$1
RAMDISK=$2

# create ramdisk; link /sbin/init to /init

(cd $SYSROOT && find . -print0 | cpio --null --create --verbose --format=newc --owner root:root) | gzip --best > $RAMDISK
