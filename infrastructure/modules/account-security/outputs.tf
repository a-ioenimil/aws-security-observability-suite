output "cloudtrail_arn" {
  description = "The ARN of the CloudTrail"
  value       = aws_cloudtrail.main_trail.arn
}

output "guardduty_detector_id" {
  description = "The ID of the GuardDuty detector"
  value       = aws_guardduty_detector.main_detector.id
}

output "cloudtrail_s3_bucket" {
  description = "The name of the S3 bucket storing CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail_bucket.id
}
