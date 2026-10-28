# Create CloudWatch Log and Stream

```sh
aws logs create-log-group --log-group-name mycloudtrail
```

# create a Role

```sh
aws iam create-role --role-name mycloudwatchcloudtrailrole --assume-role-policy-document file://assume_role_policy_document.json
```

# create policy and attach to role

```sh
aws iam put-role-policy --role-name mycloudwatchcloudtrailrole --policy-name cloudtrail-policy --policy-document file://cloud-watch-policy.json
```


# Update trail for CloudWatch Logs, first you need to trail and then run the below cmd

```sh
aws cloudtrail update-trail \
--name MyTrail \
--cloud-watch-logs-log-group-arn arn:aws:logs:us-east-1:546208175646:log-group:mycloudtrail:* \
--cloud-watch-logs-role-arn arn:aws:iam::546208175646:role/mycloudwatchcloudtrailrole
```

# Delete the trail

```sh
aws cloudtrail describe-trails --trail-name-list MyTrail
```
