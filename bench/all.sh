#!/bin/bash

if [[ $# -ne 1 ]]; then
	echo "usage: ./all.sh <file system>"
	exit 1
fi

echo "Running benchmarks for file system $1"

stdbuf -o 0 ./largefile.sh 5 | tee ../exp/raw/$1-largefile.log

stdbuf -o 0 ./smallfiles.sh 3 5 | tee ../exp/raw/$1-smallfiles.log

if [[ $1 == "ext4-metadata" ]]; then
	stdbuf -o 0 ./mailbench.sh 1 5 | tee ../exp/raw/$1-mailbench.log
else
	stdbuf -o 0 ./mailbench.sh 0 5 | tee ../exp/raw/$1-mailbench.log
fi

stdbuf -o 0 ./sqlite.sh 5 2>&1 | tee ../exp/raw/$1-sqlite.log
