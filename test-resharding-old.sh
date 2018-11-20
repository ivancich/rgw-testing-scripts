#!/bin/bash

pool=myrgwpool
bucket=reshard-test
object=myobj
host="localhost:8000"
count=60
quiet="-q"

list() {
    s3cmd ls --host=$host s3://${bucket} | sed 's/^.* //'
}

clean_reshard_locks() {
    bin/rados rm -p default.rgw.log -N reshard \
	      $(bin/rados ls -p default.rgw.log -N reshard)
}

clean_indexes() {
    bin/rados rm -p default.rgw.buckets.index $(bin/rados ls -p default.rgw.buckets.index)
}

reshard_immediate() {
    if [ $# -ne 1 ] ;then
	echo "Error: reshard_immediate needs argument"
	exit 1
    fi
    if true ; then
	bin/radosgw-admin bucket reshard --bucket=${bucket} --num-shards=$1
    else
	echo "run bucket reshard --bucket=${bucket} --num-shards=$1"
	gdb bin/radosgw-admin
    fi
}

reshard_scheduled() {
    if [ $# -ne 1 ] ;then
	echo "Error: reshard_scheduled needs argument"
	exit 1
    fi
    bin/radosgw-admin reshard add --bucket=${bucket} --num-shards=$1
    bin/radosgw-admin reshard process
}

dump_bucket_info() {
    for o in $(bin/radosgw-admin metadata list bucket.instance | jq ".[]" | sed 's/[",]/ /g') ; do
	echo "METADATA FOR $o"
	bin/radosgw-admin metadata get bucket.instance:$o
    done
}

echo "The quick brown fox jumped over the lazy dogs." >$object

# bin/radosgw-admin pool rm --pool=$pool
# bin/radosgw-admin pool add --pool=$pool

echo "Building up..."
s3cmd $quiet --host=$host mb s3://${bucket}

for i in $(seq $count) ; do
    cp $object ${object}.${i}
    s3cmd $quiet put --host=$host ${object}.${i} s3://${bucket}
    rm -f ${object}.${i}
done
rm -f $object

dump_bucket_info

# bin/ceph osd lspools
# bin/radosgw-admin bi get                     retrieve bucket index object entries

# bin/rados ls -p default.rgw.log -N reshard
# bin/rados rm -p default.rgw.log -N reshard $(bin/rados ls -p default.rgw.log -N reshard)

# bin/radosgw-admin bi put                     store bucket index object entries
# bin/radosgw-admin bi list                    list raw bucket index entries
# bin/radosgw-admin bi purge                   purge bucket index entries

bin/rados -p default.rgw.buckets.index ls

echo Reshard Locks BEFORE
bin/rados ls -p default.rgw.log -N reshard
echo "===="

starttime=$(date)

if false ;then
    (sleep 20 ; reshard_immediate 10) &
fi

if true ;then
    reshard_immediate 9;
fi

sleep 10

if false ;then
    (sleep 20 ; reshard_immediate 15) &
fi

if false ;then
    reshard_scheduled 14
fi

endtime=$(date)

echo Reshard Locks AFTER
bin/rados ls -p default.rgw.log -N reshard
echo "===="

dump_bucket_info

if false ;then
    echo "Cleaning up..."
    s3cmd $quiet rb -r --force s3://${bucket}
    clean_indexes
fi

echo $starttime
echo $endtime

echo Done
