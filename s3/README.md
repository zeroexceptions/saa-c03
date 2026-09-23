=========================
Bucket policies
ACLs
AWS private link for amazon s3
CORS for static website hosting
Block public access
IAM analyzer for s3
Internetwork traffic privacy
object ownership
access points
access grants
versioning
mfa delete
object tags
In-transit encryption
server side encryptionc
client side encryption
compliance validation for amazon s3
infrastructure security
bucket policy vs IAM policy
s3 access grants
iam access analyzer
Internetwork traffic privacy


============================

s3 object lock

aws s3,
aws s3api
aws s3control
aws s3outposts

=========================








========================================
AWS S3 - BUCKET vs OBJECT
========================================

S3 BUCKET
---------
- A bucket is a container/folder-like resource that holds objects (files).
- Think of it like a top-level directory in a global filesystem.
- Buckets have properties: region, versioning, encryption, policies, logging, lifecycle rules, etc.
- You must create a bucket before you can upload any object into it.
- Default limit: 100 buckets per account (can request increase up to 1000).
- Naming rules:
    - 3-63 characters long
    - lowercase letters, numbers, hyphens only (no uppercase, no underscores)
    - must start/end with a letter or number
    - cannot look like an IP address (e.g. 192.168.1.1)

S3 OBJECT
---------
- An object is the actual file/data stored inside a bucket (e.g. image, video, document).
- Each object = data + metadata + a unique key (its "path/filename" within the bucket).
- Object size range: 0 bytes up to 5TB.
- Objects larger than 5GB must be uploaded using Multipart Upload.
- Every object has a version ID if versioning is enabled on the bucket.
- Objects are identified by: Bucket name + Key (full path) + Version ID (optional).

Key difference:
  Bucket = the container (like a top-level folder)
  Object = the actual file stored inside that container

========================================
WHY BUCKET NAMES MUST BE "UNIVERSALLY UNIQUE"
========================================
- S3 bucket names are unique across ALL AWS accounts globally, not just within your account.
- This is because S3 uses a global namespace: every bucket gets a DNS-compatible endpoint like:
      https://<bucket-name>.s3.amazonaws.com
  Since this maps to a real DNS hostname on the internet, no two buckets anywhere
  in the world (across any account, any region) can share the same name.
- Practical impact:
    - If someone else has already taken a bucket name (e.g. "mydata"), you CANNOT use
      it, even in a different region or different AWS account.
    - Common practice for exam/real-world: add unique suffixes, e.g. "mycompany-app-logs-8213".
- Note: this uniqueness rule applies to the bucket NAME itself, not to objects inside it.
  Object keys only need to be unique WITHIN a bucket.

========================================
QUICK EXAM TIPS
========================================
- S3 is a flat structure internally — "folders" you see in console are just prefixes in the key name.
- S3 is object storage, NOT a file system or block storage (that's EBS/EFS).
- Data consistency: S3 provides strong read-after-write consistency for all operations (PUTS, GETS, DELETES).


Yes, Amazon S3 (Simple Storage Service) is considered a serverless service.
It is a fully managed object storage offering where you do not provision,
configure, or manage any underlying servers or hard drives

========================================
AWS CLI: "s3" vs "s3api"
========================================
- aws s3: high-level convenience commands (cp, sync, mv, rm, ls) for everyday file/object transfers, with automatic multipart handling and recursive/glob support.
- aws s3api: low-level commands that map 1:1 to the raw S3 REST API (put-object, list-objects-v2, create-bucket, put-bucket-policy, etc.), giving full control over request parameters (metadata, ACLs, encryption, versioning) but no built-in conveniences like sync.

TL;DR: s3 = convenience wrapper for moving files; s3api = raw API access for fine-grained control/config.




S3 CHEAT SHEET
==============

General: S3 is a globally available service (you access it via a global
namespace), but every bucket physically lives in one region you choose at
creation time. Data never leaves that region unless you set up replication.


1. S3 BUCKET NAMING RULES
--------------------------
- Bucket names are globally unique across ALL AWS accounts in the same
  partition (aws / aws-cn / aws-us-gov are separate namespaces) - not just
  unique within your account.
- 3-63 characters long.
- Lowercase letters, numbers, hyphens (-) and periods (.) only. No uppercase,
  no underscores, no spaces.
- Must start and end with a letter or number (not a hyphen or period).
- No two adjacent periods (e.g. "my..bucket" invalid).
- Cannot be formatted like an IP address (e.g. 192.168.5.4).
- Cannot start with reserved prefixes: "xn--", "sthree-", "amzn-s3-demo-".
- Cannot end with reserved suffixes: "-s3alias" (reserved for access point
  aliases), "--ol-s3" (reserved for Object Lambda access points).
- Once created, a bucket name is permanent - you cannot rename a bucket,
  only delete it and create a new one (and the name isn't instantly
  reusable elsewhere after deletion).
- Avoid periods in the name if you plan to use virtual-hosted-style HTTPS
  access with the default S3 wildcard cert, or plan to put CloudFront in
  front of it - SSL wildcard cert matching breaks on dots in the hostname.
- Also for S3 transfer accelerate, buckets can't have dot in their name. 


2. S3 BUCKET RESTRICTIONS AND LIMITATIONS
------------------------------------------
- Default quota: 100 buckets per account; can request a Service Quota
  increase up to 1,000.
- No limit on number of objects in a bucket or total storage - effectively
  unlimited.
- Max single object size: 5 TB.
- Max size for a single PUT (one API call): 5 GB. Anything larger MUST use
  multipart upload (AWS recommends multipart for anything over ~100 MB for
  reliability/parallelism, and it becomes mandatory above 5 GB).
- Multipart upload: min part size 5 MB (except the last part), max 10,000
  parts.
- No true nested buckets - "sub-buckets" don't exist, only key prefixes.
- Bucket policies are capped at 20 KB.
- Up to 10 tags per object.
- Request rate: S3 scales automatically per prefix - no need to
  "randomize" key prefixes for performance anymore (old pre-2018 advice).
  Baseline supported per prefix: 3,500 PUT/COPY/POST/DELETE and 5,500
  GET/HEAD requests per second.


3. S3 BUCKET TYPES
--------------------
- General purpose bucket (default, what you get normally):
  - Region-scoped, flat key-value namespace, unlimited storage.
  - Backs all the standard storage classes (Standard, Intelligent-Tiering,
    Standard-IA, One Zone-IA, Glacier Instant Retrieval, Glacier Flexible
    Retrieval, Glacier Deep Archive).
- Directory bucket (S3 Express One Zone):
  - Purpose-built for low-latency, high-throughput workloads.
  - Lives in a SINGLE Availability Zone (you pick the AZ) - trades
    multi-AZ durability for speed (single-digit millisecond latency).
  - Has a real hierarchical namespace (actual directories), not simulated
    prefixes like general purpose buckets.
  - Naming convention is different: bucket-base-name--azid--x-s3.
  - Only usable with the S3 Express One Zone storage class.
- Table bucket (S3 Tables, newer addition):
  - Purpose-built to store tabular data as Apache Iceberg tables.
  - Aimed at analytics workloads (query engines like Athena, EMR, etc.).


4. S3 BUCKET FOLDERS
-----------------------
- S3 is flat object storage - there is no real directory tree in a general
  purpose bucket. A "folder" is just a naming convention: the object's Key
  contains "/" characters, e.g. photos/2024/trip/pic.jpg is ONE object
  whose whole key is that string.
- The console fakes folder creation by uploading a zero-byte object whose
  key ends in "/" (e.g. photos/2024/) - this is just a UI convenience
  marker, not something S3 requires.
- Listing APIs (ListObjectsV2) emulate directory browsing using the
  "prefix" and "delimiter" parameters - matches under a prefix up to the
  next delimiter get rolled up into "CommonPrefixes" (i.e. the folders you
  see in the console).
- Deleting a "folder" in the console really means deleting every object
  that shares that key prefix.
- Exception: Directory buckets (S3 Express One Zone) DO have a genuine
  hierarchical namespace, unlike general purpose buckets.


5. BUCKET VERSIONING
------------------------
- Off by default. Three states, and it's a one-way door in one direction:
  Unversioned -> Enabled -> Suspended (you can go back and forth between
  Enabled and Suspended, but never back to Unversioned once turned on).
- When enabled: every PUT to the same key creates a new object version
  with a unique Version ID. Old versions are kept, not overwritten.
- DELETE without a version ID doesn't actually erase data - it inserts a
  "delete marker" (a new version) so the object just appears gone in
  normal listings.
- DELETE with an explicit version ID permanently removes that specific
  version.
- Suspending versioning: new objects get a version ID of "null"; existing
  versions already stored are untouched and remain retrievable.
- MFA Delete: optional extra protection requiring the root account's MFA
  code to permanently delete a version or to disable/suspend versioning
  itself. Can only be enabled/disabled via the CLI by the root user.
- Cost implication: every version stored counts toward billable storage -
  pair versioning with lifecycle rules to expire/transition noncurrent
  versions (e.g. to Glacier, or expire after N days).
- Cross-Region Replication (CRR) and Same-Region Replication (SRR) both
  REQUIRE versioning enabled on the source bucket (and destination).
- CDK: `versioned: true` on the s3.Bucket construct (as seen in
  ../infrastructure-as-code(IAC)/cdk-app/lib/cdk-app-stack.js before it
  was removed for this practice bucket).


6. BUCKET ENCRYPTION
------------------------
Server-side encryption (SSE) options - AWS encrypts/decrypts for you:
- SSE-S3: Amazon S3-managed keys, AES-256. AWS handles everything. This is
  now the ACCOUNT-WIDE DEFAULT for every new object since Jan 2023, even
  if you specify nothing.
- SSE-KMS: uses an AWS KMS key (either the AWS-managed "aws/s3" key or your
  own customer-managed key). Gives you a CloudTrail audit trail of every
  key usage and key policy-based access control. Downside: KMS has its own
  API request quota, so very high request-rate workloads can get
  throttled - mitigate with "S3 Bucket Keys" to cut down on KMS API calls.
- DSSE-KMS: dual-layer SSE with KMS - encrypts data twice, for extra strict
  compliance needs (e.g. FIPS-type requirements).
- SSE-C: customer-provided key - YOU supply the encryption key on every
  request (over HTTPS only); S3 uses it once and discards it, never
  storing it. You must resupply the exact same key on every GET too.
- Client-side encryption: you encrypt the data yourself before it ever
  reaches S3. S3 just stores opaque bytes; full control, but you own key
  management and never get server-side decryption help.
- Encryption in transit vs at rest are separate concerns: at-rest is the
  above; in-transit is just TLS/HTTPS. You can force HTTPS-only access
  with a bucket policy condition on `aws:SecureTransport`.
- You can also force a specific SSE mode with a bucket policy that denies
  PutObject requests missing the right `x-amz-server-side-encryption`
  header.
- Encryption is decided per object - different objects in the same bucket
  can use different SSE modes.


7. STATIC WEBSITE HOSTING
----------------------------
- Enabled via a bucket property: turn on "Static website hosting" and set
  an index document (e.g. index.html) and optionally an error document
  (e.g. error.html).
- The static website endpoint has NO concept of IAM auth - visitors are
  anonymous, so the bucket needs "Block Public Access" turned off (at
  least partially) plus a bucket policy granting `s3:GetObject` to
  everyone (Principal: "*") for the site to actually be reachable.
- Two different endpoint styles for the same bucket:
  - REST/API endpoint: bucket-name.s3.amazonaws.com (returns raw XML API
    responses, not a rendered site).
  - Website endpoint: bucket-name.s3-website-<region>.amazonaws.com (exact
    hostname format varies slightly by region/partition) - THIS is the one
    that serves index/error documents like a real website.
- The S3 website endpoint only serves HTTP, never HTTPS, and only your
  bucket's default region domain - put CloudFront in front if you need
  HTTPS and/or a custom domain with a certificate.
- Static hosting means static content only - HTML/CSS/JS/images. No
  server-side code execution (no PHP/Node/etc running on S3). Dynamic
  behavior has to come from client-side JS calling out to something else
  (API Gateway + Lambda, etc.).
- Supports redirect rules - e.g. redirect the whole bucket to another
  domain, or per-request routing rules (handy for apex-domain -> "www"
  redirects).
- Custom domain: point a Route 53 alias record at the S3 website endpoint.
  Important gotcha - the BUCKET NAME must exactly match the domain name
  you're serving (e.g. bucket "example.com" for domain example.com).
- If your site's JS/assets are fetched cross-origin, you'll also need a
  CORS configuration on the bucket.
- On an error, S3 returns your custom error document as the response body,
  but still keeps the real HTTP status code that occurred (403, 404, etc.)
  - it doesn't silently turn errors into 200s.


8. S3 STORAGE CLASSES
------------------------
ALL classes are rated 99.999999999% (11 nines) durability, including One
Zone-IA and Express One Zone - durability is about not losing the bits
(redundancy within whatever AZ footprint the class uses), which is
different from AVAILABILITY (whether the object is reachable right now,
e.g. during an AZ outage). Single-AZ classes (One Zone-IA, Express One
Zone) still carry the 11-nines rating for the AZ they live in, but if that
one AZ is destroyed the data really can be lost - that risk shows up in
their lower AVAILABILITY %, not in a lower durability number.

Comparison table (from course slide):

                    Express-1Z Standard  Int-Tier  Std-IA   1Zone-IA Glacier-Instant Glacier-Flex  Glacier-Deep
Durability          11 9's     11 9's    11 9's    11 9's   11 9's   11 9's          11 9's        11 9's
Availability        99.95%     99.99%    99.9%     99.9%    99.5%    99.9%           N/A           N/A
Availability SLA    99.9%      99.99%    99%       99%      99%      99%             N/A           N/A
AZs                 1          >=3       >=3       >=3      1        >=3             >=3           >=3
Min charge/object   N/A        N/A       N/A       128 KB   128 KB   (n/a listed)    40 KB         40 KB
Min storage duration N/A       N/A       30 days   30 days  30 days  90 days         90 days       180 days
Retrieval fee       N/A        N/A       N/A       per GB   per GB   per GB          per GB        per GB
First-byte latency  single-digit ms  ms  ms        ms       ms       ms              mins-hrs      hours

Note: Glacier Flexible/Deep Archive don't publish an availability SLA
because they're retrieval-based, not always-on - "availability" isn't
really a meaningful number until you've paid the restore time.

- S3 Standard:
  - Default class. Milliseconds first-byte latency, resilient across >=3 AZs.
  - 99.99% availability SLA. Highest storage cost of the "always-ready"
    tiers, no retrieval fee, no minimum storage duration.
  - Use for: frequently accessed / active data (websites, apps, analytics
    feeding live workloads).

- S3 Intelligent-Tiering:
  - No retrieval fees, no performance impact - it auto-moves objects
    between access tiers based on observed access patterns, for a small
    monthly per-object monitoring/automation fee.
  - Tiers (low to high latency): Frequent Access -> Infrequent Access (after
    30 days no access) -> Archive Instant Access (after 90 days) ->
    optional Archive Access (after 90-700+ days, opt-in) -> optional Deep
    Archive Access (after 180-700+ days, opt-in). The two archive tiers
    behave like Glacier Flexible/Deep Archive (need a restore request).
  - Use for: unknown or changing access patterns where you don't want to
    manage lifecycle rules by hand.

- S3 Standard-IA (Infrequent Access):
  - Millisecond access like Standard, but lower storage price / higher
    per-GB retrieval price. 99.9% availability.
  - Minimum storage duration: 30 days. Minimum billable object size: 128 KB
    (smaller objects still billed as if 128 KB).
  - Use for: backups, older data still occasionally needed, e.g. DR
    secondary copies.

- S3 One Zone-IA:
  - Same as Standard-IA but stored in a SINGLE AZ instead of >=3.
  - Cheaper than Standard-IA (~20% less), still rated 11 nines durability
    within that AZ, but only 99.5% availability - lose the AZ and you lose
    the data, which is why it's positioned below Standard-IA.
  - Same 30-day minimum duration / 128 KB minimum billable size as
    Standard-IA.
  - Use for: easily recreatable data, or secondary copies you already
    replicate elsewhere (e.g. on-prem backup copy).

- S3 Glacier Instant Retrieval:
  - Archive tier but with millisecond retrieval (same latency as Standard),
    for data accessed roughly once a quarter.
  - Minimum storage duration: 90 days. 99.9% availability.
  - Cheapest storage cost that still gives instant access.

- S3 Glacier Flexible Retrieval (formerly just "S3 Glacier"):
  - Data NOT instantly available - you submit a restore request first, then
    the object copy becomes available for a set time.
  - Retrieval speed options: Expedited (1-5 min), Standard (3-5 hrs), Bulk
    (5-12 hrs, cheapest/free-tier-eligible for bulk restores).
  - Minimum storage duration: 90 days. Minimum billable object size: 40 KB.
  - Use for: backups/archives accessed a few times a year, DR data.

- S3 Glacier Deep Archive:
  - Cheapest storage class overall. Restore options: Standard (12 hrs) or
    Bulk (48 hrs).
  - Minimum storage duration: 180 days. Minimum billable object size: 40 KB.
  - Use for: long-term retention / compliance archives (7-10 year
    regulatory retention, rarely-if-ever accessed).

- S3 Express One Zone:
  - The fastest class - single-digit millisecond latency, up to 10x faster
    than S3 Standard, purpose-built for latency-sensitive/high-request-rate
    workloads (e.g. ML training data, ad tech bidding).
  - ONLY usable with directory buckets (see section 3), single AZ.
  - Priced higher per-GB than Standard but can cut request costs since data
    is colocated with compute; no minimum storage duration.

- (Legacy) Reduced Redundancy Storage (RRS): deprecated, AWS no longer
  recommends it - Standard is now equally cheap/cheaper with better
  durability, so there's no reason to use RRS today.

Lifecycle rules tie all of this together: you set transition actions (e.g.
Standard -> Standard-IA after 30 days -> Glacier Deep Archive after 180
days) and expiration actions, instead of moving objects manually. Note the
minimum-duration classes (IA/Glacier tiers) charge an early-deletion
penalty if you delete/transition out before their minimum, so lifecycle
rules that transition too aggressively can cost more than they save.




https://zeroexceptions.s3.us-east-1.amazonaws.com/docs/all/myfiles/s3.txt

https://zeroexceptions.s3.us-east-1.amazonaws.com/ (s3 endpoint)


docs/all/myfiles/s3.txt (object key)
docs/all/myfiles/ (object prefix)
s3.txt (object name)

