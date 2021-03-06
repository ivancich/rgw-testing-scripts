#!/bin/bash

pool=myrgwpool
bucket=reshard-test
object=myobj
host="localhost:8000"
count=60
quiet="-q"

errlog="log-test-resharding-$(date +%d%H%M).txt"

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

dump_bucket_info() {
    for o in $(bin/radosgw-admin metadata list bucket.instance 2>>$errlog | jq ".[]" | sed 's/[",]/ /g') ; do
	echo "METADATA FOR $o"
	bin/radosgw-admin metadata get bucket.instance:$o 2>>$errlog
    done
}

echo "The quick brown fox jumped over the lazy dogs." >$object

# bin/radosgw-admin pool rm --pool=$pool
# bin/radosgw-admin pool add --pool=$pool

echo "Building up..."
s3cmd $quiet --host=$host mb s3://${bucket} 2>>$errlog

for i in $(seq $count) ; do
    cp $object ${object}.${i}
    s3cmd $quiet put --host=$host ${object}.${i} s3://${bucket} 2>>$errlog
    rm -f ${object}.${i}
done
rm -f $object

if false ;then
    dump_bucket_info
fi

echo BEFORE RESHARD

# bin/ceph osd lspools
# bin/radosgw-admin bi get                     retrieve bucket index object entries

# bin/rados ls -p default.rgw.log -N reshard
# bin/rados rm -p default.rgw.log -N reshard $(bin/rados ls -p default.rgw.log -N reshard)

# bin/radosgw-admin bi put                     store bucket index object entries
# bin/radosgw-admin bi list                    list raw bucket index entries
# bin/radosgw-admin bi purge                   purge bucket index entries

if true ;then
    echo "BUCKET INFO OBJECTS"
    list_bucket_infos
    echo "BUCKET INDEX OBJECTS"
    list_bucket_indexes
    echo "===="
fi

if false ;then
    echo Reshard Locks BEFORE
    bin/rados ls -p default.rgw.log -N reshard 2>>$errlog
fi

starttime=$(date)

if false ;then
    (sleep 20 ; reshard_immediate 10) &
fi

if true ;then
    reshard_immediate 9
fi

sleep 10

if false ;then
    (sleep 20 ; reshard_immediate 15) &
fi

if false ;then
    reshard_scheduled 14
fi

endtime=$(date)

echo AFTER RESHARD

if true ;then
    echo "BUCKET INFO OBJECTS"
    list_bucket_infos
    echo "BUCKET INDEX OBJECTS"
    list_bucket_indexes
    echo "===="
fi

if false ;then
    echo Reshard Locks AFTER
    bin/rados ls -p default.rgw.log -N reshard 2>>$errlog
    echo "===="
fi

if false ;then
    dump_bucket_info
fi

if false ;then
    echo "Cleaning up..."
    s3cmd $quiet rb -r --force s3://${bucket} 2>>$errlog
    clean_indexes
fi

echo $starttime
echo $endtime

echo Done
