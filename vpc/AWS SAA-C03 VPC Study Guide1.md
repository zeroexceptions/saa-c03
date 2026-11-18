# AWS SAA-C03 VPC Study Guide

Nov 11, 2026 · @Farooq Haider

## How to use this guide

Work through Steps 1 to 8 in order, because each step builds on the one before it. Do the lab after Step 4, since it exercises Steps 1 to 4 hands-on, then finish with the self-test.

Each step carries a depth label:

- **Deep**: you must answer scenario questions on it without hesitation (Steps 1 to 4).
- **Well**: know the comparisons, limits and when to pick each option (Steps 5 and 6).
- **Glance**: a handful of facts is enough (Step 7).
- **Recognize**: know the name and its one-line purpose (Step 8).

For every item, ask two questions: what problem does it solve, and what is the alternative? SAA-C03 is scenario-based ("lowest cost", "no internet access", "most secure"), so knowing why you would pick A over B matters more than the definition of A.

Your notes also list services that only have "gateway" in the name (API Gateway, Storage Gateway, IoT Device Gateway, Backup Gateway). They are not VPC topics, so study them with API, storage and IoT services later.

## Step 1: Foundations (Deep)

A VPC is your own isolated virtual network inside one AWS Region, and every other step in this guide is built from the pieces below.

| Piece | What it is | Must know |
| --- | --- | --- |
| VPC | Isolated network in one Region | Spans all AZs in that Region; the default VPC exists in every Region |
| CIDR block | The IP range of the VPC | Between /16 (65,536 addresses) and /28 (16 addresses); peered VPCs cannot overlap |
| Subnet | A slice of the VPC range | Lives in exactly one AZ; AWS reserves 5 addresses per subnet |
| Route table | Rules of destination to target | Each subnet uses one; the most specific route wins; the local route is automatic |
| Internet Gateway (IGW) | Door between the VPC and the internet | One per VPC; free, scales automatically, handles IPv4 and IPv6 |
| Elastic IP | A static public IPv4 address you own | Stays yours until released; AWS charges hourly for public IPv4 addresses |
| ENI | A virtual network card | Holds the private IP and the security groups; every EC2 instance has one |

**The public vs private rule.** A subnet is public only when its route table sends 0.0.0.0/0 to an IGW. An instance in it is reachable from the internet only if it also has a public or Elastic IP. A subnet with no such route is private.

**Exam traps**

- A subnet can never span two AZs, so high availability means one subnet per AZ.
- "Instance in a public subnet cannot reach the internet" means check three things: route to the IGW, a public IP, and the SG and NACL rules.
- Your own request flow is right: Internet, IGW, route table, subnet NACL, ENI security group, instance.

**Check yourself:** What exactly makes a subnet public? Why can an instance in a public subnet still be unreachable?

## Step 2: Security Groups vs NACLs (Deep)

Security groups are stateful and work at the instance level, while NACLs are stateless and work at the subnet level; this pair is tested more than anything else in VPC.

|  | Security group | Network ACL |
| --- | --- | --- |
| Attached to | ENI (instance) | Subnet |
| State | Stateful: return traffic is allowed automatically | Stateless: return traffic needs its own rule |
| Rule types | Allow only | Allow and deny |
| Evaluation | All rules together | In rule-number order, first match wins |
| Default | Inbound denied, outbound allowed | Default NACL allows all; a custom NACL denies all until you add rules |
| Source can be | CIDR or another security group | CIDR only |
| Applies to | Only instances it is attached to | Every instance in the subnet |

**Order of checks.** Inbound traffic hits the subnet NACL first, then the security group. Outbound traffic hits the security group first, then the NACL.

**Details worth knowing**

- An instance can have several security groups, and their rules are combined.
- Referencing a security group as a source is the standard way to say "only the web tier may reach the app tier".
- Because NACLs are stateless, clients often connect back on ephemeral ports (1024 to 65535 is the safe range), so a custom NACL must allow them outbound for inbound web traffic to work.
- One subnet has exactly one NACL, but one NACL can cover many subnets.

**Exam traps**

- "Block one malicious IP address" means NACL, because security groups cannot deny.
- "Inbound is allowed but connections hang" on a custom NACL means the return ephemeral port range is missing.
- "Allow traffic only from instances in another group" means a security group reference, not a CIDR.

**Check yourself:** Why does a stateless firewall need rules in both directions? Which of the two would you use to block a single IP?

## Step 3: Outbound access from private subnets (Deep)

Private instances often need to reach the internet for patches or APIs without being reachable from it, and a NAT Gateway (IPv4) or an egress-only IGW (IPv6) solves that.

| Option | IP version | Managed by | Lives in | Route target |
| --- | --- | --- | --- | --- |
| NAT Gateway | IPv4 | AWS | A public subnet, with an Elastic IP | Private route table: 0.0.0.0/0 to the NAT Gateway |
| NAT instance | IPv4 | You (an EC2 instance) | A public subnet | Same route, pointing at the instance |
| Egress-only IGW | IPv6 | AWS | Attached to the VPC | Private route table: ::/0 to the egress-only IGW |

**NAT Gateway facts**

- It sits in a public subnet and needs an Elastic IP; the private subnet's route table points at it.
- It is highly available only inside its own AZ, so for resilience create one per AZ and point each AZ's private route table at its own NAT Gateway.
- It scales automatically, you pay per hour plus per GB processed, and it has no security group (the subnet NACL still applies).
- It allows connections started from inside only; the internet cannot start a connection to the private instance.

**NAT instance facts.** It is the legacy do-it-yourself option: you must disable the source/destination check, give it a security group, and size and patch it yourself. It can double as a bastion host or do port forwarding, and the exam prefers the NAT Gateway nearly every time.

**Why egress-only exists.** IPv6 addresses are all public, so a normal IGW would make instances reachable from the internet. The egress-only IGW allows outbound IPv6 and blocks inbound.

**Exam traps**

- A NAT Gateway placed in a private subnet is wrong: it must be in a public subnet.
- "IPv6, outbound only" means egress-only IGW; "IPv4, outbound only, managed" means NAT Gateway.
- One NAT Gateway for all AZs is a single point of failure and adds cross-AZ data charges.

**Check yourself:** Which subnet does a NAT Gateway live in, and which route table points to it?

## Step 4: Private access to AWS services (Deep)

VPC endpoints let instances reach AWS services without a NAT Gateway or the public internet; gateway endpoints cover only S3 and DynamoDB, and interface endpoints cover most other services.

|  | Gateway endpoint | Interface endpoint |
| --- | --- | --- |
| Services | S3 and DynamoDB only | Most others (SQS, SNS, Kinesis, CloudWatch, SSM, ECR and more), and S3 as well |
| How it works | A route table entry pointing at the endpoint | An ENI with a private IP in your subnet |
| Cost | Free | Hourly per AZ plus per GB |
| Reachable from on-premises or a peered VPC | No | Yes, over its private IP |
| Access control | Endpoint policy | Security group on the ENI, plus endpoint policy |
| Technology | Route-based | AWS PrivateLink |

**PrivateLink for your own service.** A provider puts its service behind a Network Load Balancer and publishes it as an endpoint service. Each consumer VPC creates an interface endpoint to it. No peering is needed, CIDR ranges may overlap, and traffic flows one way, from consumer to provider.

**Exam traps**

- "Private subnet reads S3, no internet, lowest cost" means a gateway endpoint.
- "On-premises must reach S3 privately over VPN or Direct Connect" means an interface endpoint, because gateway endpoints are not reachable from outside the VPC.
- "Private access to SQS, SNS or CloudWatch" means an interface endpoint, since gateway endpoints do not support them.
- "Share one service with many VPCs or accounts without peering" means PrivateLink.

**Check yourself:** Which two services have gateway endpoints, and why are they free? Which endpoint type creates an ENI?

**Now do the lab** (later in this doc) before moving on, because Steps 1 to 4 are all hands-on there.

## Step 5: Connecting VPCs (Well)

Use peering for a few VPCs, Transit Gateway for many, and PrivateLink when you only want to expose one service.

|  | VPC peering | Transit Gateway | PrivateLink |
| --- | --- | --- | --- |
| Connects | Two VPCs | Many VPCs and on-premises networks | One service to many consumer VPCs |
| Transitive routing | No | Yes | Not applicable |
| Overlapping CIDRs | Not allowed | Cannot be routed between | Allowed |
| Setup | Request and accept, then add routes in both route tables | Attach each VPC, then manage TGW route tables | NLB, endpoint service, interface endpoint |
| Cross-account and cross-Region | Yes | Yes | Yes |
| Cost | No hourly fee, data transfer charged | Hourly per attachment plus per GB | Endpoint hourly plus per GB |

**Peering rules to memorize**

- It is one-to-one and non-transitive: if A peers with B and B peers with C, A still cannot reach C.
- Both sides must add routes to each other's CIDR in their route tables, and security groups must allow the traffic.
- You cannot use the other VPC's IGW, NAT Gateway, VPN or Direct Connect through a peering connection.

**Transit Gateway.** It is a hub-and-spoke router: each VPC, VPN or Direct Connect attaches once, and routing between attachments is controlled by TGW route tables. It replaces the "full mesh" of peering connections that becomes unmanageable as VPCs multiply.

**Exam traps**

- "Dozens or hundreds of VPCs plus on-premises" means Transit Gateway, not peering.
- "Two VPCs, lowest cost" means peering.
- "Overlapping CIDR ranges" rules out peering and Transit Gateway routing, which points to PrivateLink.

**Check yourself:** Why does A to B and B to C peering not give you A to C? What does Transit Gateway change?

## Step 6: Hybrid connectivity (Well)

Site-to-Site VPN is quick and encrypted but runs over the internet, Direct Connect is a dedicated line that is consistent but slow to set up, and Client VPN is for individual remote users.

**The two gateway pieces**

- **Virtual Private Gateway (VGW):** the AWS-side endpoint of a VPN, attached to one VPC.
- **Customer Gateway (CGW):** the AWS resource that represents your on-premises VPN device or software.

|  | Site-to-Site VPN | Direct Connect |
| --- | --- | --- |
| Path | Encrypted IPsec tunnels over the public internet | Dedicated private fiber to an AWS location |
| Setup time | Minutes to hours | Weeks |
| Encryption | Yes, by default | No by default; add a VPN over it or MACsec |
| Latency | Variable | Consistent |
| Bandwidth | Limited per tunnel (about 1.25 Gbps) | 50 Mbps up to 100 Gbps |
| Cost | Low | Higher (port hours plus data out) |

**Site-to-Site VPN facts.** Each connection gives you two tunnels for redundancy, routing is static or dynamic (BGP), and it can terminate on a VGW or on a Transit Gateway.

**Direct Connect facts**

- It uses virtual interfaces: private (to a VPC), public (to AWS public services such as S3) and transit (to a Transit Gateway).
- A Direct Connect Gateway lets one connection reach VPCs in several Regions and accounts.
- For high availability use two connections in different locations, or a VPN as the backup path.

**Client VPN.** It is a managed OpenVPN-based service that lets individual users (laptops) connect into your VPC and, through it, on-premises networks.

**Exam traps**

- "Set up within days, encrypted" means Site-to-Site VPN.
- "Consistent low latency and high throughput" means Direct Connect.
- "Dedicated and encrypted" means VPN running over Direct Connect.
- "Backup for Direct Connect" means Site-to-Site VPN.
- "Remote employees connect individually" means Client VPN.

**Check yourself:** Which of VGW and CGW is on the AWS side? Why is Direct Connect not encrypted by default?

## Step 7: Monitoring with VPC Flow Logs (Glance)

VPC Flow Logs record metadata about the IP traffic going to and from network interfaces, which makes them the tool for finding out why traffic was accepted or rejected.

- **What is recorded:** source and destination IP and port, protocol, bytes, and whether the traffic was ACCEPT or REJECT. Packet contents are never captured.
- **Where you enable them:** at the VPC, subnet or ENI level.
- **Where they are delivered:** CloudWatch Logs, S3 or Kinesis Data Firehose; query S3 data with Athena.
- **Not captured:** traffic to the Amazon DNS server, DHCP traffic and instance metadata requests (169.254.169.254).
- **Timing:** logs arrive with a delay, so they are for analysis and troubleshooting, not real-time alerting.

**Exam trap.** "Which rule is blocking this traffic, or who is hitting my instance?" means Flow Logs. "Inspect the actual packet contents" does not mean Flow Logs; that points to Traffic Mirroring or a third-party appliance.

**Check yourself:** What kind of data do Flow Logs hold, and what do they never hold?

## Step 8: Recognize-only items

These appear rarely, so learn the name and one line each, and spend no more time than that.

| Item | One-line purpose | When it shows up |
| --- | --- | --- |
| Shared VPC (via AWS RAM) | The owner account shares subnets with other accounts in the same AWS Organization, and they launch resources in them | Many accounts, one network |
| Gateway Load Balancer (GWLB) | A Layer 3 load balancer that sends traffic through third-party appliances such as firewalls and IDS/IPS | Inline traffic inspection |
| GWLB endpoint | The endpoint that routes VPC traffic to a GWLB | Same scenario as above |
| VPC Lattice | Application-layer service-to-service networking across VPCs and accounts | Newer, lightly tested |
| Network Address Usage (NAU) | A metric that counts the network addresses a VPC uses, against quotas | Large-scale VPC design |
| Cloud WAN, Carrier Gateway, Outposts local gateway | Managed global WAN, telecom carrier (Wavelength) and Outposts connectivity | Name only |

**Fixes to your notes**

- "Shared VPC (one way check firewall stateful)" mixes two ideas. The "one way check" belongs to stateful security groups, and Shared VPC is the separate multi-account sharing feature above.
- Customer Gateway is described in your notes as an on-premises "account"; it is the AWS resource that represents your on-premises VPN device.

**Skip for now.** API Gateway, Storage Gateway, IoT Device Gateway and Backup Gateway are separate services. Study them when you reach API, storage and IoT topics.

## Hands-on lab (after Step 4)

Building one VPC with a public subnet, a private subnet, a NAT Gateway and an S3 gateway endpoint covers most of Steps 1 to 4 in practice. Do it in one sitting, because the NAT Gateway bills by the hour.

1. Create a VPC with CIDR 10.0.0.0/16 (choose "VPC only" so you create each piece yourself).
2. Create a public subnet 10.0.1.0/24 and a private subnet 10.0.2.0/24 in the same AZ.
3. Create an Internet Gateway and attach it to the VPC.
4. Create a public route table with 0.0.0.0/0 to the IGW, associate it with the public subnet, and enable auto-assign public IPv4 on that subnet.
5. Launch an EC2 instance in the public subnet with a security group allowing SSH from your IP and HTTP from anywhere. Install Apache and open the public IP in a browser.
6. Launch a second EC2 instance in the private subnet whose security group allows SSH only from the first instance's security group. Attach an IAM role with S3 read access. SSH to it through the public instance.
7. From the private instance, run a curl to a public website and confirm it times out.
8. Create a NAT Gateway in the public subnet with a new Elastic IP, add 0.0.0.0/0 to the NAT Gateway in the private route table, and repeat the curl; it should now work.
9. Create an S3 gateway endpoint and attach it to the private route table. Remove the NAT route and confirm that `aws s3 ls` still works from the private instance while curl to the internet fails.
10. Break things on purpose: add a NACL deny rule for your IP, then create a custom NACL without ephemeral-port rules, and watch the connections fail.
11. Turn on VPC Flow Logs for the subnet (to CloudWatch Logs) and find the REJECT records from step 10.
12. Clean up: delete the NAT Gateway, release the Elastic IP, terminate both instances, then delete the endpoint, IGW, subnets and VPC.

**What you should be able to explain afterwards:** why the private instance had no internet until the NAT route existed, why S3 worked without NAT, and why the NACL failure looked different from a security group failure.

## Self-test

Cover the right-hand column and answer each scenario out loud; any you miss tells you which step to reread.

**The five pairs to drill**

| Pair | Decide by |
| --- | --- |
| Security group vs NACL | Stateful and instance-level, versus stateless, subnet-level and able to deny |
| NAT Gateway vs egress-only IGW | IPv4 versus IPv6 |
| Gateway endpoint vs interface endpoint | S3 and DynamoDB for free via routes, versus an ENI for most other services and on-premises access |
| Peering vs Transit Gateway | Two VPCs and non-transitive, versus many VPCs and transitive |
| Site-to-Site VPN vs Direct Connect | Fast, encrypted and variable, versus slow to set up, dedicated and consistent |

**Scenarios**

| Scenario | Answer | Step |
| --- | --- | --- |
| Block one malicious IP from reaching a web server | NACL deny rule | 2 |
| Inbound HTTP is allowed on a custom NACL but connections hang | Missing outbound ephemeral port rule | 2 |
| Private instances need IPv4 internet for patches, fully managed | NAT Gateway in a public subnet | 3 |
| IPv6 instances need outbound-only internet | Egress-only IGW | 3 |
| NAT Gateway must survive an AZ failure | One NAT Gateway per AZ, each AZ's route table pointing to its own | 3 |
| Private instance reads S3, no internet, lowest cost | S3 gateway endpoint | 4 |
| Private instance calls SQS or CloudWatch without internet | Interface endpoint | 4 |
| On-premises reaches S3 privately over Direct Connect | Interface endpoint for S3 | 4 |
| Expose your service to many customer VPCs with overlapping CIDRs | PrivateLink (NLB plus endpoint service) | 4, 5 |
| Connect two VPCs at the lowest cost | VPC peering, with routes on both sides | 5 |
| Connect 50 VPCs and an on-premises network | Transit Gateway | 5 |
| Office connects to AWS within days, encrypted | Site-to-Site VPN | 6 |
| Consistent low latency and high throughput to AWS | Direct Connect | 6 |
| Direct Connect traffic must also be encrypted | VPN over Direct Connect (or MACsec) | 6 |
| Backup path if Direct Connect fails | Site-to-Site VPN | 6 |
| Remote employees connect from laptops | Client VPN | 6 |
| Find out which traffic was rejected | VPC Flow Logs | 7 |
| Inline third-party firewall for all VPC traffic | Gateway Load Balancer | 8 |
| Several accounts launching resources in the same subnets | Shared VPC with AWS RAM | 8 |

**Next step.** Once you can answer the table without looking, move to timed practice questions on networking and note any you miss; for each miss, write the problem and the correct alternative in one line.
