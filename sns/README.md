# SNS → Lambda (basic practice)

Hands-on exercise: publish a message to an **Amazon SNS** topic and have a **Lambda** function process it. CloudWatch Logs are used only to verify the run.

## Folder layout

```
sns/
├── README.md
└── basic/
    ├── template.yml    # CloudFormation: SNS topic + Lambda + IAM role
    └── bin/
        ├── deploy      # Create/update the stack (us-east-1)
        └── publish     # Publish a test JSON message to the topic
```

## What gets created

| Resource | Purpose |
|----------|---------|
| SNS topic | Channel that receives published messages |
| Lambda `sns-basic-practice` | Subscriber that reads the SNS message and prints a greeting |
| IAM role + `AWSLambdaBasicExecutionRole` | Lets Lambda run and write to CloudWatch Logs |

**Not** created by the template (you do this in the console):

- SNS subscription (topic → Lambda)
- Invoke permission (usually added automatically when you add the trigger)

## End-to-end flow

```
./bin/deploy
    → CloudFormation creates topic + Lambda + role

Console: subscribe Lambda to the topic
    → SNS can invoke Lambda

./bin/publish
    → Message goes to SNS
    → SNS delivers to Lambda
    → Lambda prints "Hello {first_name} {last_name}!"
    → Output appears in CloudWatch Logs
```

## Steps

### 1. Deploy

```bash
cd sns/basic/bin
./deploy
```

Stack name: `sns-basic-practice`  
Region: `us-east-1`

Copy the topic ARN from CloudFormation **Outputs** (or SNS console) into `bin/publish` if needed.

### 2. Subscribe Lambda (console exercise)

Region: **US East (N. Virginia) / us-east-1**

**From SNS**

1. SNS → Topics → open your topic  
2. **Create subscription**  
3. Protocol: **AWS Lambda**  
4. Endpoint: **`sns-basic-practice`**  
5. Create — status should be **Confirmed**

**Or from Lambda**

1. Lambda → `sns-basic-practice` → **Add trigger** → **SNS**  
2. Select the same topic → Add  

Check: Configuration → Triggers shows the topic; Permissions → resource-based policy allows `sns.amazonaws.com` to invoke the function.

### 3. Publish

Edit the message in `bin/publish` if you want, then:

```bash
./publish
```

A successful CLI response looks like:

```json
{
    "MessageId": "..."
}
```

That only means SNS accepted the message. Lambda still must be subscribed for it to run.

### 4. Verify in CloudWatch Logs

1. Lambda → `sns-basic-practice` → **Monitor** → **View CloudWatch logs**  
   (or CloudWatch → Log groups → `/aws/lambda/sns-basic-practice`)
2. Open the newest log stream  
3. Expect a line like: `Hello Farooq Haider Alvi!`

Example successful log lines:

```
INIT_START ...
START RequestId: ...
Hello Farooq Haider Alvi!
END RequestId: ...
REPORT RequestId: ... Duration: ... ms
```

## Why CloudWatch logs appear without configuring CloudWatch

You do not manually create a log group or “attach CloudWatch” to Lambda.

1. The handler uses `print(...)`, which goes to Lambda stdout/stderr.  
2. The execution role includes `AWSLambdaBasicExecutionRole`, which allows creating log groups/streams and putting log events.  
3. On first invoke, Lambda automatically creates `/aws/lambda/sns-basic-practice` and writes logs there.

CloudWatch is Lambda’s default logging destination when that basic execution policy is present.

## Cleanup

```bash
aws cloudformation delete-stack \
  --region us-east-1 \
  --stack-name sns-basic-practice
```

Also remove any leftover console-created pieces if the stack delete does not cover them (the subscription is usually deleted with the topic/function).

## Exam takeaway

- **SNS** = pub/sub: publish once, deliver to subscribers (Lambda, SQS, email, HTTPS, etc.).  
- **Subscription** connects the topic to the consumer.  
- **Lambda** needs permission for SNS to invoke it (often added when you create the trigger).  
- **Logs** come from `print` + the basic execution role, not a separate CloudWatch setup step.
