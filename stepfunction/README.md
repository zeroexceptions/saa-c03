
# Step Functions: validate an order and save a receipt to S3

This lab connects Amazon Step Functions, AWS Lambda, and Amazon S3.

```text
Execution input
   |
   v
validate-order Lambda
   |
   v
Is the order valid?
   |-- no  --> workflow fails
   |
   `-- yes --> write-receipt Lambda --> S3 receipt JSON --> success
```

## Resources in this lab

| Resource | Name | Purpose |
| --- | --- | --- |
| S3 bucket | `my-step-fn-9909` | Stores receipt JSON files. |
| Lambda | `validate-order` | Checks that an order has the required fields. |
| Lambda | `write-receipt` | Creates a receipt JSON file in S3. |
| State machine | `order-receipt-workflow` | Coordinates the two Lambda functions. |

The examples use the `us-east-1` Region.

```bash
AWS_REGION="us-east-1"
BUCKET_NAME="my-step-fn-9909"
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
```

## 1. Create the S3 bucket

The bucket already exists for this lab. To create one in `us-east-1`, use a globally unique name:

```bash
aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$AWS_REGION"
```

Receipts are stored under this prefix:

```text
s3://my-step-fn-9909/receipts/
```

## 2. Lambda functions

### `validate-order`

Source: [validate-order/order.py](validate-order/order.py)

Its handler is `order.lambda_handler` because the file is named `order.py` and the function inside it is named `lambda_handler`.

The Lambda receives the complete Step Functions input, for example:

```json
{
  "orderId": "order-1001",
  "customerEmail": "learner@example.com",
  "amount": 49.99
}
```

It checks for `orderId`, `customerEmail`, and `amount`, and verifies that `amount` is greater than zero. It returns:

```json
{
  "isValid": true,
  "reason": null
}
```

or, for invalid input:

```json
{
  "isValid": false,
  "reason": "Missing/invalid fields: ['amount']"
}
```

### `write-receipt`

Source: [write-receipt/receipt.py](write-receipt/receipt.py)

Its handler is `receipt.lambda_handler`. It receives the order fields plus a Step Functions execution ID, creates a JSON receipt, and uploads it with `s3:PutObject`.

Example object created:

```text
s3://my-step-fn-9909/receipts/order-1001.json
```

This Lambda needs an environment variable:

```text
OUTPUT_BUCKET=my-step-fn-9909
```

## 3. IAM roles and policies

Each AWS service assumes its own role. A Lambda has **one execution role**, but that role can have multiple policies.

| Role | Trusted service | Permissions |
| --- | --- | --- |
| `lambda-validate-order-role` | `lambda.amazonaws.com` | CloudWatch Logs only. |
| `lambda-write-receipt-role` | `lambda.amazonaws.com` | CloudWatch Logs and `s3:PutObject` for the receipt prefix. |
| `stepfunctions-invoke-lambdas-role` | `states.amazonaws.com` | `lambda:InvokeFunction` for both Lambda functions. |

### Lambda trust policy

Use this trust relationship for either Lambda execution role:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "lambda.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

Attach the AWS-managed `service-role/AWSLambdaBasicExecutionRole` policy to both Lambda roles. It permits CloudWatch logging.

### S3 policy for `write-receipt`

Attach this additional inline policy only to `lambda-write-receipt-role`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::my-step-fn-9909/receipts/*"
    }
  ]
}
```

`validate-order` does not need S3 permission because it never writes to S3.

### Step Functions trust policy

The state machine uses a different role. Its trust relationship must use `states.amazonaws.com`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "states.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

Its permission policy allows it to invoke the two functions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "lambda:InvokeFunction",
      "Resource": [
        "arn:aws:lambda:us-east-1:ACCOUNT_ID:function:validate-order",
        "arn:aws:lambda:us-east-1:ACCOUNT_ID:function:write-receipt"
      ]
    }
  ]
}
```

Replace `ACCOUNT_ID` with the AWS account ID. The Step Functions role does not need S3 permission because `write-receipt` performs the S3 operation.

## 4. Package and deploy the Lambdas

Package each Python file so it is at the root of the zip file. Do not include `__pycache__`; it is only Python's local bytecode cache.

```bash
cd validate-order
zip -j validate-order.zip order.py

aws lambda create-function \
  --function-name validate-order \
  --runtime python3.14 \
  --handler order.lambda_handler \
  --role "arn:aws:iam::${AWS_ACCOUNT_ID}:role/lambda-validate-order-role" \
  --zip-file fileb://validate-order.zip \
  --timeout 3 \
  --memory-size 128 \
  --region "$AWS_REGION"
```

```bash
cd ../write-receipt
zip -j write-receipt.zip receipt.py

aws lambda create-function \
  --function-name write-receipt \
  --runtime python3.14 \
  --handler receipt.lambda_handler \
  --role "arn:aws:iam::${AWS_ACCOUNT_ID}:role/lambda-write-receipt-role" \
  --zip-file fileb://write-receipt.zip \
  --timeout 10 \
  --memory-size 128 \
  --environment "Variables={OUTPUT_BUCKET=${BUCKET_NAME}}" \
  --region "$AWS_REGION"
```

If a function already exists, update its package instead:

```bash
aws lambda update-function-code \
  --function-name validate-order \
  --zip-file fileb://validate-order.zip \
  --region "$AWS_REGION"
```

## 5. State machine definition

Create a file named `state-machine.json` in this directory. Replace `ACCOUNT_ID` in both Lambda ARNs.

```json
{
  "Comment": "Validate an order and write its receipt to S3",
  "StartAt": "Validate order",
  "States": {
    "Validate order": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "Parameters": {
        "FunctionName": "arn:aws:lambda:us-east-1:ACCOUNT_ID:function:validate-order",
        "Payload.$": "$"
      },
      "ResultSelector": {
        "isValid.$": "$.Payload.isValid",
        "reason.$": "$.Payload.reason"
      },
      "ResultPath": "$.validation",
      "Next": "Is order valid?"
    },
    "Is order valid?": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.validation.isValid",
          "BooleanEquals": true,
          "Next": "Write receipt"
        }
      ],
      "Default": "Invalid order"
    },
    "Write receipt": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "Parameters": {
        "FunctionName": "arn:aws:lambda:us-east-1:ACCOUNT_ID:function:write-receipt",
        "Payload": {
          "orderId.$": "$.orderId",
          "customerEmail.$": "$.customerEmail",
          "amount.$": "$.amount",
          "executionId.$": "$$.Execution.Id"
        }
      },
      "ResultPath": "$.receipt",
      "Next": "Success"
    },
    "Invalid order": {
      "Type": "Fail",
      "Error": "InvalidOrder",
      "Cause": "The validation Lambda rejected the order."
    },
    "Success": {
      "Type": "Succeed"
    }
  }
}
```

Important fields:

- `Payload.$: "$"` sends the complete execution input to `validate-order`.
- `ResultSelector` extracts the Lambda result from the `Payload` wrapper.
- `ResultPath: "$.validation"` preserves the original order and adds its validation result.
- `Choice` behaves like an `if/else` statement.
- `$$.Execution.Id` is Step Functions context data; it makes each receipt traceable to its workflow execution.

## 6. Create and run the state machine

Create the state machine with its own role:

```bash
cd ..

aws stepfunctions create-state-machine \
  --name order-receipt-workflow \
  --definition file://state-machine.json \
  --role-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:role/stepfunctions-invoke-lambdas-role" \
  --type STANDARD \
  --region "$AWS_REGION"
```

Start an execution:

```bash
STATE_MACHINE_ARN="arn:aws:states:${AWS_REGION}:${AWS_ACCOUNT_ID}:stateMachine:order-receipt-workflow"

aws stepfunctions start-execution \
  --state-machine-arn "$STATE_MACHINE_ARN" \
  --input '{"orderId":"order-1001","customerEmail":"learner@example.com","amount":49.99}' \
  --region "$AWS_REGION"
```

For an invalid-order test, omit `amount` or use `0`. The workflow should follow the `Invalid order` branch.

For a valid order, inspect the execution graph in the Step Functions console and confirm that the receipt exists:

```bash
aws s3 cp "s3://${BUCKET_NAME}/receipts/order-1001.json" -
```

## Cleanup

Delete the state machine, Lambda functions, IAM roles, and S3 objects/bucket when you are finished to avoid unnecessary charges.

