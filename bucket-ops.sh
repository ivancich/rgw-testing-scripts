#!/bin/bash


cat <<EOF

bin/radosgw-admin bi list --bucket=reshard-test
bin/radosgw-admin bi get --bucket=reshard-test --object=myobj.9
bin/radosgw-admin bucket check --bucket=reshard-test


bin/radosgw-admin metadata get bucket:reshard-test  # get bucket entry-point

bin/radosgw-admin metadata list bucket.instance

bin/radosgw-admin metadata get bucket.instance:

e.g., bin/radosgw-admin metadata get bucket.instance:reshard-test:6717b904-e35b-42c9-b8bf-f950fb84e345.14109.1

s3cmd ls s3://reshard-test             # list bucket
s3cmd rm s3://reshard-test/myobj.9     # remove item from bucket
s3cmd rb -r --force s3://reshard-test  # remove entire bucket

bin/rados ls -p default.rgw.log -N reshard  # list reshard log objects
bin/rados ls -p default.rgw.buckets.index   # list shard objects

bin/rados rm -p default.rgw.buckets.index $(bin/rados ls -p default.rgw.buckets.index)

# remove all elements from bucket index pool
for f in $(bin/rados ls -p default.rgw.buckets.index) ; do
    bin/rados rm -p default.rgw.buckets.index $f
done

EOF
