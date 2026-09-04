## Create an s3 bucket using this command

```sh
aws s3 mb s3://zeroexceptions-encryption

```

### create a temp.txt file and move to s3

```sh
touch temp.txt
```

```sh
aws s3 cp temp.txt s3://zeroexceptions-encryption
```

### server side encryption with aws managed key

```sh
aws s3api put-object \
  --bucket zeroexceptions-encryption \
  --key temp.txt \
  --body temp.txt \
  --server-side-encryption aws:kms
```
