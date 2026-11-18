# EC2 Networking: NIC, ENI, ENA, EFA, and Elastic IP

These names sound similar, but they refer to different parts of EC2 networking. For the SAA-C03 exam, start by asking: **Do I need an IP/network identity, faster ordinary networking, specialized HPC networking, or a stable public IP?**

## Quick comparison

| Term | What it is | What it is useful for |
|---|---|---|
| **NIC** | A generic network interface card: the device through which a computer sends and receives network traffic. | General computer/networking vocabulary. In EC2 questions, AWS usually describes the virtual interface as an **ENI**. |
| **ENI** | Elastic Network Interface: a virtual network card in a VPC, with private IP addresses, a MAC address, security groups, and subnet placement. | Keeping a network identity (including private IPs and security groups) available to attach to another compatible EC2 instance after failure. |
| **ENA** | Elastic Network Adapter: AWS's high-performance network device for regular IP networking (TCP/IP). It is supported by many modern instance types and commonly uses the ENA driver. | High throughput and high packet-per-second networking for ordinary application traffic. |
| **EFA** | Elastic Fabric Adapter: a specialized network device for tightly coupled HPC and distributed ML workloads. It uses OS-bypass/SRD capabilities for low-latency communication between instances. | MPI-based simulations, distributed machine learning, and other workloads with intensive instance-to-instance communication. |
| **EFA with ENA** | An interface that supports both ordinary ENA TCP/IP networking and EFA communication. | An HPC instance that needs normal IP traffic as well as EFA's specialized inter-node communication. |
| **EFA-only** | An EFA interface without ordinary IP networking support on that interface. | Specialized EFA communication where that interface does not need regular IP traffic. It does not have IP addresses. |
| **Elastic IP (EIP)** | A static, public IPv4 address allocated to your AWS account. It can be associated or reassociated with a supported network interface/resource. | Keeping a public IPv4 address stable when replacing an internet-facing instance. It is not a private IP and does not make a private-subnet instance directly internet reachable. |

## NIC versus ENI

**NIC** is the general computing term for a network card. An EC2 instance presents virtual network devices to its operating system. In AWS VPC terminology, the key resource is the **ENI**: a virtual interface that AWS creates and manages.

An ENI can have one or more private IPv4 addresses, a MAC address, security groups, and a subnet/AZ association. The primary ENI is created for the instance and cannot be detached. Secondary ENIs can be detached and attached to another instance, subject to instance-type and Availability Zone constraints.

Think of the ENI as a **movable network identity**. The instance is the compute; the ENI carries network settings and addresses.

## ENA: ordinary high-performance networking

ENA is the network adapter technology used for high-performance, standard IP traffic. Web servers, APIs, databases, and most EC2 applications use ordinary TCP/IP networking; they do not need EFA just because they need good network performance.

**Scenario:** A web service needs high throughput and many packets per second between EC2 and clients or other AWS services. Choose an ENA-capable instance type and ensure the OS/AMI has the required ENA driver. ENA improves the instance's networking capability; it does not give the application a movable IP identity by itself.

## EFA: low-latency communication between compute nodes

EFA is for applications that communicate heavily with other EC2 instances and can use supported HPC/ML communication libraries. It is not a general-purpose replacement for ENI or ENA. EFA support depends on the instance type and software configuration.

**Scenario:** A researcher runs a distributed MPI simulation across a cluster, or trains a model distributed across GPUs and needs fast, low-latency node-to-node communication. Choose EFA-capable instances and configure EFA. If the same interface also needs normal TCP/IP traffic, use **EFA with ENA**. For a regular dashboard, website, or database, EFA is usually unnecessary.

## Elastic IP: stable public IPv4

An EIP is a public, static IPv4 address. You can associate it with an instance or network interface and reassociate it during recovery. In an HA design, automation (or an appropriate service/orchestration pattern) must detect failure and perform the reassociation; an EIP does not automatically fail over on its own.

**Scenario:** A legacy internet-facing service must keep the same public IPv4 address when its EC2 host is replaced. Use an EIP and automate reassociation to the replacement. If clients use a DNS name and can tolerate DNS-based routing/failover, Route 53 or a load balancer may be a better front door depending on the requirements.

An EIP is **not** the answer when a domain points to a private IPv4 address inside a VPC. A public EIP is not a substitute for private addressing and does not bypass subnet routes, security groups, or other network controls.

## Failover with a secondary ENI or secondary private IP

Suppose a private dashboard's DNS record resolves to a private IPv4 address, and that address must remain the same when the EC2 instance is replaced.

Two related approaches are:

1. **Secondary ENI:** Put the stable private address and required security groups on a secondary ENI. On failure, detach that ENI from the failed instance and attach it to a standby instance in the **same Availability Zone**. The DNS record continues to point to the ENI's private IP. The standby must be compatible with the interface and ready to serve traffic.
2. **Secondary private IP:** Assign a secondary private IPv4 address and move/reassign it to the standby's interface during recovery. This can be simpler when only the address needs to move and the rest of the interface configuration does not.

The primary private IPv4 address of an instance's primary ENI is not movable by detaching that primary ENI. Use a **secondary** ENI or **secondary** private IPv4 address when you need a movable private identity.

**Exam scenario:** A Spot instance hosts a private dashboard, and internal DNS points to a private address that must be reused after termination. A secondary ENI (or a movable secondary private IP) with failover automation is the relevant pattern. EFA is unrelated, and an EIP is public-facing. Remember: a secondary ENI is AZ-bound, so this specific ENI move is for a standby in the same AZ; cross-AZ recovery needs another design, such as updating private DNS to a suitable address or using a load-balancing/failover architecture.

## Exam memory cues

- **Need to move private IPs/security groups/network identity with failover?** Secondary ENI.
- **Need only a movable private IPv4 address?** Secondary private IP.
- **Need a stable public IPv4 address?** Elastic IP, with reassociation as part of failover.
- **Need high-performance ordinary TCP/IP?** ENA-capable instance / ENA.
- **Need low-latency HPC or distributed ML node-to-node communication?** EFA; use EFA with ENA when ordinary IP networking is also needed.
- **Primary ENI?** It cannot be detached. Secondary ENIs can be moved, within AWS placement/instance constraints.

## AWS references

- [Elastic network interfaces](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html)
- [Multiple network interfaces and failover scenarios](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/scenarios-enis.html)
- [Create a network interface and choose ENA/EFA interface types](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-network-interface.html)
- [Elastic Fabric Adapter](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/efa.html)
- [EC2 IP addressing](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-instance-addressing.html)
