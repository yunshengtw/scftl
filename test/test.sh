#!/bin/bash

if [[ $# -ne 1 ]]; then
	echo "usage: ./test.sh <duration (in minutes)>"
	exit 1
fi

rm -rf init.img
./mkftl-emu
./crash-test 10000 100 100 $1
./crash-test 10000 100 200000 $1
./crash-test 400000 2 20000 $1
./crash-test 5 100 1000 $1
