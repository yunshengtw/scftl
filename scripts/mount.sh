#!/bin/bash

if [ -z $1 ]; then
	echo "Specify which file system to mount:"
	echo "xv6fs xv6fs-xflush xv6fs-xlog xv6fs-xlog-gcm"
	echo "ext4-sync ext4-data ext4-metadata"
	exit 1
fi

MNT=/tmp/fs

# sometimes an unclean FUSE shutdown cannot be cleaned with umount
fusermount -u $MNT &>/dev/null
umount $MNT &>/dev/null
nvme lnvm remove -n nvme0n1-pblk &>/dev/null
rm -rf $MNT
mkdir -p $MNT
case $1 in
xv6fs)
	echo "Mounting xv6fs"
	./xv6fs $MNT -f -d -s &>/dev/null &
	while [[ $(mount -l | grep xv6 | wc -l) -eq "0" ]]; do
		sleep 5
	done
	echo "The xv6 file system is ready."
	;;
xv6fs-xflush)
	echo "Mounting xv6fs-xflush"
	./xv6fs-xflush $MNT -f -d -s &>/dev/null &
	while [[ $(mount -l | grep xv6 | wc -l) -eq "0" ]]; do
		sleep 5
	done
	echo "The xv6 file system is ready."
	;;
xv6fs-xlog)
	echo "Mounting xv6fs-xlog"
	# FEMU doesn't change the content of erased block to all 1;
	# so we manually fill the first block with all 1.
	./fillone-vblk 1 &>/dev/null
	./mkftl-vblk &>/dev/null
	./xv6fs-xlog $MNT -f -d -s &>/dev/null &
	while [[ $(mount -l | grep xv6 | wc -l) -eq "0" ]]; do
		sleep 5
	done
	echo "The xv6 file system is ready."
	;;
xv6fs-xlog-gcm)
	echo "Mounting xv6fs-xlog-gcm"
	# FEMU doesn't change the content of erased block to all 1;
	# so we manually fill the first block with all 1.
	./fillone-vblk 1 &>/dev/null
	./mkftl-vblk &>/dev/null
	./xv6fs-xlog-gcm $MNT -f -d -s &>/dev/null &
	while [[ $(mount -l | grep xv6 | wc -l) -eq "0" ]]; do
		sleep 5
	done
	echo "The xv6 file system is ready."
	;;
ext4-sync)
	echo "Mounting ext4-sync"
	nvme lnvm create -d nvme0n1 -n nvme0n1-pblk -t pblk
	echo "y" | mkfs.ext4 /dev/nvme0n1-pblk
	mount /dev/nvme0n1-pblk $MNT -o data=journal,sync
	sync
	# Prevent mkfs.ext4 from interfering the experiments
	sleep 30
	echo "The ext4 file system is ready."
	;;
ext4-data)
	echo "Mounting ext4-data"
	nvme lnvm create -d nvme0n1 -n nvme0n1-pblk -t pblk
	echo "y" | mkfs.ext4 /dev/nvme0n1-pblk
	mount /dev/nvme0n1-pblk $MNT -o data=journal,journal_async_commit
	sync
	# Prevent mkfs.ext4 from interfering the experiments
	sleep 30
	echo "The ext4 file system is ready."
	;;
ext4-metadata)
	echo "Mounting ext4-metadata"
	nvme lnvm create -d nvme0n1 -n nvme0n1-pblk -t pblk
	echo "y" | mkfs.ext4 /dev/nvme0n1-pblk
	mount /dev/nvme0n1-pblk $MNT -o data=ordered
	sync
	# Prevent mkfs.ext4 from interfering the experiments
	sleep 30
	echo "The ext4 file system is ready."
	;;
*)
	echo "Unrecognized file system"
	;;
esac
