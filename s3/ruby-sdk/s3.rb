# frozen_string_literal: true

require "aws-sdk-s3"
require "tempfile"
require "pry"

# Credentials: NOT passed explicitly here.
# AWS_PROFILE is already exported into the shell by direnv (see .envrc),
# so the SDK's default credential provider chain finds it automatically:
#   env vars -> AWS_PROFILE's entry in ~/.aws/credentials / ~/.aws/config -> ...
region_name = ENV["AWS_REGION"] || "us-east-1"

client = Aws::S3::Client.new(
  region: region_name
  # credentials: omitted on purpose -> resolved via AWS_PROFILE
)

print "Enter bucket name: "
bucket_name = gets.strip

# S3 bucket names must be globally unique, lowercase, no underscores, 3-63 chars.
if bucket_name.empty?
  abort "Bucket name can't be empty."
end

begin
  puts "Creating bucket '#{bucket_name}' in #{region_name}..."

  # us-east-1 is the one region where you must NOT pass a
  # LocationConstraint, so handle it separately from every other region.
  if region_name == "us-east-1"
    my_bucket = client.create_bucket(bucket: bucket_name)
  else
    my_bucket = client.create_bucket(
      bucket: bucket_name,
      create_bucket_configuration: { location_constraint: region_name }
    )
  end

binding.pry

  puts "Bucket created."

  # Write a temp file with "hello world" content, then upload it.
  Tempfile.create(["hello", ".txt"]) do |file|
    file.write("hello world")
    file.rewind

    key = "hello.txt"
    puts "Uploading #{key}..."

    client.put_object(
      bucket: bucket_name,
      key: key,
      body: file
    )

    puts "Uploaded s3://#{bucket_name}/#{key}"
  end

rescue Aws::S3::Errors::BucketAlreadyExists
  puts "That bucket name is taken globally — try a different one."
rescue Aws::S3::Errors::BucketAlreadyOwnedByYou
  puts "You already own a bucket with that name — continuing with upload skipped."
rescue Aws::Errors::MissingCredentialsError
  puts "No AWS credentials found. Check that AWS_PROFILE is set and the profile exists in ~/.aws/credentials."
rescue Aws::S3::Errors::ServiceError => e
  puts "AWS S3 error: #{e.message}"
end
