#!/bin/bash

if [[ $# -ne 2 ]]; then
	echo "usage: ./smallfiles.sh <duration (sec)> <# of iteration>"
	exit 1
fi

MNT=/tmp/fs

gcc smallfiles.c -o smallfiles
for i in $(seq 1 $2); do
	rm -rf $MNT/*
	DIR=$MNT/$(date +%s%N)
	mkdir $DIR
	sync && sleep 1
	./smallfiles $DIR $1
done
