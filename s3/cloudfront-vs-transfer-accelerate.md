# S3 Cheat Sheet: CRUD Operations, CloudFront vs Transfer Acceleration, Presigned URLs

## 1. Basic S3 Object CRUD Operations

| Operation | API Call | Purpose |
|---|---|---|
| Create/Update | `PutObject` | Upload a new object or overwrite an existing one (same call for both) |
| Read | `GetObject` | Download an object's content |
| Delete | `DeleteObject` / `DeleteObjects` | Remove one object, or batch-delete up to 1000 |
| List | `ListObjectsV2` | List objects in a bucket (S3 has no real folders, this is how you browse) |

### CLI Quick Reference
```bash
# Create/Update
aws s3api put-object --bucket my-bucket --key file.txt --body ./file.txt

# Read
aws s3api get-object --bucket my-bucket --key file.txt output.txt

# Delete
aws s3api delete-object --bucket my-bucket --key file.txt

# List
aws s3api list-objects-v2 --bucket my-bucket
```

---

## 2. CloudFront vs Transfer Acceleration — What Problem Each Solves

| | **Transfer Acceleration** | **CloudFront** |
|---|---|---|
| **Core purpose** | Speed up individual transfers (mainly uploads) over long distances | Cache and repeatedly serve content to many users |
| **Mechanism** | Routes traffic through CloudFront edge network → AWS backbone → straight to S3 (no caching) | Caches objects at edge locations; repeat requests never touch S3 |
| **Caching** | None — every request hits origin | Yes — this is the whole point |
| **Reduces S3 load?** | No | Yes, for cache hits |
| **Freshness** | Always fresh (hits origin) | Can be stale until TTL expires or cache is invalidated |
| **Extra features** | None — just a faster route | HTTPS/custom domains, signed URLs/cookies, WAF, geo-restriction, compression |
| **Cost pattern** | Per-GB surcharge on every request | Often cheaper at scale (fewer S3 GETs/data transfer) |
| **Setup** | Enable accelerate config on bucket; bucket name must be DNS-compliant (no dots) | Create a CloudFront distribution pointing at the bucket (as origin) |

---

## 3. CRUD Operations: CloudFront vs Transfer Acceleration

| Operation | CloudFront | Transfer Acceleration |
|---|---|---|
| **PutObject (Create/Update)** | ❌ Not designed for this. Blocked by default (only GET/HEAD allowed unless manually changed). No caching benefit — just an extra hop. | ✅ **Its main strength.** Purpose-built to speed up uploads over long distances. |
| **GetObject (Read)** | ✅ **Best for repeated access.** First request caches at edge; later requests for same object served from cache, bypassing S3 entirely. | ✅ Works, but no caching — every request round-trips to S3. Best for rare/one-off or private/sensitive/frequently-changing downloads. |
| **DeleteObject (Delete)** | ⚠️ Possible if DELETE method enabled, but pointless — tiny payload, nothing to cache, and creates cache-invalidation headaches. | ⚠️ Works but negligible benefit — request is too small to meaningfully accelerate. |
| **ListObjectsV2 (List)** | ⚠️ Poor fit — dynamic/small metadata response, hard to cache usefully since results change often. | ⚠️ Works, but negligible improvement — small response either way. |

### Practical Rule of Thumb
- **Uploads (Put)** → Transfer Acceleration
- **Repeated downloads by many users (Get)** → CloudFront
- **Rare/private downloads (Get)** → Transfer Acceleration (or just standard endpoint)
- **Delete / List** → Neither tool helps much; use the standard S3 endpoint
- **Real apps often use both**: Transfer Acceleration for ingest, CloudFront for distribution

---

## 4. Presigned URLs

### What it is
A URL with a temporary, embedded signature that lets someone perform **one specific S3 action** on **one specific object**, for a **limited time**, without needing their own AWS credentials.

### Actions you can presign
- `GetObject` (download) — most common
- `PutObject` (upload) — most common
- `DeleteObject`
- `HeadObject`
- Multipart upload operations (`CreateMultipartUpload`, `UploadPart`, etc.)

### Core Benefit
You never expose your AWS access keys/secret keys to end users, browsers, or mobile apps — you delegate a narrow, temporary permission instead.

| Action | Benefit |
|---|---|
| **Presigned GET** | Share private objects (invoices, private photos) temporarily without making the bucket/object public |
| **Presigned PUT** | Let clients upload directly to S3, bypassing your server — saves your server's bandwidth/compute, scales better for large files |
| **Presigned DELETE** | Grant a scoped, temporary delete permission without broader IAM access |

### Key properties (apply to all presigned actions)
1. **Security** — no long-lived credentials exposed to clients
2. **Time-limited** — expiration configurable (seconds to days)
3. **Scoped** — one object, one action only
4. **Offloads work from your server** — client talks directly to S3

### Example (Ruby SDK)
```ruby
s3 = Aws::S3::Presigner.new
url = s3.presigned_url(:put_object, bucket: 'my-bucket', key: 'file.txt', expires_in: 300)
# valid for 5 minutes; anyone with the link can PUT to that exact key
```

---

## 5. KMS Quick Notes (bonus, from earlier context)

| Key Type | Monthly Storage Cost | Notes |
|---|---|---|
| AWS-managed key (`aws/s3`, `aws/ebs`, etc.) | Free | Auto-created by AWS services; can't be created manually |
| Customer-managed key (CMK) | $1.00/month | Full control over policy, rotation, cross-account sharing |
| Multi-Region replica key | $1.00/month per replica | Billed as a separate key per region |

- Free tier: 20,000 API requests/month (symmetric ops only; asymmetric ops and `GenerateDataKeyPair` excluded)
- Enable **S3 Bucket Keys** (`BucketKeyEnabled: true`) with SSE-KMS to cut KMS API calls by up to 99% — free feature, pure savings