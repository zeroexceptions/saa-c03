# Two buckets side by side, same object key, same content on every apply -
# the only difference between them is whether versioning is turned on.
# That lets you diff their behavior directly with the AWS CLI instead of
# taking it on faith.

# ---- Bucket A: versioning ENABLED ------------------------------------
resource "aws_s3_bucket" "versioned" {
  bucket = "dev03-aws-crs-versioning-demo-on"

  tags = {
    Name = "versioning-demo-enabled"
  }
}

resource "aws_s3_bucket_versioning" "versioned" {
  bucket = aws_s3_bucket.versioned.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "versioned_object" {
  # depends_on makes sure versioning is switched on BEFORE the first upload,
  # so even the very first version is tracked as an explicit version rather
  # than landing as version "null".
  depends_on = [aws_s3_bucket_versioning.versioned]

  bucket  = aws_s3_bucket.versioned.id
  key     = "hello.txt"
  content = var.object_content
}

# ---- Bucket B: versioning NEVER enabled (default state) ---------------
resource "aws_s3_bucket" "unversioned" {
  bucket = "dev03-aws-crs-versioning-demo-off"

  tags = {
    Name = "versioning-demo-disabled"
  }
}

# Note: no aws_s3_bucket_versioning resource here at all. A bucket that has
# never had versioning touched stays in the "Unversioned" state - there is
# nothing to configure for the "off" case, that IS the off case.

resource "aws_s3_object" "unversioned_object" {
  bucket  = aws_s3_bucket.unversioned.id
  key     = "hello.txt"
  content = var.object_content
}
