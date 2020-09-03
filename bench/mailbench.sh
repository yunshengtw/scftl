#!/bin/bash

if [[ $# -ne 2 ]]; then
	echo "usage: ./mailbench.sh <0 | 1> <# of iteration>"
 	exit 1
fi

if [[ $1 == "0" ]]; then
	sed --in-place 's/  fdatasync/  \/\/fdatasync/g' sv6/bin/mail-enqueue.cc
	sed --in-place 's/  fdatasync/  \/\/fdatasync/g' sv6/bin/mail-deliver.cc
elif [[ $1 == "1" ]]; then
	sed --in-place 's/  \/\/fdatasync/  fdatasync/g' sv6/bin/mail-enqueue.cc
	sed --in-place 's/  \/\/fdatasync/  fdatasync/g' sv6/bin/mail-deliver.cc
else
	echo "0: no fdatasync; 1: use fdatasync"
	exit 1
fi

MNT=/tmp/fs

make -C sv6 HW=linux o.linux/bin/mail{bench,-deliver,-enqueue,-qman}
for i in $(seq 1 $2); do
	rm -rf $MNT/*
	DIR=$MNT/$(date +%s%N)
	mkdir $DIR
	pushd ./sv6/o.linux/bin
	sync && sleep 1
	./mailbench -a all $DIR 1
	popd
	rm $DIR/mail/user/new/*
done
