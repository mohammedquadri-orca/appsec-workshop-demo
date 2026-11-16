# Reusable demo bucket module.
#
# ORCA-DEMO: IaC – buckets from this module have NO versioning and NO access logging.
# Public access is fully blocked, so there is no public exposure.

resource "aws_s3_bucket" "this" {
  bucket_prefix = var.bucket_prefix
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = var.encryption_enabled ? 1 : 0
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Placeholder object – no real data.
resource "aws_s3_object" "readme" {
  bucket       = aws_s3_bucket.this.id
  key          = "README.txt"
  content      = "orca-appsec-demo placeholder object. Contains no real data.\n"
  content_type = "text/plain"
}
