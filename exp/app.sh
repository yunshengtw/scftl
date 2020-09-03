#!/bin/bash

mkdir -p raw &>/dev/null
for FS in ext4-metadata ext4-data xv6fs-xlog-gcm xv6fs-xlog xv6fs-xflush xv6fs
do
	pushd ..
	./scripts/mount.sh $FS
	popd
	pushd ../bench
	./all.sh $FS
	popd
done
