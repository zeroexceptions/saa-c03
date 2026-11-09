# AWS VPC Lab: Public EC2 + Private RDS PostgreSQL

A hands-on learning setup (SAA-C03 prep) built in the AWS Console, region **us-east-1**.

```
Internet
   |
[Internet Gateway: igw-0dbde09908d7d4872]
   |
+--------------------- VPC: myvpc (10.0.0.0/16) ----------------------+
|                                                                     |
|  Public subnets (route 0.0.0.0/0 -> IGW)                            |
|    10.0.0.0/24 (us-east-1a)   EC2 web-public  [web-sg]             |
|    10.0.1.0/24 (us-east-1b)                                         |
|                                                                     |
|  Private subnets (local route only)                                 |
|    10.0.2.0/24 (us-east-1c)   RDS PostgreSQL  [rds-sg]             |
|    10.0.3.0/24 (second AZ)    (DB subnet group needs 2 AZs)         |
+---------------------------------------------------------------------+
```

## Resources used

| Resource | Value |
|---|---|
| VPC | `myvpc`, `vpc-05406d157bbe9319f`, `10.0.0.0/16` |
| Internet Gateway | `igw-0dbde09908d7d4872` |
| Main route table | `rtb-071b25a87345aab70` (local route only, kept private on purpose) |
| Public route table | `my-public-rt`, `rtb-00b8c4c4046521a2b` |
| EC2 | `web-public`, Amazon Linux 2023, `t3.micro`, private IP `10.0.0.84` |
| RDS | `mydb`, PostgreSQL 18.3, Single-AZ, `db.t3.micro` |
| Security groups | `web-sg` (EC2), `rds-sg` (database) |

---

## 1. Create the VPC

1. VPC -> **Your VPCs** -> **Create VPC** -> **VPC only**.
2. Name: `myvpc`, IPv4 CIDR: `10.0.0.0/16`.
3. Create.

A /16 gives 65,536 addresses. The primary CIDR cannot be changed later.

> **Enable DNS settings** (needed later for RDS public access and good practice anyway):
> VPC -> select `myvpc` -> Actions -> **Edit VPC settings** -> tick **Enable DNS resolution** and **Enable DNS hostnames** -> Save.
> VPCs created with "VPC only" have DNS hostnames **off** by default.

## 2. Create the subnets

VPC -> **Subnets** -> **Create subnet** -> select `myvpc` -> add each subnet.

| Name | CIDR | AZ | Type | Total IPs | Usable (AWS reserves 5) |
|---|---|---|---|---|---|
| public-1 | `10.0.0.0/24` | us-east-1a | Public | 256 | 251 |
| public-2 | `10.0.1.0/24` | us-east-1b | Public | 256 | 251 |
| private-1 | `10.0.2.0/24` | us-east-1c | Private | 256 | 251 |
| private-2 | `10.0.3.0/24` | a different AZ than private-1 | Private | 256 | 251 |

Rules to remember:
- Subnet CIDRs must sit inside the VPC CIDR and must not overlap each other.
- A subnet lives in exactly one AZ.
- A /24 spans `x.x.N.0` to `x.x.N.255`. Increment the third octet for each new /24.
- AWS reserves the first four and the last address of every subnet (`.0` network, `.1` router, `.2` DNS, `.3` future use, `.255` broadcast). Usable range of `10.0.2.0/24` is `10.0.2.4` to `10.0.2.254`.

## 3. Internet Gateway

1. VPC -> **Internet gateways** -> **Create internet gateway** (`myvpc-igw`).
2. **Actions** -> **Attach to VPC** -> `myvpc`.

Check from the CLI:

```bash
aws ec2 describe-internet-gateways \
  --filters "Name=attachment.vpc-id,Values=vpc-05406d157bbe9319f" \
  --region us-east-1 \
  --query "InternetGateways[].{IGW:InternetGatewayId,State:Attachments[0].State}" \
  --output table
```

An attached IGW does nothing until a route table points to it.

## 4. Route tables

**Main route table** (`rtb-071b25a87345aab70`): leave it with only `10.0.0.0/16 -> local`.
Any subnet without an explicit association falls back to the main table, so keeping it private means a forgotten subnet fails safe.

**Public route table** (`my-public-rt`):
1. VPC -> **Route tables** -> **Create route table** -> name `my-public-rt`, VPC `myvpc`.
2. **Routes** tab -> **Edit routes** -> **Add route**: destination `0.0.0.0/0`, target **Internet Gateway** -> `igw-0dbde09908d7d4872`.
3. **Subnet associations** tab -> **Edit subnet associations** -> select **public-1** and **public-2** -> Save.

Resulting routes in `my-public-rt`:

| Destination | Target | Meaning |
|---|---|---|
| `10.0.0.0/16` | local | Traffic inside the VPC stays inside |
| `0.0.0.0/0` | `igw-0dbde09908d7d4872` | Everything else goes to the internet |

The most specific route wins, so VPC-internal traffic never goes to the IGW.

The private subnets are **not** associated with anything, so they use the main table (no IGW route) and are private.

Verify:

```bash
aws ec2 describe-route-tables --region us-east-1 \
  --route-table-ids rtb-00b8c4c4046521a2b \
  --query "RouteTables[0].{Routes:Routes[].{Dest:DestinationCidrBlock,Target:GatewayId},Subnets:Associations[].SubnetId}" \
  --output json
```

A subnet is "public" because of its route table, not its CIDR.

## 5. Security groups

### web-sg (for the EC2)

Inbound:

| Type | Port | Source |
|---|---|---|
| SSH | 22 | **My IP** (not 0.0.0.0/0) |
| HTTP | 80 | `0.0.0.0/0` |

Outbound (**must exist**, or `dnf`, curl and everything else time out):

| Type | Port | Destination |
|---|---|---|
| All traffic | All | `0.0.0.0/0` |

### rds-sg (for the database)

Inbound:

| Type | Port | Source |
|---|---|---|
| PostgreSQL | 5432 | **web-sg** (the security group, not a CIDR) |

Outbound: leave the default.

Using a security group as the source means only instances in `web-sg` can reach the database. Security groups are stateful, so return traffic is allowed automatically.

## 6. Launch the EC2 instance (public subnet)

EC2 -> **Instances** -> **Launch instances**.

1. Name: `web-public`
2. AMI: Amazon Linux 2023
3. Instance type: `t3.micro` (or free-tier eligible)
4. Key pair: create `saa-key` (RSA, `.pem`) and download it
5. Network settings -> **Edit**:
   - VPC: `myvpc`
   - Subnet: `10.0.0.0/24` (public-1)
   - Auto-assign public IP: **Enable**
   - Security group: existing -> `web-sg`
6. Launch, then wait for 2/2 status checks. Note the **Public IPv4 address**.

Connect:

```bash
chmod 400 saa-key.pem
ssh -i saa-key.pem ec2-user@<EC2_PUBLIC_IP>
```

Test outbound internet from the instance:

```bash
curl -I --max-time 10 https://aws.amazon.com
```

## 7. Create the RDS PostgreSQL database (private subnets)

### 7.1 DB subnet group

RDS -> **Subnet groups** -> **Create DB subnet group**.

- Name: `private-db-subnet-group`
- VPC: `myvpc`
- AZs: the AZs of the two private subnets
- Subnets: `10.0.2.0/24` and `10.0.3.0/24` (private only)

RDS requires subnets in **at least two AZs**, even for a Single-AZ database.

### 7.2 Create the database

RDS -> **Databases** -> **Create database**.

1. Standard create, engine **PostgreSQL** (18.3)
2. Template: **Free tier** (or Dev/Test)
3. DB instance identifier: `mydb`, master username: `postgres`, self-managed password (save it)
4. Instance class: `db.t3.micro`
5. Storage: 20 GiB, disable storage autoscaling for learning
6. Availability: **Single-AZ DB instance deployment (1 instance)** (cheapest, ~99.5% uptime, no redundancy)
7. Connectivity:
   - Don't connect to an EC2 compute resource
   - VPC: `myvpc`
   - DB subnet group: `private-db-subnet-group`
   - **Public access: No**
   - Security group: existing -> `rds-sg` only (remove `default`)
8. Disable Performance Insights and Enhanced Monitoring to avoid extra cost.
9. Create and wait for status **Available** (5 to 10 minutes).

Note: `mydb` above is the **instance identifier**, not a database name. Unless you set "Initial database name", only the default `postgres` database exists.

### 7.3 Connect from the EC2

Copy the **Endpoint** from the database's Connectivity & security tab, then on the EC2:

```bash
sudo dnf install -y postgresql15        # or the newest version `dnf search postgresql` shows
psql -h <RDS_ENDPOINT> -U postgres -d postgres
```

A version warning (client 15, server 18) is harmless for basic SQL. A `postgres=>` prompt means it works.

```sql
CREATE DATABASE mydb;
\c mydb
CREATE TABLE test (id serial PRIMARY KEY, name text);
INSERT INTO test (name) VALUES ('hello from ec2');
SELECT * FROM test;
\q
```

Confirm it is private: the endpoint resolves to a `10.0.x.x` address (for example `10.0.3.89`), and the same `psql` command from your laptop times out.

## 8. Optional: access the database from your laptop

### Recommended: SSH tunnel through the EC2 (database stays private)

```bash
ssh -i saa-key.pem -L 5433:<RDS_ENDPOINT>:5432 ec2-user@<EC2_PUBLIC_IP>
```

In another terminal on your laptop:

```bash
psql -h localhost -p 5433 -U postgres -d postgres
```

This also works with DBeaver or pgAdmin pointed at `localhost:5433`.

### Making the database publicly accessible (not recommended outside experiments)

Setting "Publicly accessible: Yes" requires all of the following:

1. **VPC DNS enabled.** Otherwise the modify fails with:
   `Cannot create a publicly accessible DBInstance. The specified VPC does not support DNS resolution, DNS hostnames, or both.`
   ```bash
   aws ec2 modify-vpc-attribute --region us-east-1 --vpc-id vpc-05406d157bbe9319f --enable-dns-support
   aws ec2 modify-vpc-attribute --region us-east-1 --vpc-id vpc-05406d157bbe9319f --enable-dns-hostnames
   ```
2. **A DB subnet group made of public subnets** (routes to the IGW). Create `public-db-subnet-group` with `10.0.0.0/24` and `10.0.1.0/24`, then modify the DB to use it (this moves the instance and causes downtime; if the console refuses, restore from a snapshot into the new group or recreate the DB).
   Do not mix public and private subnets in one group: the instance lands in one of them unpredictably and loses its route if a private one is chosen.
3. **Modify the DB**: Public access -> **Yes**.
4. **Edit `rds-sg`**: add inbound PostgreSQL 5432 from **My IP** (never `0.0.0.0/0`).

Then connect directly:

```bash
psql -h <RDS_ENDPOINT> -U postgres -d postgres
```

Revert to private when finished: Public access -> No, use the private subnet group again, and remove the My IP rule.

## 9. Troubleshooting log (issues hit in this lab)

| Symptom | Cause | Fix |
|---|---|---|
| `dnf install` times out on the EC2 | `web-sg` had **no outbound rule**, which blocks all outbound traffic | Add outbound All traffic to `0.0.0.0/0` |
| `FATAL: database "mydb" does not exist` | `mydb` was the instance name; only `postgres` exists | Connect with `-d postgres`, then `CREATE DATABASE mydb;` |
| `psql` version warning (15 vs 18) | Older client than server | Harmless for basic SQL; install a newer client if available |
| Can't make RDS public: VPC does not support DNS | DNS hostnames/resolution disabled on the VPC | Enable both in VPC settings |
| Subnet group error about AZs | Both private subnets in the same AZ | Put the two private subnets in different AZs |
| SSH times out | Your public IP changed | Update the SSH rule in `web-sg` to My IP |

## 10. Key concepts (exam notes)

- **Public vs private subnet:** decided by the route table (`0.0.0.0/0 -> IGW`), not by CIDR.
- **Two-way internet access needs:** IGW attached + route to IGW + public/Elastic IP + SG and NACL allow + VPC Block Public Access off.
- **Keep the main route table private**; create a separate public route table for public subnets.
- **Security groups:** stateful, allow rules only, can reference other security groups. **NACLs:** stateless, numbered rules, allow and deny.
- **Overlapping CIDRs:** allowed between unconnected VPCs, but peering, Transit Gateway and VPN need non-overlapping ranges. Use PrivateLink to share a single service across overlapping networks.
- **Permissions boundary:** caps the maximum permissions of one IAM user or role; it never grants anything. SCPs cap whole accounts or OUs.
- **Multi-AZ RDS** is for failover/availability. **Read replicas** are for read scaling.
- Private resources reach the internet outbound-only via a **NAT Gateway** (in a public subnet), and reach S3/DynamoDB privately via **gateway endpoints**.

## 11. Cleanup (avoid charges)

1. RDS -> delete the DB instance (untick final snapshot for a throwaway lab).
2. Delete the DB subnet group(s) and `rds-sg`.
3. Terminate the EC2 instance, then delete `web-sg`.
4. Release any Elastic IPs and delete any NAT Gateway (billed hourly).
5. Optionally delete the subnets, route tables, detach and delete the IGW, then delete the VPC.