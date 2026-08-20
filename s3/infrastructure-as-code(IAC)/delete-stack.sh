#!/usr/bin/env bash

STACK_NAME="s3-practice-stack"
TEMPLATE_FILE="$(dirname "$0")/template.yml"
REGION="${AWS_REGION:-us-east-1}"

echo "Deleting stack '${STACK_NAME}' in ${REGION}..."

aws cloudformation delete-stack \
  --stack-name "${STACK_NAME}" \
  --region "${REGION}"

echo "Waiting for stack deletion to complete..."
aws cloudformation wait stack-delete-complete \
  --stack-name "${STACK_NAME}" \
  --region "${REGION}"

echo "Stack '${STACK_NAME}' deleted."
