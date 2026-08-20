resource "aws_s3_bucket" "example" {
  bucket = "dev03-aws-crs-tf-practice-bucket"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}