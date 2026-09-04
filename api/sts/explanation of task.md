# STS role assumption and S3 access

This example demonstrates how an IAM user receives **temporary** S3 access by
assuming an IAM role through AWS Security Token Service (STS).

```text
sts-machine-user --(asks STS to assume)--> StsRole --(role policy permits)--> S3 bucket
```

The files have separate jobs:

| File | Purpose |
| --- | --- |
| `template.yaml` | CloudFormation definition that creates an S3 bucket and an IAM role. |
| `bin/deploy` | Deploys `template.yaml` as a CloudFormation stack. |
| `policy.json` | An identity policy that permits `sts-machine-user` to request temporary credentials for the role. |
| `README.md` | The process and the reason each part is needed. |

## 1. What CloudFormation creates

Run the deployment with an administrator profile, not the restricted `sts`
profile:

```bash
aws cloudformation deploy \
  --template-file template.yaml \
  --stack-name my-sts-fun-stack \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides BucketName=your-globally-unique-bucket-name
```

`template.yaml` declares two resources:

```yaml
S3Bucket:
  Type: AWS::S3::Bucket
  Properties:
    BucketName: !Ref BucketName
```

`BucketName` is a CloudFormation parameter. `!Ref BucketName` means “use the
value supplied for this parameter” as the bucket name. S3 bucket names are
globally unique, so use a name that nobody else has taken.

```yaml
StsRole:
  Type: AWS::IAM::Role
```

This creates a role. A role does not have permanent access keys. It can issue
short-lived credentials when an allowed principal calls `sts:AssumeRole`.

### The role trust policy

The `AssumeRolePolicyDocument` in the template is the role's **trust policy**:

```yaml
AssumeRolePolicyDocument:
  Version: "2012-10-17"
  Statement:
    - Effect: Allow
      Principal:
        AWS: "arn:aws:iam::546208175646:user/sts-machine-user"
      Action: sts:AssumeRole
```

In plain English, this says:

> This role accepts requests to be assumed by exactly `sts-machine-user` in AWS account `546208175646`.

The `Principal` is the entity the role trusts. As written, **only this named
user** is trusted. A different user cannot assume the role merely by having an
`sts:AssumeRole` permission policy. The role's trust policy would also need to
be changed to include that other user, role, or AWS account.

The commented alternative does something different:

```yaml
# Service: s3.amazonaws.com
```

It would trust the S3 AWS service, not your CLI user. Do not use it for this
user-assumes-a-role exercise.

### The role permissions policy

The `s3access` policy under `StsRole` defines what a successful role session
can do. It is the source of the role's S3 access.

The current example uses `Action: s3:*` and also includes
`arn:aws:s3:::*`. That is broader than access to only the bucket created by
the stack. For a real system, grant only required actions and restrict their
resources to the intended bucket and its objects.

## 2. Create and configure the restricted user

Using administrator credentials, create the user and an access key:

```bash
aws iam create-user --user-name sts-machine-user
aws iam create-access-key --user-name sts-machine-user --output table
```

Store the new access key under a separate CLI profile:

```bash
aws configure --profile sts
```

This profile now represents the restricted user:

```bash
aws sts get-caller-identity --profile sts
```

It should return an ARN like this:

```text
arn:aws:iam::546208175646:user/sts-machine-user
```

Before assuming a role, this user should not have direct S3 permissions:

```bash
aws s3 ls --profile sts
```

## 3. What `policy.json` does

`policy.json` is attached to `sts-machine-user`, not to the role:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::546208175646:role/my-sts-fun-stack-StsRole-hbvZF40OCc6y"
  }]
}
```

In plain English, it says:

> Give `sts-machine-user` permission to request temporary credentials for this exact role.

It does **not** grant S3 access. The S3 permissions come from the role policy
created by CloudFormation.

Update the role ARN in `policy.json` to the ARN actually created by your
stack. CloudFormation-generated role names can differ after a redeployment.

Attach this policy with administrator credentials:

```bash
aws iam put-user-policy \
  --user-name sts-machine-user \
  --policy-name StsAssumePolicy \
  --policy-document file://policy.json
```

`file://policy.json` tells the AWS CLI to read policy JSON from the file.

## 4. Assume the role through STS

Use the restricted user's profile to request a role session:

```bash
aws sts assume-role \
  --role-arn arn:aws:iam::546208175646:role/my-sts-fun-stack-StsRole-hbvZF40OCc6y \
  --role-session-name s3-sts-fun \
  --profile sts
```

In plain English:

> I am `sts-machine-user`. STS, give me temporary credentials for this role and label this session `s3-sts-fun`.

AWS permits the request only if **both** permissions agree:

| Check | Where it is configured |
| --- | --- |
| Is the user allowed to request this role? | `policy.json`, attached to `sts-machine-user` |
| Does the role trust this user? | `AssumeRolePolicyDocument`, attached to `StsRole` |

If either check fails, STS returns `AccessDenied`.

If both checks pass, STS returns a temporary access key, secret key, session
token, and expiration time. Configure those returned values in an `assumed`
profile (or export them as environment variables). Then:

```bash
aws sts get-caller-identity --profile assumed
aws s3 ls --profile assumed
```

The identity command should now show an `assumed-role` ARN. S3 requests use
the permissions of `StsRole` until the temporary credentials expire.

## 5. Cross-account note

The account number in the trust policy must identify the real source user. If
the user is in account `546208175646` and the role is in account
`982383527471`, then the role's trust policy must still name:

```text
arn:aws:iam::546208175646:user/sts-machine-user
```

Meanwhile, `policy.json` must name the target role in account `982383527471`.

## Cleanup

Remove the inline policy before deleting the restricted user:

```bash
aws iam delete-user-policy --user-name sts-machine-user --policy-name StsAssumePolicy
aws iam delete-access-key --access-key-id YOUR_ACCESS_KEY_ID --user-name sts-machine-user
aws iam delete-user --user-name sts-machine-user
```

Delete the CloudFormation stack separately. Empty the bucket first if it
contains objects, otherwise CloudFormation cannot delete the bucket.
