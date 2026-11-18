# AWS SAA-C03 · VPC Study Guide

Nov 12, 2026 · @Farooq Haider

## 1. Big picture: how traffic reaches an EC2 instance

A request crosses the IGW, the route table, the NACL and the security group, in that order, before it reaches your instance. Learn this order first; most exam questions test one link in it.

**Inbound (browser to EC2 running Apache on port 80)**

1. Client browser sends an HTTP request to the EC2 public IP.
2. Internet Gateway (IGW) attached to the VPC receives it.
3. The subnet's route table decides where the traffic goes (public subnet = has a route to the IGW).
4. NACL on the subnet checks inbound rules (stateless).
5. Security Group on the EC2 ENI checks inbound rules (stateful).
6. EC2 instance / Apache on port 80 gets the request.

**Outbound (EC2 to internet)**: EC2, then Security Group, then NACL of the subnet, then route table, then IGW, then internet.

**Memory hook:** the NACL guards the subnet door, the security group guards the instance door. The security group remembers connections, so replies are allowed automatically. The NACL does not, so replies need their own rule.

## 2. VPC basics

A VPC is your own logically isolated network in AWS. These are its building blocks, plus the default and shared variants the course covers.

| Component | What it is | Exam hook |
| --- | --- | --- |
| Internet Gateway (IGW) | Connects the VPC to the public internet, inbound and outbound | Needed for a subnet to be public |
| VPN Gateway (VGW) | Connects the VPC to an on-premises network over an encrypted VPN | Pairs with a Customer Gateway on your side |
| Route table | Rules deciding where a subnet's traffic goes | One per subnet association |
| NAT Gateway | Lets private-subnet resources reach the internet outbound only | Sits in a public subnet |
| NACL | Stateless firewall at subnet level | Allow and deny rules |
| Security group | Stateful firewall at the instance/ENI level | Allow rules only |
| Public subnet | Has a route to an IGW; resources need a public IP to reach the internet |  |
| Private subnet | No direct route to an IGW; not reachable directly from the internet |  |
| VPC endpoint | Private access to supported AWS services without the public internet | Interface, gateway, GWLB types |
| VPC peering | Private connection between two VPCs using private IPs | Not transitive |
| Network interface (ENI) | The virtual network card an instance's security group attaches to | Every EC2 has one |

**Default VPC.** Every region comes with one. Its default route (catch-all) is `0.0.0.0/0` for IPv4 and `::/0` for IPv6, pointing at the IGW. You can delete it and recreate it (follow-along in the course).

**Shared VPC (via AWS RAM).** You share subnets, not the whole VPC, with other accounts in the organization using Resource Access Manager. Participants launch resources into those subnets; the owner account manages the VPC itself.

## 3. Firewalls: NACL vs security group (stateless vs stateful)

Security groups are stateful and instance-level; NACLs are stateless and subnet-level. This pair is the most tested comparison in the VPC domain.

|  | Security group | Network ACL (NACL) |
| --- | --- | --- |
| Level | Instance / ENI | Subnet |
| State | Stateful: reply traffic is allowed automatically | Stateless: inbound and outbound are checked separately (two-way check) |
| Rule types | Allow only | Allow and deny |
| Evaluation | All rules evaluated; any allow wins | Rules in number order; first match wins |
| Applies to | Only instances it is attached to | Every resource in the subnet |

**Key facts to memorize**

- An instance can belong to multiple security groups.
- Security group rules are permissive: if one group denies and another allows, allow wins (there is no explicit deny in an SG).
- Stateful means one-way check: you only define the inbound rule and the response is let out.
- Stateless means two-way check: you need an inbound rule and a matching outbound rule.
- Order in the path: Internet, NACL of subnet, Security Group on EC2 ENI, EC2. Reverse on the way out.

## 4. Route tables and route targets

A route table holds the rules that decide where a subnet's traffic goes; the target you pick defines what kind of subnet it is. A subnet with a route to an IGW is public.

| Target | Sends traffic out to |
| --- | --- |
| Local | Default route that lets subnets in the VPC reach each other |
| Internet Gateway (IGW) | The internet, ingress and egress, IPv4 and IPv6 |
| Virtual Private Gateway (VGW) | A private connection to an on-premises network |
| NAT Gateway | The internet, egress only, for private instances (IPv4) |
| Egress-Only Internet Gateway | The internet, egress only, for private instances (IPv6) |
| Instance | A specific EC2 instance |
| Network Interface (ENI) | A specific Elastic Network Interface |
| Carrier Gateway | AWS-partnered telecom carrier networks via AWS Wavelength |
| Core Network | Managed WAN via AWS Cloud WAN |
| Gateway Load Balancer Endpoint | A Gateway Load Balancer (GWLB), used for third-party virtual appliances |
| Outposts Local Gateway | An Outpost, a physical AWS rack in your own datacenter |
| Peering Connection | Another VPC |
| Transit Gateway (TGW) | A transit hub connecting multiple VPCs and on-premises networks |

## 5. VPC to the internet (public)

Everything in this section is public by nature, because the destination is the internet. There is no private option here.

| Service | What it does | Direction / IP version |
| --- | --- | --- |
| Internet Gateway (IGW) | Lets a public subnet talk to the internet | Two-way, IPv4 and IPv6 |
| NAT Gateway | Lets a private subnet reach the internet; no inbound connections | Outbound only, IPv4 |
| Egress-Only Internet Gateway | Same idea as NAT, for IPv6 | Outbound only, IPv6 |
| NAT Instance | Older, self-managed alternative to the NAT Gateway | Outbound only, IPv4 |
| Elastic IP (EIP) | A fixed public IPv4 address you attach to an instance or ENI | n/a |
| Bastion / jumpbox host | Public entry point used to reach instances in private subnets | Inbound admin access |
|  |  |  |

**Easy mix-ups:** IGW is two-way and IPv4 plus IPv6; NAT Gateway is IPv4 outbound only; the Egress-Only IGW is the IPv6 equivalent of NAT.

**To add while watching:** Elastic IP cost and remap behavior, how AWS supports IPv6 in a VPC, the steps for migrating from IPv4 to IPv6, NAT Gateway vs NAT Instance differences, and how a bastion is secured.

## 6. On-premises to VPC

Two families: an encrypted tunnel over the public internet, or a dedicated private line. Transit Gateway ties several of these together.

### 6a. Over the public internet (encrypted)

| Service | What it is |
| --- | --- |
| Site-to-Site VPN | Encrypted VPN between your on-premises network and your VPC |
| Virtual Private Gateway (VGW) | AWS-side endpoint of the Site-to-Site VPN, attached to the VPC |
| Customer Gateway | Your side of the Site-to-Site VPN, in your on-premises network |
| AWS Client VPN | VPN access for individual users connecting to AWS |

### 6b. Private (dedicated line, not over the internet)

| Service | What it is |
| --- | --- |
| Direct Connect | Dedicated fiber connection from a co-location data center to AWS |
| Direct Connect Gateway | The endpoint that connects that fiber link to your VPCs |

### 6c. Hub for many networks

| Service | What it is |
| --- | --- |
| Transit Gateway (TGW) | Hub-and-spoke hub that connects many VPCs and on-premises networks (VPN or Direct Connect) |

**To add while watching:** speed and latency differences, setup time, and why Direct Connect plus VPN is the common backup pattern.

## 7. VPC to AWS services (S3, DynamoDB, SQS and so on)

| Path | How | When |
| --- | --- | --- |
| Public (over the internet) | IGW, or a NAT Gateway from a private subnet, to the service's public endpoint | Default, no extra setup |
| Private: gateway endpoint | VPC gateway endpoint (route-table entry) | S3 and DynamoDB only |
| Private: interface endpoint | Powered by PrivateLink | Most other AWS services |
| Private: GWLB endpoint | Powered by PrivateLink | Sending traffic through firewalls, intrusion detection or deep packet inspection appliances |

**Exam hook:** if the question says S3 or DynamoDB privately from a VPC, the answer is a gateway endpoint. Any other service, interface endpoint. Inspecting traffic with a third-party appliance, GWLB endpoint.

**To add while watching:** how interface endpoints use ENIs with private IPs, and the cost difference between endpoint types.

## 8. VPC to other VPCs (private)

| Service | Scope |
| --- | --- |
| VPC Peering | Private connection between two VPCs over private IPs; one-to-one, not transitive |
| Transit Gateway | Hub connecting many VPCs |
| PrivateLink | Exposes one service privately to other VPCs |
| VPC Lattice | Service-to-service networking across VPCs; fill in details from the course |
| Shared VPC (RAM) | Share subnets with other accounts (covered in section 2) |

## 9. Inspection, monitoring and other gateways

These do not connect networks. They filter, inspect or watch traffic.

| Service | What you know so far | Fill in from the course |
| --- | --- | --- |
| NACL and security groups | Covered in section 3 | n/a |
| AWS Network Firewall | Listed in the course | Purpose |
| VPC Flow Logs | Listed in the course | What it captures, where it goes |
| Traffic Mirroring | Listed in the course | Purpose |
| Network Address Usage | Listed in the course | Purpose |

**Other "gateways" that are not VPC connections**

| Gateway | What it does |
| --- | --- |
| Amazon API Gateway | Abstracts API endpoints to backend services |
| AWS Storage Gateway | Syncs, caches or extends local storage to cloud storage |
| AWS Backup Gateway | Endpoint for AWS-managed backups |
| IoT Device Gateway | Sends IoT data in both directions |
| Carrier Gateway | Connects to an AWS-partnered telecom network |

## 10. Exam cheat sheet and course checklist

**Quick answers**

- Stateful = security group. Stateless = NACL.
- Allow and deny rules = NACL. Allow only = security group.
- Private IPv4 outbound = NAT Gateway. Private IPv6 outbound = Egress-Only IGW.
- Private access to S3 or DynamoDB = gateway endpoint. Other AWS services = interface endpoint.
- Third-party firewall or inspection appliance = Gateway Load Balancer (endpoint).
- Many VPCs plus on-premises = Transit Gateway.
- On-premises over encrypted internet = Site-to-Site VPN (VGW plus Customer Gateway). Dedicated fiber = Direct Connect.
- Share a subnet with another account = shared VPC through RAM.
- Every EC2 reads its own metadata at a special link-local IP address (note the exact address from the lecture).

**Course checklist (SAA-C03 VPC section, with the section above where each belongs)**

- [ ] 12:19:34 VPC (section 1)
- [ ] 12:21:36 Core Components of VPC (section 2)
- [ ] 12:24:09 Key Features of VPC (section 2)
- [ ] 12:26:09 VPC Follow Along (section 2)
- [ ] 13:41:24 Default VPC (section 2)
- [ ] 13:44:15 Deleting VPC (section 2)
- [ ] 13:45:05 Default Route 0.0.0.0/0 and ::/0 (section 2)
- [ ] 13:46:41 Delete and Recreate Default VPC Follow Along (section 2)
- [ ] 13:48:30 Shared VPC via RAM (sections 2 and 8)
- [ ] 13:50:05 Shared VPC Follow Along (sections 2 and 8)
- [ ] 14:09:06 NACLs (section 3)
- [ ] 14:12:28 NACL Follow Along (section 3)
- [ ] 15:10:40 Security Groups (section 3)
- [ ] 15:15:40 Security Groups Follow Along (section 3)
- [ ] 15:24:02 Stateless vs Stateful (section 3)
- [ ] 15:28:36 Route Tables (section 4)
- [ ] 15:35:28 Route Tables Follow Along (section 4)
- [ ] 15:37:58 Gateways (sections 5 and 6)
- [ ] 15:42:57 IGW (section 5)
- [ ] 15:44:29 IGW Follow Along (section 5)
- [ ] 15:47:12 EO-IGW (section 5)
- [ ] 15:48:26 EO-IGW Follow Along (section 5)
- [ ] 16:07:47 EIP (section 5)
- [ ] 16:13:17 EIP Follow Along (section 5)
- [ ] 16:18:40 AWS IPv6 Support (section 5)
- [ ] 16:19:51 Migrating from IPv4 to IPv6 (section 5)
- [ ] 16:21:11 Direct Connect (section 6b)
- [ ] 16:27:12 VPC Endpoints (section 7)
- [ ] 16:28:48 Private Link (sections 7 and 8)
- [ ] 16:31:48 Interface Endpoints (section 7)
- [ ] 16:33:34 GWLB Endpoint (section 7)
- [ ] 16:35:09 VPC Gateway Endpoints (section 7)
- [ ] 16:36:09 VPC Endpoints Comparison (section 7)
- [ ] 16:38:56 VPC Flow Logs (section 9)
- [ ] 16:40:51 AWS VPN (section 6a)
- [ ] 16:42:01 AWS Site-to-Site VPN (section 6a)
- [ ] 16:46:07 VGW (section 6a)
- [ ] 16:47:32 Customer Gateway (section 6a)
- [ ] 16:49:59 TGW (section 6c)
- [ ] 16:50:56 AWS Client VPN (section 6a)
- [ ] 16:53:14 NAT (section 5)
- [ ] 16:54:50 NAT Gateway (section 5)
- [ ] 16:58:25 NAT Instances (section 5)
- [ ] 17:00:07 Jumpbox/Bastion host (section 5)
- [ ] 17:02:37 VPC Lattice (section 8)
- [ ] 17:06:07 TGW More Detail (sections 6c and 8)
- [ ] 17:09:07 Traffic Mirroring (section 9)
- [ ] 17:10:10 AWS Network Firewall (section 9)
- [ ] 17:11:33 VPC Peering (section 8)
- [ ] 17:14:16 VPC Peering Follow Along (section 8)
- [ ] 17:30:26 Network Address Usage (section 9)
