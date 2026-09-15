{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowReadS3DevBucket",
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:ListBucket"],
      "Resource": "arn:aws:s3:::my-dev-bucket/*",
      "Condition": {
        "IpAddress": {"aws:SourceIp": "203.0.113.0/24"}
      }
    }
  ]
}



Version
Specifies the IAM policy language syntax version, not a version number for your policy. "2012-10-17" is the current/latest version and should be used in all new policies. There's an older "2008-10-17" version still supported for backward compatibility, but AWS recommends always using 2012-10-17 since it supports newer features like policy variables.
2
Statement
The container that holds one or more individual permission rules. Every policy must have at least one Statement, and it's common to have many, each granting or denying a different set of permissions. Structurally it's an array: 'Statement: [ {...}, {...} ]'.
3
Sid (Statement ID)
An optional, purely descriptive label for a statement (e.g. 'AllowS3ReadOnly'). It has zero effect on permissions — it's just there to make the policy more readable and easier to reference/debug, similar to a comment.
4
Effect
Must be either 'Allow' or 'Deny'. This is the core switch that determines whether the listed actions are permitted or blocked. Important rule: an explicit Deny always overrides any Allow, even from a different policy attached to the same identity.
5
Action
The specific API operations the statement applies to, written as 'service:ActionName' (e.g. 's3:GetObject', 'ec2:StartInstances'). You can list multiple actions, use wildcards like 's3:*' for all S3 actions, or use 'NotAction' to invert the logic (as we saw in an earlier policy you shared).
6
Principal
Specifies WHO the statement applies to — an account, IAM user, role, or federated user. This element only appears in resource-based policies (like an S3 bucket policy or IAM role trust policy), NOT in identity-based policies (attached to a user/role/group), since in those cases the 'who' is implied by whoever the policy is attached to.
7
Resource
Specifies WHICH AWS resource(s) the action applies to, written as an ARN (e.g. 'arn:aws:s3:::my-bucket/*' for objects in a specific bucket). Using '*' means the action applies to all resources of that type — which is why scoping this down is key to least-privilege policies.
8
Condition
Optional extra logic that narrows when the statement applies — e.g. only allow the action if the request comes from a specific IP range, only if MFA was used, or only during certain hours. Written as key-value operators like 'IpAddress', 'DateLessThan', 'Bool', etc.