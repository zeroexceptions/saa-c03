#!/usr/bin/env bash
set -euo pipefail

# Deploys template.yml as a CloudFormation stack.
# Credentials/region come from the environment (AWS_PROFILE via direnv),
# same as the Ruby scripts in ../ruby-sdk.

STACK_NAME="s3-practice-stack"
TEMPLATE_FILE="$(dirname "$0")/template.yml"
REGION="${AWS_REGION:-us-east-1}"

echo "Deploying stack '${STACK_NAME}' from ${TEMPLATE_FILE} in ${REGION}..."

aws cloudformation deploy \
  --stack-name "${STACK_NAME}" \
  --template-file "${TEMPLATE_FILE}" \
  --region "${REGION}"

echo "Stack deployed. Resources:"
aws cloudformation describe-stack-resources \
  --stack-name "${STACK_NAME}" \
  --region "${REGION}" \
  --query "StackResources[].{Logical:LogicalResourceId,Physical:PhysicalResourceId,Status:ResourceStatus}" \
  --output table
