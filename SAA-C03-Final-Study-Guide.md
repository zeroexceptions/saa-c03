# SAA-C03 — Final Study Guide
### Organized by the 4 Official Exam Domains
 
This is the consolidated master reference — service priority tiers mapped against the official AWS exam blueprint domains, plus the recurring comparison patterns the exam tests repeatedly.
 
---
 
## Exam Domain Weighting (Official Blueprint)
 
| Domain | Weight | Focus |
|---|---|---|
| **1. Design Secure Architectures** | ~30% | IAM, VPC security, encryption, identity |
| **2. Design Resilient Architectures** | ~26% | HA/DR, decoupling, multi-AZ/region, backup |
| **3. Design High-Performing Architectures** | ~24% | Caching, storage/database performance, networking, elasticity |
| **4. Design Cost-Optimized Architectures** | ~20% | Storage classes, pricing models, right-sizing |
 
Most real exam questions **blend 2+ domains at once** (e.g., "cost-effective AND highly available" storage solution) — so the domains below are a lens, not a strict silo.
 
---
 
## Priority Legend
🔴 **Must Know** — study deeply, appears in nearly every exam
🟡 **Useful** — know purpose + when to choose it over its "cousin" service
🟢 **Low Priority** — know the name + one-liner only
 
---
 
# DOMAIN 1: Design Secure Architectures (~30%)
 
### 🔴 Must Know
| Service | What to Know |
|---|---|
| **IAM** | Users, groups, roles, policies (identity vs resource-based), permission boundaries, STS, least privilege |
| **VPC Security** | Security Groups (stateful, allow-only) vs NACLs (stateless, allow+deny, subnet-level) |
| **VPC Endpoints** | Gateway Endpoint (S3, DynamoDB only, free) vs Interface Endpoint/PrivateLink (most other services, paid, uses ENI) |
| **KMS** | Encryption key management, AWS-managed vs customer-managed CMKs, envelope encryption |
| **Secrets Manager** | Auto-rotation of credentials, costs more than Parameter Store |
| **ACM** | Free SSL/TLS certificates for AWS resources (ALB, CloudFront) |
| **WAF** | Layer 7 filtering — SQL injection, XSS rules, rate limiting |
| **Shield** | DDoS protection — Standard (free, automatic) vs Advanced (paid, 24/7 DRT support) |
| **GuardDuty** | Continuous threat detection using ML/anomaly detection on logs |
| **Cognito** | User Pools (authentication) vs Identity Pools (temporary AWS credentials/authorization) |
 
### 🟡 Useful
| Service | Comparison Angle |
|---|---|
| **CloudHSM** | vs KMS — single-tenant, dedicated hardware, full control of keys (compliance-driven use case) vs KMS's shared, AWS-managed service |
| **AWS Inspector** | Automated vulnerability scanning for EC2/ECR images |
| **Amazon Macie** | Discovers sensitive data (PII) in S3 using ML |
| **AWS Security Hub** | Aggregates findings from GuardDuty, Inspector, Macie into one dashboard |
| **AWS Firewall Manager** | Centrally manages WAF/Shield/SG rules across multiple accounts |
| **AWS Directory Service** | Managed Microsoft AD / AD Connector for hybrid identity |
| **Amazon Detective** | Investigates *root cause* after GuardDuty flags something |
| **AWS Audit Manager** | Automates evidence collection for compliance audits |
 
### 🟢 Low Priority
- **AWS Artifact** — portal for compliance reports/agreements (just know it exists)
---
 
# DOMAIN 2: Design Resilient Architectures (~26%)
 
### 🔴 Must Know
| Service | What to Know |
|---|---|
| **EC2 + ASG** | Auto Scaling Groups — scaling policies (target tracking, step, scheduled), health checks, Multi-AZ deployment |
| **ELB** | ALB (Layer 7, path/host routing) vs NLB (Layer 4, static IP, ultra-high performance) |
| **RDS Multi-AZ vs Read Replica** | Multi-AZ = synchronous standby for failover (HA); Read Replica = async copy for scaling reads, can be promoted but isn't automatic failover |
| **Aurora Global Database** | Cross-region DR with <1 sec replication lag, fast regional failover |
| **S3** | Versioning, Cross-Region Replication (CRR), 11 nines durability everywhere |
| **SNS** | Pub/sub, fan-out to multiple subscribers |
| **SQS** | Decoupling — Standard (at-least-once) vs FIFO (exactly-once, ordered); prevents data loss on failure |
| **EventBridge (+ CloudWatch)** | Event-driven routing between services/SaaS; CloudWatch = metrics/alarms/logs |
| **Route 53** | Failover routing policy, health checks |
| **AWS Backup** | Centralized backup policies across services, Vault Lock (WORM) |
| **Storage Gateway** | Bridges on-prem to AWS storage (File, Volume, Tape Gateway) — used in resilience/DR patterns |
 
### 🟡 Useful
| Service | Comparison Angle |
|---|---|
| **DMS** | Database migration with minimal downtime (homogeneous vs heterogeneous w/ SCT) |
| **DataSync** | Automated online transfer between on-prem and AWS (alternative to Snow Family when bandwidth allows) |
| **Snow Family** | Offline data transfer/edge compute when bandwidth is too limited or slow |
| **AWS Auto Scaling** (account-wide) | Scales multiple resources (EC2, DynamoDB, ECS) together via one policy, vs EC2-specific ASG |
| **Step Functions** | Orchestrates resilient multi-step workflows with retry/catch logic |
| **AWS Batch** | Manages batch computing jobs at scale, handles retries/scheduling |
| **Amazon MQ** | Managed message broker — used when migrating legacy apps needing JMS/AMQP protocol support (vs SQS/SNS for AWS-native apps) |
| **Transfer Family** | Managed SFTP/FTPS/FTP directly into S3/EFS |
| **Migration Hub** | Tracks migration progress across multiple AWS migration tools |
| **Health Dashboards** | Personal Health Dashboard = account-specific service health/events |
 
### 🟢 Low Priority
- (covered mostly above — resilience domain has few true "skip" services)
---
 
# DOMAIN 3: Design High-Performing Architectures (~24%)
 
### 🔴 Must Know
| Service | What to Know |
|---|---|
| **EBS** | gp3/gp2 (SSD, general purpose), io1/io2 (high IOPS, Multi-Attach), st1/sc1 (HDD, throughput/cold) |
| **EFS** | Shared NFS storage, Multi-AZ, performance modes (General Purpose/Max I/O), throughput modes |
| **CloudFront** | CDN, edge caching, Origin Access Control (OAC), signed URLs/cookies |
| **ElastiCache** | Redis (persistence, replication, Multi-AZ, HA) vs Memcached (simple, multi-threaded, no persistence/HA) |
| **DynamoDB** | Partition/sort keys, GSI vs LSI, on-demand vs provisioned capacity, DAX (microsecond caching) |
| **Kinesis** | Data Streams (custom real-time processing) vs Firehose (managed delivery to S3/Redshift) |
| **Lambda** | Serverless compute, event triggers, concurrency, cold starts |
| **API Gateway** | Throttling, caching, REST vs HTTP APIs |
| **Athena** | Serverless SQL queries directly on S3, pay-per-query, least overhead for ad-hoc analysis |
| **ECS / ECR / EKS** | Container orchestration concepts — Fargate = serverless containers (no EC2 management) |
| **EC2 Pricing Models** | On-Demand, Reserved, Spot, Savings Plans, Dedicated Hosts — know which fits which workload pattern |
| **Elastic Beanstalk** | PaaS — quick deploy with minimal changes (rehost pattern) |
 
### 🟡 Useful
| Service | Comparison Angle |
|---|---|
| **Global Accelerator** | vs CloudFront — Global Accelerator optimizes for **non-HTTP/TCP-UDP** traffic and static anycast IPs; CloudFront is for **HTTP/HTTPS content caching** |
| **FSx** | vs EFS — FSx for Windows (SMB/Windows-native), FSx for Lustre (HPC/ML workloads), EFS = Linux NFS only |
| **MemoryDB for Redis** | vs ElastiCache — MemoryDB is a durable, Redis-compatible **primary database** (multi-AZ durability built in); ElastiCache Redis is a **cache layer** in front of a separate primary DB |
| **OpenSearch Service** | Search/analytics engine, log analytics, full-text search |
| **AppSync** | Managed GraphQL API layer (real-time data sync for apps) |
| **Redshift** | Data warehousing, columnar storage, Redshift Spectrum (query S3 directly from a cluster) |
| **AWS Glue** | ETL + Data Catalog, often paired with Athena for schema discovery |
| **Compute Optimizer** | ML-based rightsizing recommendations for EC2/EBS/Lambda |
| **DocumentDB** | MongoDB-compatible managed document database (use-case only) |
| **Neptune** | Managed graph database — relationship-heavy data (social networks, fraud detection) |
| **Amazon Keyspaces** | Managed Cassandra-compatible database |
| **Amazon MSK** | Managed Kafka — vs Kinesis: MSK when migrating existing Kafka workloads, Kinesis for AWS-native streaming (light coverage) |
| **Lake Formation** | Simplifies building secure data lakes on S3 (light coverage) |
 
### 🟢 Low Priority
- **Elastic Transcoder / MediaConvert** — video transcoding, niche media use case
- **Amplify** — frontend/mobile app dev framework, not core architecture
- **AppFlow** — SaaS-to-AWS data integration (Salesforce, etc.)
- **ML Managed Services (SageMaker, etc.)** — light on SAA, heavy on ML Specialty
- **AI Dev Tools (CodeWhisperer/Q)** — not architecture-relevant
---
 
# DOMAIN 4: Design Cost-Optimized Architectures (~20%)
 
### 🔴 Must Know
| Service | What to Know |
|---|---|
| **S3 Storage Classes** | Standard → IA → One Zone-IA → Glacier tiers → Deep Archive; lifecycle policies automate cost savings |
| **EC2 Pricing Models** | Spot (cheapest, interruptible) vs Reserved/Savings Plans (steady-state discount) vs On-Demand (flexible, most expensive) |
| **Auto Scaling** | Right-sizing capacity automatically avoids over-provisioning |
| **Gateway Endpoints** | Free — avoids NAT Gateway data processing charges for S3/DynamoDB traffic |
| **AWS Backup lifecycle** | Transition backups to cold storage automatically |
 
### 🟡 Useful
| Service | Comparison Angle |
|---|---|
| **Compute Optimizer** | Recommends rightsizing to cut waste |
| **Trusted Advisor** | Flags cost, security, performance, fault-tolerance issues (some checks require Business/Enterprise support) |
| **AWS Cost Explorer / Budgets** | (Not in your list, but exam-adjacent) — visualize and alert on spend |
| **Snow Family vs DataSync** | Cost/time trade-off — physical shipping vs network transfer, based on bandwidth math |
| **NAT Gateway vs NAT Instance** | NAT Gateway = managed but hourly + data cost; NAT Instance = cheaper but self-managed (rarely the "best" answer now) |
 
### 🟢 Low Priority
- **Service Catalog** — governs self-service resource provisioning (cost-control adjacent, light coverage)
- **AWS Data Exchange** — subscribing to third-party data products (rarely tested)
---
 
## Non-Service Notes
- **Introduction / Setup (course sections)** — do once, not exam content, don't rewatch.
- **"AWS API" section** — skim unless it covers **IAM/SigV4 request signing basics**, which occasionally appears in security-adjacent questions.
---
 
## High-Frequency Comparison Pairs (The Exam's Favorite Trap Pattern)
 
| Pair | The One Distinguishing Fact |
|---|---|
| **SQS vs SNS** | SQS = queue, pull-based, one consumer processes each message; SNS = pub/sub, pushes to many subscribers at once |
| **Redis vs Memcached** | Redis = persistence + replication + Multi-AZ (HA); Memcached = simple, multi-threaded, no persistence |
| **EFS vs EBS** | EFS = shared, multi-instance, Multi-AZ; EBS = single-instance, AZ-locked |
| **Multi-AZ vs Read Replica** | Multi-AZ = HA/failover (same data, standby); Read Replica = scales reads (separate endpoint, async) |
| **Security Group vs NACL** | SG = stateful, instance-level, allow-only; NACL = stateless, subnet-level, allow + deny |
| **Gateway vs Interface Endpoint** | Gateway = free, S3/DynamoDB only, route table-based; Interface = paid, most services, ENI-based |
| **NAT Gateway vs Internet Gateway** | NAT = outbound-only for private subnets; IGW = two-way for public subnets |
| **CloudFront vs Global Accelerator** | CloudFront = HTTP/HTTPS content caching; Global Accelerator = TCP/UDP, non-HTTP, static IP use cases |
| **KMS vs CloudHSM** | KMS = shared/managed service; CloudHSM = dedicated, single-tenant hardware for strict compliance |
| **MemoryDB vs ElastiCache** | MemoryDB = durable primary database; ElastiCache = cache layer in front of a separate database |
| **DMS homogeneous vs heterogeneous** | Same engine = DMS alone; different engine = DMS + Schema Conversion Tool (SCT) |
 
---
 
---
 
## Appendix: Flat Priority List (Quick Scan Version) of the course topics.
 
For a fast top-to-bottom review without domain grouping — use this as a checklist.
 
### 🔴 HIGH Priority — Core exam topics, study deeply
- Amazon S3
- VPC
- IAM
- EC2
- AMIs
- ASG (Auto Scaling Group)
- ELB
- Route 53
- CloudFront
- EBS
- EFS
- SNS
- SQS
- CloudWatch and EventBridge
- Lambda
- Elastic Beanstalk
- ElastiCache
- CloudTrail
- Redshift
- Athena
- AWS Glue
- API Gateway
- RDS
- Aurora
- DynamoDB
- ECR
- ECS
- EKS
- KMS
- ACM
- Cognito
- AWS Secrets Manager
- AWS Shield
- AWS WAF
- AWS GuardDuty
- Storage Gateway
- EC2 Pricing Models
### 🟡 MEDIUM Priority — Show up regularly, know the core concept + 1-liner
- AWS API (general API Gateway/SDK concepts)
- AWS Global Accelerator
- FSx
- AWS Backup
- AWS Snow Family
- AWS Transfer Family
- AWS DataSync
- DMS
- AWS Auto Scaling (account-wide, vs EC2 ASG)
- AWS Batch
- OpenSearch Service
- Amazon MQ
- AWS Step Functions
- AWS Compute Optimizer
- Kinesis
- MemoryDB
- Lake Formation
- DocumentDB
- Amazon Keyspaces
- Neptune
- AWS Directory Service
- AWS Firewall Manager
- AWS Inspector
- Amazon Macie
- AWS Security Hub
- CloudHSM
- AWS Migration Hub
- Amazon MSK
- Health Dashboards
---
 
## Study Priority Summary
1. **Domain 1 (Security, ~30%)** — IAM and VPC security first; this is the single biggest scoring opportunity.
2. **Domain 2 (Resilience, ~26%)** — Multi-AZ patterns, decoupling (SQS/SNS), backup/DR.
3. **Domain 3 (Performance, ~24%)** — Caching, storage/database selection, elastic compute.
4. **Domain 4 (Cost, ~20%)** — Storage classes and EC2 pricing models tie directly back to Domains 2 and 3 — study them together, not in isolation.
**Golden rule for judging any unfamiliar service:** if it touches **security, networking, compute, storage, databases, decoupling, HA/DR, or cost** → study it. If it's a **niche app/media/mobile/ML/blockchain tool** → know the name and one-liner, move on.