output "versioned_bucket_name" {
  value = aws_s3_bucket.versioned.id
}

output "versioned_object_etag" {
  value = aws_s3_object.versioned_object.etag
}

output "versioned_object_version_id" {
  value = aws_s3_object.versioned_object.version_id
}

output "unversioned_bucket_name" {
  value = aws_s3_bucket.unversioned.id
}

output "unversioned_object_etag" {
  value = aws_s3_object.unversioned_object.etag
}

output "unversioned_object_version_id" {
  value = aws_s3_object.unversioned_object.version_id
}
