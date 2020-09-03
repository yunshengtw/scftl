#!/bin/bash

if [[ $# -ne 1 ]]; then
	echo "usage: ./sqlite.sh <# of iteration>"
	exit 1
fi

MNT=/tmp/fs
DB=$MNT/test.db

for i in $(seq 1 $1); do
	rm -rf $MNT/*
	touch $DB
	sync && sleep 1
	time -p (sudo python2 mini-sql.py | sqlite3 $DB)
done
