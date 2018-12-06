#!/usr/bin/python

# perform a multipart upload where a single part is uploaded twice
import boto3
import logging
import sys

bucket = sys.argv[1]
filename = sys.argv[2]
key = sys.argv[3]

# endpoint and keys from vstart
endpoint='http://127.0.0.1:8000'
access_key='0555b35654ad1656d804'
secret_key='h7GhxuBLTrlhVUyxSPUKUV8r/2EI4ngqJxD7iBdBYLhwluN30JaT3Q=='

s3 = boto3.resource('s3',
        endpoint_url=endpoint,
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key)

bucket = s3.Bucket(bucket)
bucket.create()

obj = bucket.Object(key)
upload = obj.initiate_multipart_upload()

parts = []
part = upload.Part(1)

with open(filename, 'rb') as body:
    part.upload(Body=body)
