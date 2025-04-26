# QNAP Kernel and Initrd

When connecting a disk drive to a LInux system that was used in a QNAP NAS, you might encounter the following error failing to active some LVM partitions:

```
WARNING: Unrecognised segment type tier-thin-pool
...
Internal error: LV segments corrupted in tp1.
```

This is not an actual error but missing features that QNAP has added to their kernel and tools for thin-provisioned LVM partitions.

While QNAP provides patched versions of the kernel and tools in their SourceForge site (https://sourceforge.net/projects/qosgpl/),
building a kernel and a suitable root filesystem is not as straight forward.

The kernel and ramdisk included in this repository provde an option to boot into a VM for backing up a QNAP partition
and have tested on a drive from a QTS-251 in a RAID-1 (mirrored) setup.
They are based on [QNAP's 5.2.3 release](https://sourceforge.net/projects/qosgpl/files/QNAP%20NAS%20GPL%20Source/QTS%205.2.3/) on SourceForge
and support the following target destinations for backing up a QNAP partition:

- local drive or partition
- network mounted NFS share
- remote system using rsync

This repository also includes the patches and scripts used to build the kernel and ramdisk. This might be useful for supporting other QNAP systems
or for addition additional kernel options.

For more details and instructions for using the kernel and ramdisk, and for building instructions,
visit [QNAP Disk Drive Recovery on Linux](https://www.industrialdreams.com/qnap-disk-drive-recovery-on-linux-part-i/)
