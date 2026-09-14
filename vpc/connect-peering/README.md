## create vpc peering connection

```
aws ec2 create-vpc-peering-connection \
  --vpc-id vpc-089d2e323e64765c8 \
  --peer-vpc-id vpc-0401c02046b86d755

```


## activate peering connection

```sh
aws ec2 accept-vpc-peering-connection \
  --vpc-peering-connection-id pcx-09cee6190a240f557
```

## In the route table associated with VPC 12.0.0.0/16:
## add a route to the other VPC (10.0.0.0/16)

```sh
aws ec2 create-route \
  --route-table-id rtb-04b32656e6ea05224 \
  --destination-cidr-block 10.0.0.0/16 \
  --vpc-peering-connection-id pcx-09cee6190a240f557
```

# In the route table associated with VPC 10.0.0.0/16:
# add a route to the other VPC (12.0.0.0/16)

```sh
aws ec2 create-route \
  --route-table-id rtb-0aa38fc12939ba589 \
  --destination-cidr-block 12.0.0.0/16 \
  --vpc-peering-connection-id pcx-09cee6190a240f557
```