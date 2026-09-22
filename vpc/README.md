## Core components of vpc

### IGW

An **Internet Gateway (IGW)** connects a VPC to the public internet for inbound and outbound traffic.

### VPN GATEWAY

A **VPN Gateway** connects a VPC securely to an on-premises network through an encrypted VPN connection.

### ROUTE TABLES

A **route table** contains rules that decide where network traffic from a subnet should go.

### NAT GATEWAY

A **NAT Gateway** lets private-subnet resources access the internet outbound without accepting inbound internet connections.

### NACL

A **Network ACL (NACL)** is a stateless firewall that controls inbound and outbound traffic at the subnet level.

### SECURITY GROUPS

A **security group** is a stateful firewall that controls inbound and outbound traffic for AWS resources such as EC2 instances.

### PUBLIC SUBNETS

A **public subnet** has a route to an Internet Gateway, allowing its resources to reach the internet when they have public IP addresses.

### PRIVATE SUBNETS

A **private subnet** has no direct route to an Internet Gateway, keeping its resources inaccessible directly from the internet.

### VPC ENDPOINTS

A **VPC endpoint** provides private access from a VPC to supported AWS services without using the public internet.

### VPC PEERING

**VPC peering** is a private network connection that lets resources in two VPCs communicate using private IP addresses.

**Network Interface ENI**

## shared vpc (one way check firewall stateful)
## Nacl's (two way check firewall stateless)
##stateful vs stateless


Internet → NACL of subnet → Security Group on EC2 ENI → EC2
EC2 → Security Group → NACL of subnet → Internet

Client browser
  ↓ HTTP request to EC2 public IP
Internet
  ↓
Internet Gateway (attached to the VPC)
  ↓
VPC
  ↓ route table chooses the subnet route
Public subnet
  ↓ inbound rules checked
Network ACL (NACL)
  ↓
EC2 network interface (ENI)
  ↓ inbound rules checked
Security Group
  ↓
EC2 instance / Apache on port 80




Local – The default local route that lets associate subnets within the VPC route to the other route.
Internet Gateway (IGW) ingress and egress connections to the internet for IPv4 and IPv6
Virtual Private Gateway (VPG) — out to a private connection to a on-premise network
NAT Gateway – egress connections for private instances out to the internet for IPv4
Egress Only Internet Gateway — egress connections for private instances out to the internet for IPv6
Instance — out to a specific EC2 instance
Network Interface (ENI) — out to a specific Elastic Network Interface
Carrier Gateway – out to AWS partnered telecom carrier networks via AWS Wavelength
Core Network – out to managed wide-area networking (WAN) via AWS Cloud WAN
Gateway Load Balancer Endpoint — out to a Gateway Load Balancer (GWLB); GWLB is for third-party virtual appliances
Outposts Local Gateway — out to an Outpost, a physical server rack with AWS services in your own datacenter
Peering Connection — out to another Virtual Private Cloud (VPC)
Transit Gateway (TGW) — out to a transit hub for connecting multiple VPCs and on-premises network



# What is a Gateway?

A gateway (in the context of cloud services) is a networking service which
**sits between two different networks**. Gateways often act as reverse
proxies, firewalls, and load balancers.

---

## Networking Gateways

### Internet Gateway
Inbound and outbound public traffic for IPv4 and IPv6.

### Egress-Only Internet Gateway
Outbound private traffic for IPv6.

### Carrier Gateway
Connecting to AWS partnered telecom network.

### NAT Gateway
Outbound private traffic for IPv4.

### Virtual Private Gateway
The endpoint into your AWS account for a VPN connection.

### Customer Gateway
The endpoint into your on-premise account for a VPN connection.

### Gateway Load Balancer (GWLB)
Layer 3 (Network layer) load balancer to run and scale third-party virtual
applications, e.g. Firewalls, IDS/IPS.

---

## Connectivity & Service Gateways

### Direct Connect Gateway
The endpoint connection to a fiber optic connection at a co-location data
center.

### AWS Backup Gateway
The endpoint connection for AWS managed backups.

### IoT Device Gateway
The endpoint connection to send IoT data in both directions.

### AWS Transit Gateway
Hub and spoke model to simplify VPC peering.

### Amazon API Gateway
Abstracts API endpoints to services.

### AWS Storage Gateway
Syncing, caching, or extending local storage to cloud storage.



### AWS direct connect
### VPC endpoints
### Interface Endpoints
### Gateway Load balancers
### vpc gateway endpoints
### aws client vpn
### aws private link
### interface endpoint vs gateway endpoint vs gateway load balancer endpoint
### vpc flow logs
### Virtual Private Network
### aws site to site vpn
### nat gateway
### vpc lattice
### Network Address Usage










### List of topics

12:19:34 VPC
12:21:36 Core Components of VPC
12:24:09 Key Features of VPC
12:26:09 VPC Follow Along
13:41:24 Default VPC
13:44:15 Deleting VPC
13:45:05 Default Route (Catch-All-Route) 0.0.0.0/0 ::/0
13:46:41 Delete & Recreate Default VPC Follow Along
13:48:30 Shared VPC via RAM (sharing subnet)
13:50:05 Shared VPC Follow Along
14:09:06 NACLs
14:12:28 NACL Follow Along
15:10:40 Security Groups
15:15:40 Security Groups Follow Along
15:24:02 Stateless vs Stateful
15:28:36 Route Tables
15:35:28 Route Tables Follow Along
15:37:58 Gateways
15:42:57 IGW (Internet Gateway)
15:44:29 IGW Follow Along
15:47:12 EO-IGW (Egress-Only Internet Gateway)
15:48:26 EO-IGW Follow Along
16:07:47 EIP (Elastic IPs)
16:13:17 EIP Follow Along
16:18:40 AWS IPv6 Support
16:19:51 Migrating from IPv4 to IPv6
16:21:11 Direct Connect
16:27:12 VPC Endpoints
16:28:48 Private Link
16:31:48 Interface Endpoints (powered via PrivateLink)
16:33:34 GWLB (Gateway Load Balancer) Endpoint (powered via PrivateLink)
16:35:09 VPC Gateway Endpoints (private to S3 & DynamoDB)
16:36:09 VPC Endpoints Comparison
16:38:56 VPC Flow Logs
16:40:51 AWS VPN (Virtual Private Network)
16:42:01 AWS Site-to-Site VPN
16:46:07 VGW (Virtual Private Gateway)
16:47:32 Customer Gateway
16:49:59 TGW (Transit Gateway)
16:50:56 AWS Client VPN
16:53:14 NAT (Network Address Translation)
16:54:50 NAT Gateway
16:58:25 NAT Instances
17:00:07 Jumpbox/Bastion host
17:02:37 VPC Lattice
17:06:07 TGW (Transit Gateway) More Detail
17:09:07 Traffic Mirroring
17:10:10 AWS Network Firewall
17:11:33 VPC Peering
17:14:16 VPC Peering Follow Along
17:30:26 Network Address Usage