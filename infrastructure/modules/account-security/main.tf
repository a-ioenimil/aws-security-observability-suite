data "aws_caller_identity" "current" {}

# 1. S3 Bucket for CloudTrail Logs
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket        = "${var.project_name}-${var.environment}-cloudtrail-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # Allow terraform destroy to delete the bucket even if it has logs (useful for Dev/Labs)

  tags = {
    Name        = "${var.project_name}-${var.environment}-cloudtrail-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail_versioning" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_encryption" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail_lifecycle" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  rule {
    id     = "archive-and-expire-logs"
    status = "Enabled"

    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = 90
    }
  }
}

# 2. S3 Bucket Policy for CloudTrail
resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_bucket.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# 3. AWS CloudTrail
resource "aws_cloudtrail" "main_trail" {
  name                          = "${var.project_name}-${var.environment}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-trail"
    Environment = var.environment
    Project     = var.project_name
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail_policy]
}

# 4. AWS GuardDuty
resource "aws_guardduty_detector" "main_detector" {
  enable = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-guardduty"
    Environment = var.environment
    Project     = var.project_name
  }
}
