# terraform-aws-s3-bucket

A simple Terraform module to create an AWS S3 bucket with optional versioning.

## Usage

```hcl
module "s3_bucket" {
  source = "git::https://github.com/<your-org>/terraform-aws-s3-bucket.git"

  bucket_name        = "my-example-bucket"
  versioning_enabled = true
  tags = {
    Environment = "dev"
    Owner       = "my-team"
  }
}
