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







All important gateways

### What is a Gateway?
A gateway is a networking service that sits between two different networks — often acting as a reverse proxy, firewall, or load balancer.
 
---
 
### Internet Gateway
Inbound and outbound public traffic for IPv4 and IPv6.
 
### Egress-Only Internet Gateway
Outbound-only private traffic for IPv6.
 
### Carrier Gateway
Connects to an AWS-partnered telecom network.
 
### NAT Gateway
Outbound-only private traffic for IPv4.
 
### Virtual Private Gateway
The endpoint into your AWS account for a VPN connection.
 
### Customer Gateway
The endpoint into your on-premises network for a VPN connection.
 
### Gateway Load Balancer (GWLB)
A Layer 3 (network layer) load balancer used to run and scale third-party virtual appliances (e.g., firewalls, IDS/IPS).
 
### Direct Connect Gateway
The endpoint connection to a fiber optic connection at a co-location data center.
 
### AWS Backup Gateway
The endpoint connection for AWS-managed backups.
 
### IoT Device Gateway
The endpoint connection to send IoT data in both directions.
 
### AWS Transit Gateway
A hub-and-spoke model that simplifies VPC peering.
 
### Amazon API Gateway
Abstracts API endpoints to backend services.
 
### AWS Storage Gateway
Syncs, caches, or extends local storage to cloud storage.