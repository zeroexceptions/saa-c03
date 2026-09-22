### create a copy of AMI

```sh
aws ec2 create-image --instance-id i-0a49b5e9df398d21c --name "my-ami-99"
```

source that new ami into another region

```sh
aws ec2 copy-image \
    --source-image-id ami-097e4d00dcdd4565d \
    --source-region us-east-1 \
    --region us-west-2 \
    --name "My Copied AMI Name" \
    --description "Description of my copied AMI" \
    --encrypted
```
