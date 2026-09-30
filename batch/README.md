### the commands in this read me doesn't work properly, and gave error




# Build Image
docker build -t  app .

# Register Job

aws batch register-job-definition \
--job-definition-name square-job \
--type container \
--container-properties '{
    "image": "546208175646.dkr.ecr.us-east-1.amazonaws.com/square:latest",
    "vcpus": 1, 
    "memory": 128
}'

https://docs.aws.amazon.com/cli/latest/reference/batch/register-job-definition.html#examples

# Create Compute Env

aws batch create-compute-environment --compute-environment-name my-compute-env \
--type MANAGED \
--compute-resources minvCpus=0,desiredvCpus=1,maxvCpus=1,instanceTypes=t3.micro,subnets=subnet-12345678,securityGroupIds=sg-12345678 \
    --service-role arn:aws:iam::123456789012:role/service-role/AWSServiceRoleForBatch

# Create Queue


aws batch create-job-queue \
--job-queue-name my-job-queue \
--state ENABLED \
--priority 1 \
--compute-environment-order '[
  {
    "order": 1,
    "computeEnvironment": "arn:aws:batch:us-east-1:546208175646:compute-environment/MyCompute"
  }
]'

# Submit Job

aws batch submit-job \
    --job-name my-job \
    --job-definition square-job \
    --job-queue my-job-queue





### ELK: elastic searc, logstash, kibana