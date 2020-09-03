#!/bin/bash

if [[ $# -ne 1 ]]; then
	echo "usage: ./largefile.sh <# of iteration>"
	exit 1
fi

MNT=/tmp/fs

gcc largefile.c -o largefile
for i in $(seq 1 $1); do
	rm -rf $MNT/*
	DIR=$MNT/$(date +%s%N)
	mkdir $DIR
	sync && sleep 1
	./largefile $DIR
done
