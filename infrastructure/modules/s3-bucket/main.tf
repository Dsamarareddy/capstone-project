terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_s3_bucket" "this" {
  # checkov:skip=CKV_AWS_144: cross-region replication needs a second region + replica bucket +
  # IAM role, which this generic dev-purpose bucket module doesn't assume exists. Layer
  # replication on top for buckets that specifically need DR.
  # checkov:skip=CKV2_AWS_62: event notifications are consumer-specific (this module has no
  # opinion on what, if anything, should react to object changes) - add an
  # aws_s3_bucket_notification resource in the calling environment if a specific consumer needs one.
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  rule {
    id     = "expire-noncurrent-versions"
    status = var.versioning_enabled ? "Enabled" : "Disabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# Access logging is opt-in: a generic reusable bucket module shouldn't force every caller to
# also stand up (and pay for) a dedicated log-target bucket. Pass access_log_bucket_id to
# enable it (see variables.tf) - covers CKV_AWS_18 for callers that need it.
resource "aws_s3_bucket_logging" "this" {
  count = var.access_log_bucket_id != null ? 1 : 0

  bucket        = aws_s3_bucket.this.id
  target_bucket = var.access_log_bucket_id
  target_prefix = "log/${var.bucket_name}/"
}
