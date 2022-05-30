resource "aws_s3_bucket" "logs_bucket" {
  bucket              = "${var.name}-logs"
  object_lock_enabled = true
  force_destroy       = true
  tags                = var.tags

}
resource "aws_s3_bucket_acl" "logs_bucket" {
  bucket = aws_s3_bucket.logs_bucket.id
  acl    = "log-delivery-write"

}
resource "aws_s3_bucket_object_lock_configuration" "logs_bucket" {
  bucket = aws_s3_bucket.logs_bucket.bucket

  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 5
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs_bucket" {
  bucket = aws_s3_bucket.logs_bucket.id

  rule {
    id = "rule-1"

    filter {
      prefix = "logs/"
    }
    noncurrent_version_expiration {
      noncurrent_days = 3
    }
    expiration {
      days = 7
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "logs_bucket" {
  bucket = aws_s3_bucket.logs_bucket.bucket

  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_public_access_block" "logs_bucket" {
  bucket                  = aws_s3_bucket.logs_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_kms_key" "logs_bucket" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 7
  tags                    = var.tags
}


resource "aws_s3_bucket_server_side_encryption_configuration" "logs_bucket" {
  bucket = aws_s3_bucket.logs_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.logs_bucket.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

output "logs_bucket" {
  description = "The name of the S3 logs_bucket bucket"
  value       = aws_s3_bucket.logs_bucket.id
}

