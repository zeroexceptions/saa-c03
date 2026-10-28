# Create a bucket for cloudtrail logs

aws s3 mb s3://zeroexception-cloudtrail

# Create bucket policy to allow cloud trail to put to bucket

aws s3api put-bucket-policy --bucket zeroexception-cloudtrail --policy file://bucket-policy.json

# Create Trail
aws cloudtrail create-trail \
--name MyTrail \
--s3-bucket-name zeroexception-cloudtrail \
--region us-east-1

# Start Logging

aws cloudtrail start-logging --name MyTrail
