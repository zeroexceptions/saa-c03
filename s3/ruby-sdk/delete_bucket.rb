# frozen_string_literal: true

require "aws-sdk-s3"

# Credentials: resolved via AWS_PROFILE (same as s3.rb) — nothing passed explicitly.
region_name = ENV["AWS_REGION"] || "us-east-1"

client = Aws::S3::Client.new(region: region_name)

print "Enter bucket name to delete: "
bucket_name = gets.strip

abort "Bucket name can't be empty." if bucket_name.empty?

print "This will permanently delete ALL objects in '#{bucket_name}' and the bucket itself. Type the bucket name again to confirm: "
confirmation = gets.strip

abort "Confirmation didn't match. Aborting." unless confirmation == bucket_name

begin
  # list_object_versions covers both plain objects and, if versioning is/was
  # ever enabled, every version + delete marker. Paginate since a bucket can
  # hold more than one page (and delete_objects caps at 1000 keys per call).
  puts "Emptying bucket '#{bucket_name}'..."
  deleted_count = 0

  client.list_object_versions(bucket: bucket_name).each_page do |page|
    objects_to_delete = page.versions.map { |v| { key: v.key, version_id: v.version_id } } +
                         page.delete_markers.map { |d| { key: d.key, version_id: d.version_id } }

    next if objects_to_delete.empty?

    client.delete_objects(
      bucket: bucket_name,
      delete: { objects: objects_to_delete, quiet: true }
    )

    deleted_count += objects_to_delete.size
  end

  puts "Deleted #{deleted_count} object version(s)."

  puts "Deleting bucket '#{bucket_name}'..."
  client.delete_bucket(bucket: bucket_name)
  puts "Bucket '#{bucket_name}' deleted."

rescue Aws::S3::Errors::NoSuchBucket
  puts "Bucket '#{bucket_name}' doesn't exist."
rescue Aws::Errors::MissingCredentialsError
  puts "No AWS credentials found. Check that AWS_PROFILE is set and the profile exists in ~/.aws/credentials."
rescue Aws::S3::Errors::ServiceError => e
  puts "AWS S3 error: #{e.message}"
end
