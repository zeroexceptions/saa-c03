## Create a new bucket

```sh
aws s3api create-bucket --bucket zeroexceptions-acl --region us-east-1
```

## Turn of Block Public Access for ACLs

```sh
aws s3api put-public-access-block \
--bucket zeroexceptions-acl \
--public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

```sh
aws s3api get-public-access-block --bucket zeroexceptions-acl
```

## Change Bucket Ownership


```sh
aws s3api put-bucket-ownership-controls \
--bucket zeroexceptions-acl \
--ownership-controls="Rules=[{ObjectOwnership=BucketOwnerPreferred}]"
```

## To get the canonical ID
```sh
aws s3api list-buckets --query "Owner.ID" --output text
```

## Change ACLs to allow for a user in another AWS Account

```sh
aws s3api put-bucket-acl \
--bucket zeroexceptions-acl \
--access-control-policy file:///home/user/Desktop/aws_crs/s3/acls/policy.json
```

## Access Bucket from other account

```sh
touch bootcamp.txt
aws s3 cp bootcamp.txt s3://zeroexceptions-acl
aws s3 ls s3://zeroexceptions-acl
```

## Cleanup

```sh
aws s3 rm s3://zeroexceptions-acl/bootcamp.txt
aws s3 rb s3://zeroexceptions-acl
```