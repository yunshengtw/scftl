#!/bin/bash

echo "Checking snapshot consistency"
agda SnapshotConsistency.agda &>/dev/null
if [[ $? -eq 0 ]]; then
	echo "Pass"
else
	echo "Fail"
fi

