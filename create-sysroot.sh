#!/bin/bash

# Create a minimal root filesystem for mounting QNAP partitions
#
# Usage:
#   create-sysroot.sh <SYSROOT> <QTS>
#
# THe <QTS> argument is the full path to the QNAP QTS GPL sources:
#
#     ${QTS}/GPL_QTS/src/
#         linux-5.10
#         lvm2-2_02_138
#         thin-provisioning-tools-v0.4.1
#
# lvm2 and thin-provisioning-tools are already built when downloading them
# from the QNAP SourceForge page.
#
# The kernel must be patched and built including modules.
# Use modules_install with the INSTALL_MOD_PATH=modules option
# to install the modules locally in the linux-5.10/modules directory.

if [ $# -ne 2 ]; then
	echo "usage: create-sysroot.sh <SYSROOT> <QTS>"
	exit 1
fi

SYSROOT=`realpath $1`
QTSPATH=`realpath $2`/GPL_QTS

UBUNTU_TOOLS="busybox rsync"
QTS_TOOLS="lvm pdata_tools"
QTS_DIRS="lvm2 thin-provisioning-tools"
KERNELPATH=$QTSPATH/src/linux-5.10
MODULESPATH=$KERNELPATH/modules

# sanity check

if [ -e $SYSROOT ]; then
	echo "SYSROOT already exists"
	exit -1
fi

if [ -z $QTSPATH ]; then
	echo "QTSPATH undefined"
	exit -1
fi

if [ -z $KERNELPATH ]; then
	echo "Kernel missing in $KERNELPATH"
	exit -1
fi

if [ -z $MODULESPATH ]; then
	echo "Modules expected to be installed under KERNELPATH/modules"
	exit -1
fi

# check that ubuntu tools have been installed

for f in $UBUNTU_TOOLS; do
	if ! which -s $f; then
		echo $f not installed
		exit -1
	fi
done

# check that QTS tools have been installed

for f in $QTS_DIRS; do
	if ! ls -U $QTSPATH/src/$f-* 1> /dev/null 2>&1; then
		echo $QTSPATH/src/$f not found
		exit -1
	fi
done

# create sysroot and various directories

echo "Creating sysroot under $SYSROOT"

mkdir --parents $SYSROOT/{bin,dev,etc,etc/init.d,etc/lvm,mnt,proc,sbin,sys,tmp,usr/bin,usr/lib,usr/sbin,var,var/run}

# FIXME for d in $DIRS; do mkdir -p $SYSROOT/$d; done
ln -s usr/lib $SYSROOT/lib
ln -s usr/lib $SYSROOT/lib64

# copy Ubuntu tools

for f in $UBUNTU_TOOLS; do cp -a `which $f` $SYSROOT/sbin/$f; done

# special handling of some tools

for f in $UBUNTU_TOOLS $QTS_TOOLS; do

	# create symbolic links for busybox commands, including /init for any ramdisk
	if [ $f == "busybox" ]; then
		for file in `$SYSROOT/sbin/busybox --list-full`; do
		       	ln -s /sbin/busybox $SYSROOT/$file;
	       	done
		echo "BUSYBOX"

		ln -s /sbin/busybox $SYSROOT/init
	fi

	# create symbolic links for lvm commands
	if [ $f == "lvm" ]; then
		make -C $QTSPATH/src/lvm2*/tools/ install DESTDIR=$SYSROOT/ prefix=
		make -C $QTSPATH/src/lvm2*/libdm/ install DESTDIR=$SYSROOT/ prefix=
		make -C $QTSPATH/src/lvm2*/daemons/ install DESTDIR=$SYSROOT/ prefix=
	fi

	# create symbolic links for thin-provisioning-tools
	if [ $f == "pdata_tools" ]; then
		cp -a $QTSPATH/src/thin-provisioning-tools*/bin/* $SYSROOT/sbin
	fi
done

# copy required libraries 

for f in $UBUNTU_TOOLS $QTS_TOOLS; do

       	LD_LIBRARY_PATH=$SYSROOT/lib/ ldd $SYSROOT/sbin/$f | awk -v sysroot=${SYSROOT} '
	function copy(name) {
	        print "copy library: " name
		if (name !~ /linux-vdso/) {
			basedir=gensub(/\/[^\/]*$/, "\\1", "g", name); system("mkdir -p " sysroot basedir);
			system("cp -R -H " name "* " sysroot basedir)
		}
	}
	NF == 4 { copy($3) };
	NF == 2 { copy($1) };
	'
done

# create thin tool links to pdata_tools

THIN_TOOLS="think_check thin_dump thin_check thin_repair thin_restore thin_rmap thin_metadata_size"
for f in $THIN_TOOLS; do
	ln -s pdata_tools $SYSROOT/sbin/$f
done

# copy dm-* modules

KERNELRELEASE=`cat $KERNELPATH/include/config/kernel.release`
MODULESDIR=lib/modules/$KERNELRELEASE

mkdir -p $SYSROOT/$MODULESDIR
cp -a $MODULESPATH/$MODULESDIR/dm* $SYSROOT/$MODULESDIR

# setup rootfs

cat << EOF > $SYSROOT/etc/init.d/rcS
#! /bin/sh
/bin/mount -a
/sbin/depmod -a
/bin/mkdir /tmp/lvm
/bin/ln -s /tmp/lvm /var/run/lvm
/sbin/lvmetad
EOF
chmod +x $SYSROOT/etc/init.d/rcS

cat << EOF > $SYSROOT/etc/inittab
::sysinit:/etc/init.d/rcS
::askfirst:-/bin/sh
EOF

cat << EOF > $SYSROOT/etc/fstab
# file system  mount-point  type   options          dump  fsck
#                                                         order

proc           /proc        proc   defaults         0     0
sysfs          /sys         sysfs  defaults         0     0
dev            /dev         devtmpfs deftauls       0     0
EOF
