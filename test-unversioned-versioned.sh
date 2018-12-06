#!/bin/sh

greptext="--binary-file=text"
suffix=$(date +%H%M%S)

s/my-new-vstart
s/test-user-stats-multipart-mismatch.sh no >unversioned-${suffix}.out
../src/stop.sh

s/my-new-vstart
s/test-user-stats-multipart-mismatch.sh yes >versioned-${suffix}.out
../src/stop.sh

first=1
for f in $(ls -tr log-test-resharding* | tail -2) ;do
    if [ $first -eq 1 ] ;then
	grep $greptext EI_DEBUG $f >unversioned-${suffix}.err
	first=0
    else
	grep $greptext EI_DEBUG $f >versioned-${suffix}.err
    fi
done

bell
