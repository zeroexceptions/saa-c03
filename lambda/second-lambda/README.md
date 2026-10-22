# second-lambda (Node.js zip + AWS CLI)

Handler: `index.handler`  
Runtime: `nodejs20.x`

## Zip

```bash
cd ~/Desktop/aws_crs/lambda/second-lambda/src
zip -r ../function.zip .
cd ..
```

## Role (once)

```bash
aws iam create-role \
  --role-name second-lambda-exec-role \
  --assume-role-policy-document file://trust-policy.json

aws iam attach-role-policy \
  --role-name second-lambda-exec-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
```

Wait ~10 seconds after creating the role.

## Create function

```bash
ROLE_ARN=$(aws iam get-role --role-name second-lambda-exec-role --query 'Role.Arn' --output text)

aws lambda create-function \
  --function-name second-lambda \
  --runtime nodejs20.x \
  --role "$ROLE_ARN" \
  --handler index.handler \
  --zip-file fileb://function.zip \
  --timeout 3 \
  --memory-size 128 \
  --region us-east-1
```

## Test

```bash
aws lambda invoke \
  --function-name second-lambda \
  --payload '{}' \
  --cli-binary-format raw-in-base64-out \
  response.json

cat response.json
```

CloudWatch logs (`console.log`) are in `/aws/lambda/second-lambda`.

## Update code and run again

1. Edit `src/index.js`.
2. Re-zip from `src` (same as first zip — overwrites `function.zip`).
3. Push the new zip to the existing function.
4. Invoke again.

```bash
cd ~/Desktop/aws_crs/lambda/second-lambda/src
zip -r ../function.zip .
cd ..

aws lambda update-function-code \
  --function-name second-lambda \
  --zip-file fileb://function.zip \
  --region us-east-1
```

Wait until the function is `Active` if the next invoke fails with `ResourceConflictException`:

```bash
aws lambda wait function-updated \
  --function-name second-lambda \
  --region us-east-1
```

Then invoke:

```bash
aws lambda invoke \
  --function-name second-lambda \
  --payload '{}' \
  --cli-binary-format raw-in-base64-out \
  response.json

cat response.json
```

Do **not** run `create-function` again for an update. That is only for the first deploy.

To change timeout, memory, handler, or layers (not the zip):

```bash
aws lambda update-function-configuration \
  --function-name second-lambda \
  --timeout 10 \
  --region us-east-1
```

## Layers

A **layer** is a separate zip that Lambda mounts at `/opt` and shares across functions. Your function zip stays small; common code or `node_modules` live in the layer.

For Node.js, the zip **must** start with `nodejs/`:

```
layer/
  nodejs/
    node_modules/
      shared-lib/
        index.js
        package.json
```

At runtime that becomes `/opt/nodejs/node_modules/shared-lib`, so `require("shared-lib")` works. Runtime of the layer must match the function (`nodejs20.x`).

### 1. Zip the layer

```bash
cd ~/Desktop/aws_crs/lambda/second-lambda/layer
zip -r ../shared-layer.zip nodejs
cd ..
```

### 2. Publish a layer version

Each publish creates a **new version**. You attach a version ARN, not just a name.

```bash
aws lambda publish-layer-version \
  --layer-name second-lambda-shared \
  --zip-file fileb://shared-layer.zip \
  --compatible-runtimes nodejs20.x \
  --region us-east-1
```

Copy `LayerVersionArn` from the output (looks like `arn:aws:lambda:us-east-1:ACCOUNT:layer:second-lambda-shared:1`).

### 3. Attach it to the function

Replace the ARN with yours:

```bash
aws lambda update-function-configuration \
  --function-name second-lambda \
  --layers arn:aws:lambda:us-east-1:546208175646:layer:second-lambda-shared:1\
  --region us-east-1
```

`--layers` **replaces** the full list. To detach all layers, pass an empty list:

```bash
aws lambda update-function-configuration \
  --function-name second-lambda \
  --layers \
  --region us-east-1
```

### 4. Update function code (uses `require("shared-lib")`) and invoke

```bash
cd ~/Desktop/aws_crs/lambda/second-lambda/src
zip -r ../function.zip .
cd ..

aws lambda update-function-code \
  --function-name second-lambda \
  --zip-file fileb://function.zip \
  --region us-east-1

aws lambda wait function-updated \
  --function-name second-lambda \
  --region us-east-1

aws lambda invoke \
  --function-name second-lambda \
  --payload '{}' \
  --cli-binary-format raw-in-base64-out \
  response.json

cat response.json
```

Expected body includes `"hello from layer, zip lambda"`.

If you change files under `layer/`, zip and `publish-layer-version` again, then `update-function-configuration --layers` with the **new** version ARN. `update-function-code` does not refresh the layer.
