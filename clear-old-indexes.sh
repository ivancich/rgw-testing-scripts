#!/bin/bash

pool=default.rgw.buckets.index

echo BEFORE

bin/rados -p $pool ls

bin/rados -p $pool rm $(bin/rados -p $pool ls)

echo AFTER

bin/rados -p $pool ls
