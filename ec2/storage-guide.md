# AWS Storage for EC2: EBS, EFS, S3, and FSx

Exam-focused notes for choosing storage in SAA-C03 scenario questions. The key is to identify the access pattern first: **block**, **shared files**, or **objects**.

## Amazon EBS volume types

Amazon Elastic Block Store (EBS) provides persistent **block storage** for EC2. A volume behaves like a disk that an operating system can format and mount. An EBS volume is tied to one Availability Zone and normally attaches to one EC2 instance at a time. EBS Multi-Attach is a special option for supported `io1`/`io2` volumes and instance types; it is not a general shared-file-system replacement.

| Type | Media / behavior | Typical SAA-C03 use case |
|---|---|---|
| `gp3` | General-purpose SSD; baseline performance with IOPS and throughput configurable independently of size | Default choice for boot volumes, development/test, virtual desktops, and most small or medium databases and applications. Usually prefer it over `gp2` for new general-purpose volumes. |
| `gp2` | General-purpose SSD; performance scales with volume size and can burst | Existing workloads and older configurations. Know it for exam comparisons; consider `gp3` for new deployments. |
| `io2` / `io2 Block Express` | Provisioned IOPS SSD; designed for high IOPS, low latency, and demanding sustained I/O | I/O-intensive and business-critical databases that need high, predictable performance and durability. |
| `io1` | Earlier-generation Provisioned IOPS SSD | Existing I/O-intensive database workloads; for current designs, `io2` is generally the newer choice. |
| `st1` | Throughput Optimized HDD; optimized for large, sequential reads/writes | Frequently accessed big data, data warehouses, and log processing. **Cannot be a boot volume.** |
| `sc1` | Cold HDD; lowest-cost HDD for infrequently accessed data | Infrequently accessed, throughput-oriented data when low storage cost matters most. **Cannot be a boot volume.** |
| `standard` | Previous-generation magnetic volume | Legacy workloads with small, infrequently accessed data and modest performance needs. Usually not the choice for a new design. |

**Quick selection:** general workload → `gp3`; demanding database IOPS → `io2`; large sequential analytics/log data → `st1`; cold, low-cost HDD data → `sc1`.

EBS snapshots are point-in-time backups stored using Amazon S3 behind the scenes. They are not ordinary S3 objects to manage directly. EBS volumes can be encrypted, resized, and changed between supported types. See [AWS EBS volume types](https://docs.aws.amazon.com/ebs/latest/userguide/ebs-volume-types.html).

## Does every EC2 instance need EBS?

An EC2 instance needs a **root device** to boot. Most current designs use an EBS-backed AMI, which creates an EBS root volume automatically. You can add other EBS volumes for application data, databases, or separate filesystems.

EBS is not the only possible root storage: a limited set of older Linux configurations can use an **instance store** root. Instance store is temporary storage physically attached to the host; its data can be lost when the instance stops, terminates, or the host fails. Windows instances require an EBS root volume. For SAA-C03 questions, assume EBS-backed root storage unless the question specifically points to temporary instance-store storage.

EFS does **not** replace the EC2 root disk. You cannot boot a standard EC2 instance from an EFS mount. You can mount EFS after boot for shared application files while the instance uses EBS (or supported instance store) for its operating system and local disk needs.

## Amazon EFS

Amazon Elastic File System (EFS) is a managed, elastic **NFS file system**. Linux EC2 instances can mount it over the network, and many instances can access the same directory tree concurrently, including instances in multiple Availability Zones. Capacity grows and shrinks as files are added or removed.

Choose EFS when the question calls for shared Linux files, such as shared web content, home directories, or application files accessed by a fleet of EC2 instances. EFS is not a disk attached to one instance: clients mount it through network interfaces and mount targets in their VPC.

### EFS deployment and storage choices

These are EFS choices—not separate services like S3 or FSx:

- **Regional file system:** stores data redundantly across multiple Availability Zones; use for high availability and multi-AZ access.
- **One Zone file system:** stores data in one Availability Zone; lower-cost option when the workload can accept the AZ-level availability and recovery trade-off.
- **Standard / One Zone storage classes:** for frequently accessed data.
- **Infrequent Access (IA) / One Zone-IA:** lower storage cost for files accessed less often; access charges apply.
- **Archive:** lower-cost tier for very rarely accessed files; access latency and minimum storage duration/cost rules apply.

Lifecycle management can move eligible files between storage classes. EFS IA and Archive are still part of the same file system; they are not different protocols or replacement products. Check current regional availability and pricing before deployment.

## How EBS, EFS, S3, and FSx differ

| Service | Storage model | How compute accesses it | Common SAA-C03 clue |
|---|---|---|---|
| **EBS** | Block storage (disk/volume) | Attached to EC2 in the same AZ, then formatted and mounted | Boot disk, single-instance database disk, low-latency block device, snapshots |
| **EFS** | Managed shared file storage (NFS) | Mounted over the network, primarily by Linux clients | Multiple Linux EC2 instances in multiple AZs need the same files and a shared POSIX-style filesystem |
| **S3** | Object storage (buckets and objects) | Accessed through API/SDK/CLI or HTTP; not a normal mounted block disk | Durable object data, backups, static assets, data lake, archival, or direct internet delivery |
| **FSx** | Managed file systems with specific protocols and engines | Mounted by compatible clients over the network | Need a particular enterprise filesystem, Windows SMB, high-performance Lustre, or NetApp/OpenZFS features |

Amazon FSx is a **family of managed file-system services**, not an EFS storage class:

- **FSx for Windows File Server:** Windows-native shared files over SMB, commonly integrated with Microsoft Active Directory.
- **FSx for Lustre:** high-performance, parallel file system for HPC, machine learning, and data processing; can integrate with S3 data repositories.
- **FSx for NetApp ONTAP:** managed ONTAP features, including NFS/SMB/iSCSI and data-management capabilities.
- **FSx for OpenZFS:** managed OpenZFS file storage for workloads needing ZFS features and low-latency shared access.

**Memory aid:** EBS = a disk for an instance; EFS/FSx = shared files over a network; S3 = objects in a bucket. EFS and FSx are both file storage, but FSx is chosen when a specific filesystem/protocol or feature set is required.

## EC2 launch wizard: “File systems” choices

The EC2 launch wizard's **File systems** selector configures an additional network file-system mount for the instance. It is separate from the **Volumes** section, where you configure the root EBS disk and any additional EBS block volumes. Selecting `None` here does not remove the root volume required to boot.

| Launch choice | What it mounts | When to choose it |
|---|---|---|
| **S3 Files** | An S3 file system backed by data in an S3 bucket, mounted at a path on the instance | Choose when an application needs file-system-style access to S3 data. This does not turn S3 into an EBS boot disk. The instance needs the required IAM permissions and network/security-group access. |
| **EFS** | An Amazon EFS NFS file system | Choose for shared Linux files that multiple EC2 instances need to access. |
| **FSx** | A compatible Amazon FSx file system | Choose when the workload needs a specific managed filesystem, such as Windows SMB or Lustre. |
| **None** | No extra file-system mount configured by this selector | Choose when the instance does not need one of these network file systems. The normal root volume is still configured separately. |

**Exam distinction:** The menu is a console convenience for attaching/mounting shared or object-backed files at launch. It does not replace the storage decision for the operating system disk: for a typical EC2 instance, that root disk is EBS. The AWS exam may describe the underlying use case rather than this exact console menu label. For S3 Files, remember that S3 remains object storage behind a file-system interface; choose regular S3 API access when the application is designed to use objects directly.

## Exam decision examples

- One EC2 database needs a persistent boot/data disk → **EBS**.
- Many Linux EC2 instances across AZs need to read and write the same files → **EFS Regional**.
- Windows servers need a shared SMB drive → **FSx for Windows File Server**.
- HPC workload needs a high-throughput parallel filesystem → **FSx for Lustre**.
- Application needs highly durable object storage or static website assets → **S3**.
- Temporary cache/scratch data that can be rebuilt and needs very fast local storage → **instance store**, when the instance type supports it.

## Official references

- [Amazon EBS volume types](https://docs.aws.amazon.com/ebs/latest/userguide/ebs-volume-types.html)
- [EC2 storage options](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Storage.html)
- [EC2 root volumes](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/RootDeviceStorage.html)
- [Amazon EFS features](https://docs.aws.amazon.com/efs/latest/ug/features.html)
- [Use Amazon S3 with EC2 instances (S3 Files)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AmazonS3.html)
- [Mounting S3 file systems on EC2](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-files-mounting.html)
- [Use Amazon FSx with EC2 instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/storage_fsx.html)
- [Choosing an AWS storage service](https://docs.aws.amazon.com/decision-guides/latest/decision-guides/choosing-aws-storage-service.html)
