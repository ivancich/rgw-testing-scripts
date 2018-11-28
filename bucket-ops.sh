#!/bin/bash


cat <<EOF

RADOSGW-ADMIN

bin/radosgw-admin bi list --bucket=reshard-test
bin/radosgw-admin bi get --bucket=reshard-test --object=myobj.9
bin/radosgw-admin bucket check --bucket=reshard-test


bin/radosgw-admin metadata get bucket:reshard-test  # get bucket entry-point

bin/radosgw-admin metadata list bucket.instance

bin/radosgw-admin metadata get bucket.instance:

e.g., bin/radosgw-admin metadata get bucket.instance:reshard-test:6717b904-e35b-42c9-b8bf-f950fb84e345.14109.1

bin/radosgw-admin bucket reshard --bucket=reshard-test --num-shards=16

bin/radosgw-admin reshard stale-instances list
bin/radosgw-admin reshard stale-instances delete


== S3CMD ==

s3cmd ls s3://reshard-test             # list bucket
s3cmd rm s3://reshard-test/myobj.9     # remove item from bucket
s3cmd rb -r --force s3://reshard-test  # remove entire bucket

== RADOS ==

bin/rados -p default.rgw.meta --all ls 2>/dev/null    # list all objs in all ns
bin/rados -p default.rgw.meta -N root ls 2>/dev/null  # list bucket info objs

bin/rados ls -p default.rgw.log -N reshard  # list reshard log objects
bin/rados ls -p default.rgw.buckets.index   # list shard objects

bin/rados rm -p default.rgw.buckets.index $(bin/rados ls -p default.rgw.buckets.index)

# remove all elements from bucket index pool
for f in $(bin/rados ls -p default.rgw.buckets.index) ; do
    bin/rados rm -p default.rgw.buckets.index $f
done

EOF
