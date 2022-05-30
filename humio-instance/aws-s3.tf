resource "aws_s3_bucket" "humio" {
  bucket        = var.cluster_id
  force_destroy = true
  tags          = var.tags

}
resource "aws_s3_bucket_acl" "humio" {
  bucket = aws_s3_bucket.humio.id
  acl    = "private"

}

resource "aws_s3_bucket_public_access_block" "humio" {
  bucket                  = aws_s3_bucket.humio.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_kms_key" "humio" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
  tags                    = var.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "humio" {
  bucket = aws_s3_bucket.humio.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.humio.arn
      sse_algorithm     = "aws:kms"
    }
  }
}
resource "aws_s3_bucket_versioning" "humio" {
  bucket = aws_s3_bucket.humio.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "humio" {
  bucket = aws_s3_bucket.humio.id

  target_bucket = var.humio_logs_bucket_id
  target_prefix = "log/"
}

output "s3_humio_bucket_name" {
  description = "The name of the S3 humio bucket"
  value       = aws_s3_bucket.humio.id
}
