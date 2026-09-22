# AWS VPC — SAA-C03 Study Guide

This guide reorganizes the VPC topics in this folder for the **AWS Certified Solutions Architect – Associate (SAA-C03)** exam. It explains what each service does, where it belongs, and the common exam decisions behind it.

---

## 1. VPC foundations

### Amazon VPC

An **Amazon Virtual Private Cloud (VPC)** is a logically isolated virtual network in an AWS Region. You choose its IPv4/IPv6 address ranges and control its subnets, routing, and network security.

| Component | What it is | Key point |
|---|---|---|
| CIDR block | The IP address range assigned to a VPC, such as `10.0.0.0/16`. | Plan address space before building; CIDR ranges must not overlap for VPC peering. |
| Subnet | A range of IP addresses within one Availability Zone (AZ). | A subnet cannot span AZs. Use multiple AZs for high availability. |
| Route table | Rules that select the next hop for traffic from associated subnets. | Every subnet is associated with one route table at a time. |
| Elastic network interface (ENI) | A virtual network interface attached to an AWS resource, commonly EC2. | It has private IPs, security groups, MAC address, and optional Elastic IP. |
| Elastic IP (EIP) | A static public IPv4 address allocated to your account. | Use sparingly; AWS charges for public IPv4 addresses. |

### Default VPC and custom VPC

| Type | Use |
|---|---|
| Default VPC | AWS-created VPC intended for quick starts. Default subnets usually assign public IPv4 addresses to launched instances. |
| Custom VPC | A VPC you design with its own CIDR ranges, subnet tiers, and routing. This is the usual architecture for production workloads. |

### Public versus private subnet

A subnet is **public** when its route table contains a route to an **Internet Gateway (IGW)**. A subnet is **private** when it has no direct route to an IGW. An EC2 instance also needs a public IPv4 address or EIP to communicate directly with the internet over IPv4.

Typical three-tier layout:

```text
Internet
   |
Internet Gateway
   |
Public subnets: ALB, NAT Gateway, bastion host
   |
Private application subnets: EC2, ECS, Lambda ENIs
   |
Private data subnets: RDS, ElastiCache
```

> “Public/private” is determined by the **route table**, not by the subnet name or by whether an EC2 instance currently has a public IP.

---

## 2. Routing and route targets

### Route tables

A route consists of a **destination** CIDR/prefix list and a **target** (next hop). AWS chooses the most specific matching route. Each route table includes an immutable **local route** that enables communication inside the VPC CIDR.

| Route | Meaning |
|---|---|
| `10.0.0.0/16 → local` | Communication between subnets in the same VPC. |
| `0.0.0.0/0` | IPv4 default route (catch-all route). |
| `::/0` | IPv6 default route. |

### Important route targets

| Category | Target | Primary use |
|---|---|---|
| Internet access | Internet Gateway (IGW) | Public IPv4 and IPv6 ingress/egress. |
| Internet access | NAT Gateway | IPv4 outbound internet access from private subnets. |
| Internet access | Egress-only Internet Gateway | IPv6 outbound-only internet access from private subnets. |
| AWS services | Gateway VPC endpoint | Private route-table access to Amazon S3 or DynamoDB. |
| AWS services | Interface VPC endpoint | PrivateLink-based private access to supported AWS services, partner services, or endpoint services. |
| Inspection | Gateway Load Balancer endpoint (GWLBE) | Route traffic through security appliances behind a Gateway Load Balancer. |
| VPC connectivity | VPC peering connection | Private routing to one peered VPC. |
| VPC connectivity | Transit Gateway (TGW) | Hub-based routing between many VPCs and on-premises networks. |
| Hybrid connectivity | Virtual private gateway (VGW) | AWS-side VPN attachment for a Site-to-Site VPN. |
| Hybrid connectivity | Direct Connect gateway | Connect Direct Connect virtual interfaces to VPCs/VPNs across Regions. |
| Hybrid connectivity | Customer gateway | On-premises VPN device representation; used when creating Site-to-Site VPN, not a normal subnet route target. |
| Advanced | ENI or EC2 instance | Send traffic to a specific network appliance. |
| Advanced | Carrier Gateway | Access carrier networks from AWS Wavelength Zones. |
| Advanced | Core Network | Connect to AWS Cloud WAN. |
| Advanced | Outposts local gateway | Route between an AWS Outpost and the local network. |

---

## 3. Network security

### Security groups (resource-level security)

A **security group (SG)** is a virtual firewall attached to an ENI, for example an EC2 instance, load balancer, RDS database, or Lambda ENI.

| Property | Security group |
|---|---|
| Scope | Resource / ENI level |
| State | **Stateful** — return traffic is automatically allowed. |
| Rules | Allow rules only; no explicit deny rules. |
| Evaluation | All associated security groups are combined. |
| Best practice | Reference another security group instead of fixed IP addresses when allowing traffic between application tiers. |

### Network ACLs (subnet-level security)

A **network access control list (NACL)** is an optional firewall at the subnet boundary.

| Property | Network ACL |
|---|---|
| Scope | Subnet level |
| State | **Stateless** — inbound and outbound rules must both allow a connection. |
| Rules | Allow and deny rules, evaluated in ascending rule-number order; first match wins. |
| Association | A subnet can be associated with one NACL; one NACL can protect many subnets. |
| Best use | Broad subnet guardrails or explicitly blocking a CIDR/IP range. |

### Stateful versus stateless traffic flow

```text
Inbound:  Internet → NACL (subnet) → Security group (ENI) → EC2
Outbound: EC2 → Security group (ENI) → NACL (subnet) → Internet
```

For an internet-facing web server, allow the client request in the inbound rules. Because SGs are stateful, response traffic is automatically allowed by the SG. Because NACLs are stateless, the NACL must also permit the appropriate outbound ephemeral-port response traffic.

### Other network-security services

| Service | Category | Use |
|---|---|---|
| AWS Network Firewall | Managed network firewall | Stateful, stateful-rule, and intrusion-prevention filtering for VPC traffic. |
| Gateway Load Balancer (GWLB) | Service insertion / load balancing | Deploy and scale third-party virtual appliances such as firewalls and IDS/IPS. |
| AWS WAF | Application-layer protection | Protect CloudFront, ALB, API Gateway, and other supported web endpoints from web exploits. |
| Traffic Mirroring | Packet inspection | Copy EC2 ENI traffic to monitoring or security appliances. |

---

## 4. Internet connectivity and egress

### Internet Gateway (IGW)

An **IGW** is attached to one VPC and enables public IPv4 and IPv6 traffic between that VPC and the internet. It is horizontally scaled and highly available. Public subnets route `0.0.0.0/0` and/or `::/0` to it.

### NAT Gateway

A **NAT Gateway** gives resources with private IPv4 addresses outbound access to the internet or AWS public services, while preventing unsolicited inbound connections from the internet.

- Deploy it in a **public subnet** with a route to an IGW and associate an EIP.
- Private-subnet route table: `0.0.0.0/0 → NAT Gateway`.
- For high availability, deploy one NAT Gateway per AZ and route each private subnet to the NAT Gateway in the same AZ.
- A NAT Gateway does **not** support IPv6 traffic.

### Egress-only Internet Gateway

An **egress-only IGW** is the IPv6 equivalent of outbound-only internet connectivity. Private IPv6 subnets route `::/0` to it. It allows outbound IPv6 connections and return traffic, but blocks unsolicited inbound connections.

### Bastion host / jump box

A **bastion host** is a hardened administrative host, normally in a public subnet, used to reach private instances. On the exam, consider **AWS Systems Manager Session Manager** when you need administrative access without opening inbound SSH/RDP or maintaining a bastion.

---

## 5. Private access to AWS services: VPC endpoints and PrivateLink

VPC endpoints let workloads access supported services privately, without an IGW, NAT Gateway, VPN, or Direct Connect connection.

| Endpoint type | Technology | Network placement | Supports | Exam distinction |
|---|---|---|---|---|
| Gateway endpoint | VPC route-table target | No ENIs; associated with route tables | **Amazon S3 and DynamoDB only** | No hourly charge; use when private S3/DynamoDB access is required. |
| Interface endpoint | AWS PrivateLink | One or more endpoint ENIs in chosen subnets; protected by SGs | Many AWS services, Marketplace/partner services, and your own endpoint services | Has hourly and data-processing charges; can enable private DNS. |
| GWLB endpoint | AWS PrivateLink | Endpoint ENIs / route target | Gateway Load Balancer appliances | Use to transparently steer traffic to inspection appliances. |

### AWS PrivateLink

**PrivateLink** is the underlying private service-connectivity technology used by interface endpoints and GWLB endpoints. It exposes a service through private IP connectivity without granting full network connectivity between VPCs.

### Interface endpoint versus gateway endpoint

| If the requirement says… | Choose… |
|---|---|
| Private connectivity to S3 or DynamoDB from a VPC | Gateway VPC endpoint. |
| Private connectivity to most other AWS services | Interface VPC endpoint. |
| Privately expose or consume a service across VPC/account boundaries without peering | PrivateLink / interface endpoint. |
| Insert a firewall appliance into the network path | GWLB + GWLB endpoint. |

---

## 6. VPC-to-VPC and multi-account connectivity

### VPC peering

**VPC peering** creates a private connection between two VPCs. Route tables on both sides must be updated, and the VPC CIDR ranges cannot overlap.

- Peering is **non-transitive**: if VPC A peers with B and B peers with C, A cannot automatically reach C.
- Peering can be cross-account and cross-Region.
- Use a Transit Gateway when many VPCs must communicate through a central hub.

### AWS Transit Gateway (TGW)

A **Transit Gateway** is a regional network transit hub. Attach VPCs, VPN connections, and Direct Connect gateways to simplify many-to-many connectivity.

| Good fit | Why |
|---|---|
| Many VPCs/accounts | Hub-and-spoke design avoids a large peering mesh. |
| VPC and on-premises connectivity | Centralizes hybrid routing. |
| Segmented networks | TGW route tables control which attachments can communicate. |

### Shared VPC (AWS RAM)

With **AWS Resource Access Manager (RAM)**, a VPC owner can share selected subnets with other accounts in AWS Organizations. Participant accounts can launch resources into shared subnets, while the owner retains control of the VPC, subnets, route tables, and NACLs.

---

## 7. Hybrid networking: on-premises to AWS

### AWS Site-to-Site VPN

**Site-to-Site VPN** provides encrypted IPsec tunnels between an on-premises network and AWS over the public internet.

| Component | Belongs to | Role |
|---|---|---|
| Customer Gateway (CGW) | On-premises side | AWS representation of the customer VPN device and its public IP. |
| Virtual Private Gateway (VGW) | AWS VPC side | VPN endpoint attached to one VPC. |
| Transit Gateway | AWS hub side | Can terminate VPN connections for multiple attached VPCs. |

AWS creates two VPN tunnels for availability. Use BGP/dynamic routing when possible.

### AWS Direct Connect

**Direct Connect (DX)** is a dedicated private network connection between an on-premises location and AWS through a DX location/provider. It generally offers more consistent connectivity than an internet-based VPN, but it is **not encrypted by default**.

- Add Site-to-Site VPN over Direct Connect when encryption is required.
- Use a **Direct Connect gateway** to connect virtual interfaces to multiple VPCs or a Transit Gateway.
- Common exam pattern: Direct Connect for steady high-bandwidth hybrid traffic; VPN for quick setup, encrypted internet connectivity, or a backup path.

### AWS Client VPN

**Client VPN** is a managed, client-based VPN for individual users/devices that need remote access to VPC and on-premises resources. It is different from Site-to-Site VPN, which connects entire networks.

---

## 8. Observability and troubleshooting

### VPC Flow Logs

**VPC Flow Logs** capture metadata about IP traffic to and from network interfaces. Publish logs to Amazon CloudWatch Logs or Amazon S3.

| Can be created for | Use |
|---|---|
| VPC, subnet, or ENI | Troubleshoot accepted/rejected network traffic, investigate security groups/NACLs, and audit network patterns. |

Flow Logs record metadata such as source/destination IPs, ports, protocol, bytes, and whether traffic was accepted or rejected. They do **not** capture packet payloads.

### Common troubleshooting order

1. Confirm the resource IP addressing and subnet route table.
2. Check the correct route target and return path.
3. Check security group inbound/outbound rules.
4. Check NACL inbound/outbound rules and ephemeral ports.
5. Use VPC Flow Logs to see whether traffic is accepted or rejected.
6. Check application health, DNS, and host-based firewall settings.

---

## 9. Additional SAA-C03 networking topics

| Service / feature | Category | What to remember |
|---|---|---|
| VPC Lattice | Application networking | Connect, secure, and observe service-to-service communication across VPCs and accounts; designed for application-layer services. |
| Network Address Usage (NAU) | Capacity management | Measures consumption of networking resources in a VPC; use it to monitor VPC scale and quotas. |
| IPv6 | Addressing | AWS VPC IPv6 CIDR blocks are /56; subnets are /64. IPv6 is globally routable, so control access with routes, SGs, and NACLs. |
| IPv4-to-IPv6 migration | Addressing | Use dual stack while workloads and clients transition; NAT Gateway is IPv4 only, use egress-only IGW for private IPv6 egress. |
| NAT instance | Legacy/self-managed NAT | An EC2-based NAT option. It requires disabling source/destination checks and managing availability, scaling, patching, and throughput. Prefer NAT Gateway unless a requirement dictates otherwise. |

---

## 10. High-value SAA-C03 decision guide

| Requirement | Best answer / concept |
|---|---|
| Public web application load balancer | ALB in public subnets across at least two AZs, with an IGW route. |
| Private EC2 needs software updates over IPv4 | NAT Gateway in a public subnet; route private subnet IPv4 default route to NAT Gateway. |
| Private IPv6 workload needs outbound internet only | Egress-only Internet Gateway. |
| Access S3 privately from a VPC at lowest complexity/cost | Gateway VPC endpoint. |
| Access Secrets Manager, SQS, or another supported AWS service privately | Interface VPC endpoint with private DNS when appropriate. |
| Connect two non-overlapping VPCs | VPC peering, if only a small number of VPCs are involved. |
| Connect many VPCs and on-premises networks | Transit Gateway. |
| Connect on-premises network rapidly and securely over internet | Site-to-Site VPN. |
| Consistent dedicated hybrid network connection | Direct Connect; add VPN if encryption is needed. |
| Block a malicious IP range for an entire subnet | NACL deny rule. |
| Allow web tier to reach database tier | Security group reference between the tiers. |
| Inspect traffic using third-party virtual firewalls | Gateway Load Balancer and GWLB endpoints. |
| Troubleshoot rejected VPC traffic | VPC Flow Logs plus route table, SG, and NACL review. |

---

## 11. Quick exam reminders

- **Security groups are stateful; NACLs are stateless.**
- **NACLs can explicitly deny; security groups cannot.**
- **Gateway endpoints are only for S3 and DynamoDB.**
- **VPC peering is non-transitive; Transit Gateway provides transitive hub routing.**
- **NAT Gateway is for IPv4; Egress-only IGW is for IPv6 outbound-only access.**
- **A subnet lives in one AZ only.**
- **A route alone is not enough:** security groups, NACLs, return routing, and resource IP addressing must also permit traffic.
- Design critical network paths across **at least two Availability Zones**.

## Related hands-on material

- [VPC peering exercise](connect-peering/README.md)
- [Network ACL exercise](nacl/README.md)
- [Security group exercise](sg/README.md)

