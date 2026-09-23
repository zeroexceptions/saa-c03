# SAA-C03 Storage Services Study Guide
### S3 | Glacier | EBS | EFS | Snow Family | AWS Backup | aws file cache

Storage is one of the **heaviest-weighted domains** on SAA-C03. Expect scenario questions that test which service fits a given cost/durability/access-pattern requirement — memorize the comparisons, not just definitions.

---

## 1. Amazon S3

### Core Facts
- Object storage, **regional service** (data stored across ≥3 AZs automatically)
- **Durability:** 99.999999999% (11 nines) — same across ALL storage classes
- **Availability:** varies by class (99.99% Standard → 99.9% for IA classes)
- Unlimited storage, max object size **5 TB** (single PUT limit 5GB, must use multipart upload above 100MB — recommended)
- **Strong read-after-write consistency** for all operations (since Dec 2020 — exam-relevant change)

### Storage Classes (KNOW THIS TABLE COLD)
| Class | Min Duration | Min Billable Size | Availability | Use Case |
|---|---|---|---|---|
| **S3 Standard** | None | None | 99.99% | Frequently accessed data |
| **S3 Intelligent-Tiering** | None | None | 99.9% | Unknown/changing access patterns (auto moves tiers, **no retrieval fee**) |
| **S3 Standard-IA** | 30 days | 128 KB | 99.9% | Infrequent access, needs rapid retrieval |
| **S3 One Zone-IA** | 30 days | 128 KB | 99.5% | Infrequent, **re-creatable data** (single AZ = cheaper, less durable to AZ loss) |
| **S3 Glacier Instant Retrieval** | 90 days | 128 KB | 99.9% | Archive, millisecond access, accessed ~1x/quarter |
| **S3 Glacier Flexible Retrieval** | 90 days | — | 99.99% | Archive, retrieval in minutes–hours |
| **S3 Glacier Deep Archive** | 180 days | — | 99.99% | Lowest cost, 12-hr retrieval, compliance/long-term |

### Exam Traps
- **Lifecycle policies** move objects between classes automatically (e.g., Standard → IA after 30 days → Glacier after 90 days)
- **S3 Transfer Acceleration** = uses CloudFront edge locations for faster uploads over long distances
- **S3 Versioning** must be enabled before Cross-Region Replication (CRR) works
- **MFA Delete** requires versioning enabled
- **Encryption options:** SSE-S3 (AWS-managed keys), SSE-KMS (auditable, more control), SSE-C (customer-provided keys), client-side encryption
- **S3 Access Points** simplify managing access for shared buckets with many users/apps
- **Presigned URLs** — grant temporary access to private objects
- **S3 Object Lock** — WORM (Write Once Read Many) model, used for compliance (Governance vs Compliance mode)
- **Static website hosting** — S3 can host static sites directly (not dynamic/server-side content)

---

## 2. Amazon S3 Glacier (now S3 Glacier storage classes)

### Core Facts
- Purpose-built for **archival**, extremely low cost
- Same 11 nines durability as S3
- Data stored in "vaults" (older/legacy Glacier) or as objects within S3 (modern Glacier storage classes)
- **Vault Lock policies** — like Object Lock, WORM compliance controls

### Retrieval Options (Flexible Retrieval) — MEMORIZE
| Retrieval Tier | Time | Use Case |
|---|---|---|
| **Expedited** | 1–5 minutes | Urgent access needed |
| **Standard** | 3–5 hours | Default option |
| **Bulk** | 5–12 hours | Large volumes, cheapest |

### Deep Archive Retrieval
| Tier | Time |
|---|---|
| Standard | 12 hours |
| Bulk | 48 hours |

### Exam Traps
- Deep Archive = **cheapest storage class in all of AWS**
- Glacier Instant Retrieval ≠ same as Glacier Flexible Retrieval (Instant has millisecond access, higher cost than Flexible)
- Early deletion before minimum storage duration = **prorated charge penalty**

---

## 3. Amazon EBS (Elastic Block Store)

### Core Facts
- **Block storage**, attached to a **single EC2 instance** (except Multi-Attach io1/io2)
- **AZ-locked** — an EBS volume can only attach to instances in the **same AZ**
- To move to another AZ: **snapshot → copy → restore in new AZ**
- Snapshots are **incremental** and stored in S3 (but not visible/managed via S3 console)

### Volume Types (KNOW FOR EXAM)
| Type | Category | IOPS | Use Case |
|---|---|---|---|
| **gp3** | SSD | Up to 16,000 | General purpose, baseline 3,000 IOPS independent of size (newer, cheaper than gp2) |
| **gp2** | SSD | Up to 16,000 | General purpose, IOPS scales with volume size |
| **io1/io2** | SSD | Up to 64,000 | Critical, high-performance databases; supports **Multi-Attach** |
| **io2 Block Express** | SSD | Up to 256,000 | Highest performance sub-millisecond latency |
| **st1** | HDD | — | Throughput-optimized, big data, log processing (cannot be boot volume) |
| **sc1** | HDD | — | Cold HDD, lowest cost, infrequent access (cannot be boot volume) |

### Exam Traps
- **gp3 vs gp2**: gp3 lets you provision IOPS/throughput independently of storage size — cost optimization answer
- Root/boot volumes **must be SSD** (gp2/gp3/io1/io2) — HDD types can't boot
- **EBS encryption**: uses KMS, encrypts data at rest, in transit between instance/volume, and snapshots
- **Snapshots** can be copied across regions (for DR scenarios)
- Deleting an instance: by default root EBS volume is deleted too, unless "Delete on Termination" is unchecked
- **io1/io2 Multi-Attach**: allows attaching one volume to multiple EC2 instances (same AZ) — used for clustered Linux apps needing shared storage

---

## 4. Amazon EFS (Elastic File System)

### Core Facts
- **File storage** using **NFSv4** protocol
- Can be mounted by **thousands of EC2 instances simultaneously**, **Multi-AZ** by design (unlike EBS)
- Works with Linux-based AMIs only (not Windows)
- Pay only for storage used (no pre-provisioning needed)
- Scales automatically (elastic)

### Performance Modes
| Mode | Use Case |
|---|---|
| **General Purpose** | Default, latency-sensitive apps (web serving, CMS) |
| **Max I/O** | Higher latency, but scales to more throughput/operations (big data, media processing) |

### Throughput Modes
| Mode | Description |
|---|---|
| **Bursting** | Throughput scales with storage size |
| **Provisioned** | Set throughput independent of storage amount |
| **Elastic** | Automatically scales throughput up/down based on workload (good for unpredictable spiky workloads) |

### Storage Classes (Lifecycle Management)
- **EFS Standard**
- **EFS Standard-IA** (infrequent access, cost savings)
- **EFS One Zone** / **One Zone-IA** (single AZ, ~47% cheaper, less resilient)

### Exam Traps
- **EFS vs EBS**: EBS = single instance/single AZ; EFS = multiple instances/multi-AZ — classic exam differentiator
- EFS is the answer whenever the question says **"shared file storage across multiple instances/AZs"**
- EFS **Infrequent Access** storage class + lifecycle policy = automatic cost optimization
- EFS is NOT for Windows workloads → use **FSx for Windows File Server** instead

---

## 5. AWS Snow Family

### Devices (KNOW CAPACITIES)
| Device | Capacity | Key Trait |
|---|---|---|
| **Snowcone** | 8 TB HDD / 14 TB SSD | Smallest, portable, can be sent back via internet (DataSync) OR shipped |
| **Snowball Edge (Storage Optimized)** | 80 TB | Data migration focus |
| **Snowball Edge (Compute Optimized)** | 42 TB (up to 210 TB w/ clustering) | Edge compute + storage, has EC2/Lambda capability |
| **Snowmobile** | Up to 100 PB | Truck-based, entire data center migrations |

### Exam Traps
- **When to use Snow Family:** the classic exam clue is **"limited/no network bandwidth"** + **"large data volume (TBs–PBs)"** + a **time comparison showing internet transfer would take X weeks/months**
- **Rule of thumb (exam logic):** if calculated transfer time over network > 1 week, physical transfer (Snowball) is usually the better answer
- **Snowball Edge** can run **compute** (Lambda functions, EC2 AMIs) — useful for edge locations with intermittent connectivity
- **OpsHub** = software used to manage Snow devices locally
- Data is automatically deleted from the device after AWS confirms successful import (NIST 800-88 wipe)

---

## 6. AWS Backup

### Core Facts
- **Centralized, managed backup service** across multiple AWS services from ONE console
- Supports: EBS, EFS, RDS, DynamoDB, Storage Gateway, EC2, FSx, Aurora, Redshift, S3 (as of newer updates)
- Removes need for custom scripts/Lambda functions to manage backups per-service

### Key Concepts
| Concept | Description |
|---|---|
| **Backup Plan** | Defines backup frequency, window, lifecycle (transition to cold storage, expiration) |
| **Backup Vault** | Logical container where backups (recovery points) are stored |
| **Resource Assignment** | Tag-based or resource-ID based selection of what gets backed up |
| **Cross-Region Backup** | Copy backups to another region for DR |
| **Cross-Account Backup** | Copy backups to another AWS account (ransomware/accidental deletion protection) |
| **Vault Lock** | WORM protection for backup vaults — prevents deletion even by root/admin |

### Exam Traps
- AWS Backup is the answer when the question emphasizes **"centralized"**, **"single pane of glass"**, or **"policy-based backup across multiple services"**
- Backup Vault Lock = compliance/ransomware protection scenario answer
- AWS Backup integrates with **Organizations** for account-wide backup policies

---

## Quick Cross-Service Comparison (High-Yield for Exam)

| Requirement in Question | Correct Service |
|---|---|
| Object storage, static website, data lake | **S3** |
| Cheapest possible long-term archival, retrieval time not critical | **S3 Glacier Deep Archive** |
| Block storage for a single EC2 instance / database | **EBS** |
| Shared file storage across many Linux instances, multi-AZ | **EFS** |
| Shared file storage for Windows instances | **FSx for Windows** |
| High-performance computing / ML file storage | **FSx for Lustre** |
| No/limited network bandwidth, large data migration | **Snowball / Snowmobile** |
| Edge location needing local compute + storage | **Snowball Edge (Compute Optimized)** |
| Centralized backup policy across many AWS services | **AWS Backup** |
| Need multi-instance attach for a single volume (same AZ) | **EBS io1/io2 Multi-Attach** |

---

## Final Exam Tips
1. **Cost vs. access speed trade-off** is the recurring theme — Glacier tiers, EFS-IA, S3 storage classes all test this.
2. Watch for **AZ vs Region vs multi-Region** scope in the question — it usually eliminates 1–2 wrong answers immediately (e.g., EBS = AZ-bound, EFS = Region-bound/Multi-AZ, S3 = Region-bound but 3+ AZ replicated).
3. If the scenario mentions **"cannot use the internet"** or **"bandwidth constrained"** → Snow Family.
4. If it mentions **"multiple EC2 instances need to read/write the same files"** → EFS (not EBS).
5. If it mentions **"single database volume needing high IOPS"** → EBS io1/io2.
6. If it mentions **"compliance," "WORM," "cannot be deleted even by admin"** → S3 Object Lock / Glacier Vault Lock / AWS Backup Vault Lock.
7. Always double-check **durability (11 nines, same everywhere)** vs **availability (varies by class)** — a very commonly confused exam point.