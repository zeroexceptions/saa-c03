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



## shared vpc
## Nacl's