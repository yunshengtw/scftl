#!/bin/bash

# just to make sure the OCSSD is not used by a file system
MNT=/tmp/fs

fusermount -u $MNT &>/dev/null
umount $MNT &>/dev/null
nvme lnvm remove -n nvme0n1-pblk &>/dev/null
mkdir -p raw &>/dev/null
for wr_interval in 1 16 256 2048
do
    stdbuf -o 0 ../randwr-sync $wr_interval 2>&1 1>/dev/null \
        | tee raw/sync-$wr_interval.log
    stdbuf -o 0 ../randwr-async $wr_interval 2>&1 1>/dev/null \
        | tee raw/async-$wr_interval.log
    ../fillone-vblk 1 1>/dev/null
    ../mkftl-vblk 1>/dev/null
    stdbuf -o 0 ../randwr-scftl $wr_interval 2>&1 1>/dev/null \
        | tee raw/scftl-$wr_interval.log
    nvme lnvm create -d nvme0n1 -n nvme0n1-pblk -t pblk
    stdbuf -o 0 ../randwr-pblk $wr_interval 2>&1 1>/dev/null \
        | tee raw/pblk-$wr_interval.log
    nvme lnvm remove -n nvme0n1-pblk
done
