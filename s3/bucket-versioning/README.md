# Bucket versioning + ETag demo

Two buckets, same object key (`hello.txt`), same content on every apply.
The only difference: `dev03-aws-crs-versioning-demo-on` has versioning
enabled, `dev03-aws-crs-versioning-demo-off` never had it touched. Applying
twice with different content is what makes the difference visible.

## Run it

```bash
terraform init
terraform apply
```

Note the four outputs Terraform prints - especially the two `*_etag` and
`*_version_id` values.

Now bump the content and apply again, to simulate an overwrite:

```bash
terraform apply -var 'object_content=version 2 - hello.txt'
```

## What to inspect

```bash
# versioned bucket: every version is listed, each with its own VersionId + ETag
aws s3api list-object-versions --bucket dev03-aws-crs-versioning-demo-on --prefix hello.txt

# unversioned bucket: only ONE entry ever exists for this key
aws s3api list-object-versions --bucket dev03-aws-crs-versioning-demo-off --prefix hello.txt

# current object metadata on either bucket
aws s3api head-object --bucket dev03-aws-crs-versioning-demo-on --key hello.txt
aws s3api head-object --bucket dev03-aws-crs-versioning-demo-off --key hello.txt
```

## ETag - what it actually is

- ETag is a hash of the object's *content*, not a versioning concept. For a
  plain single-part upload (which is what `terraform apply` does here),
  it's the MD5 hash of the bytes, wrapped in quotes, e.g. `"5eb63bbbe01eeed093cb22bb8f5acdc3"`.
- For multipart uploads it is NOT a plain MD5 of the whole file - it's a
  hash of the concatenated part hashes plus `-<number of parts>`
  (e.g. `"abc123...-4"`). You cannot use it to verify content integrity for
  multipart uploads the same way you can for single-part ones.
- Since it's a content hash, ETag changes any time the bytes change -
  that happens identically whether or not versioning is on. Versioning
  does not change how ETag is computed.

## What versioning actually changes

Versioning doesn't touch ETag computation. What it changes is what happens
to the *previous* (content, ETag) pair when you overwrite the same key.

**Versioning enabled (bucket A):**
- Every `PutObject` to `hello.txt` creates a brand new, independent
  **version** with its own unique `VersionId` and its own `ETag` matching
  that version's content.
- The old version isn't touched or replaced - it's still sitting in the
  bucket with its own VersionId + ETag, retrievable forever via
  `GetObject --version-id <old-id>` (until a lifecycle rule or an explicit
  versioned delete removes it).
- A plain `GetObject` (no version id) always returns the *current* (most
  recent) version's content and ETag.
- `list-object-versions` on this bucket will show 2 entries for `hello.txt`
  after the second apply - one marked `IsLatest: true` (v2's ETag), one
  `IsLatest: false` (v1's ETag, still fully intact).

**Versioning never enabled (bucket B):**
- There's only ever one row for the key. `VersionId` reported by the API is
  literally the string `"null"` - AWS's way of saying "this bucket doesn't
  do versions."
- The second `PutObject` **overwrites the object in place**. The old
  content is gone - not recoverable, no history, nothing to roll back to.
- The ETag still changes (it always reflects current bytes), but there is
  no way to go back and ask "what was the ETag before this PUT" - that
  data no longer exists anywhere.

## The one-line summary

ETag = "what are the current bytes, as a hash." Versioning = "do old
(bytes, ETag) pairs get kept around after an overwrite, or thrown away."
They're orthogonal, but versioning is what determines whether an ETag you
observed yesterday is still attached to *any* retrievable object today.

## Cleanup

```bash
terraform destroy
```

Because bucket A has versioning enabled, Terraform will fail to delete it
if it still contains multiple versions of `hello.txt` - `aws_s3_bucket`
does not empty version history for you. If `destroy` complains about the
versioned bucket not being empty, delete every version manually first:

```bash
aws s3api delete-objects --bucket dev03-aws-crs-versioning-demo-on \
  --delete "$(aws s3api list-object-versions --bucket dev03-aws-crs-versioning-demo-on \
  --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json)"
```

then re-run `terraform destroy`.
