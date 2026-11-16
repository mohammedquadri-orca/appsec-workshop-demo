# Bootstrap: the S3 bucket that holds the main stack's Terraform state.
#
# Orca Cloud-to-Dev matches cloud resources back to Terraform code by reading
# state files in S3. The bucket is tagged orca-cloud-to-dev=true so Orca's
# "Scan private buckets for Cloud to Dev" option picks it up.
#
# This stack uses LOCAL state (infra/bootstrap/terraform.tfstate, gitignored).
# Destroy it LAST (make destroy-bootstrap).

terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      owner   = var.owner
      purpose = "orca-appsec-demo"
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "tfstate" {
  bucket = "orca-appsec-demo-tfstate-${data.aws_caller_identity.current.account_id}-${var.region}"

  # Lets `make destroy-bootstrap` remove the bucket even though it is versioned.
  force_destroy = true

  tags = {
    "orca-cloud-to-dev" = "true"
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

# SSE-S3 (not KMS) so Orca's scanning role can read the state without extra KMS grants.
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
