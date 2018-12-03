#!/bin/bash

pool=myrgwpool
bucket=bucket1
versioned=1
object=myobj
host="localhost:8000"
count=10
quiet="-q"

errlog="log-test-resharding-$(date +%d%H%M%S).txt"

list() {
    s3cmd ls --host=$host s3://${bucket} 2>>$errlog | sed 's/^.* //'
}

list_bucket_infos() {
    bin/rados -p default.rgw.meta -N root ls 2>>$errlog
}

list_bucket_indexes() {
    bin/rados -p default.rgw.buckets.index ls 2>>$errlog
}

clean_reshard_locks() {
    bin/rados rm -p default.rgw.log -N reshard \
	      $(bin/rados ls -p default.rgw.log -N reshard 2>>$errlog) 2>>$errlog
}

clean_indexes() {
    bin/rados rm -p default.rgw.buckets.index $(bin/rados ls -p default.rgw.buckets.index 2>>$errlog) 2>>$errlog
}

reshard_immediate() {
    if [ $# -ne 1 ] ;then
	echo "Error: reshard_immediate needs argument"
	exit 1
    fi
    if true ; then
	bin/radosgw-admin bucket reshard --bucket=${bucket} --num-shards=$1 2>>$errlog
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
    bin/radosgw-admin reshard add --bucket=${bucket} --num-shards=$1 2>>$errlog
    bin/radosgw-admin reshard process 2>>$errlog
}

list_bucket_entrypoints() {
    bin/radosgw-admin metadata list bucket
}

list_bucket_metadata() {
    bin/radosgw-admin metadata list bucket.instance
}

dump_bucket_info() {
    for o in $(bin/radosgw-admin metadata list bucket.instance 2>>$errlog | jq ".[]" | sed 's/[",]/ /g') ; do
	echo "METADATA FOR $o"
	bin/radosgw-admin metadata get bucket.instance:$o 2>>$errlog
    done
}

bucket_stats() {
    bin/radosgw-admin bucket stats --bucket $bucket
}

echo "The quick brown fox jumped over the lazy dogs." >$object


echo "Building up..."
s3cmd $quiet --host=$host mb s3://${bucket} 2>>$errlog

if [ "$versioned" == 1 ] ;then
    echo making bucket versioned
    bucket-enable-versioning.sh $bucket
fi

for i in $(seq $count) ; do
    ln $object ${object}.${i}
    s3cmd $quiet put --host=$host ${object}.${i} s3://${bucket} 2>>$errlog
    rm -f ${object}.${i}
done
rm -f $object

bucket_stats
# list_bucket_metadata
# list_bucket_entrypoints

echo "## resharding"
reshard_immediate 4

bucket_stats
# list_bucket_metadata
# list_bucket_entrypoints

echo "## replacing object.3"
echo "foobar" >${object}.3
s3cmd $quiet put --host=$host ${object}.3 s3://${bucket} 2>>$errlog
rm -f ${object}.3

bucket_stats

echo "## resharding"
reshard_immediate 5

bucket_stats

echo "## removing object.4"
s3cmd $quiet rm s3://${bucket}/${object}.4 2>>$errlog

bucket_stats

echo "## resharding"
reshard_immediate 6

bucket_stats

if false ;then
    echo "Cleaning up..."
    s3cmd $quiet rb -r --force s3://${bucket} 2>>$errlog
    clean_indexes
fi

# list_bucket_metadata
# list_bucket_entrypoints
