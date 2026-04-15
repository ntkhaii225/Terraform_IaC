# =============================================================================
# Frontend S3 + CloudFront Module - Outputs
# =============================================================================

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID (dùng cho cache invalidation khi deploy)"
  value       = aws_cloudfront_distribution.frontend.id
}

output "cloudfront_domain_name" {
  description = "CloudFront Domain Name"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "s3_bucket_name" {
  description = "S3 Bucket Name (dùng cho aws s3 sync khi deploy)"
  value       = aws_s3_bucket.frontend.id
}

output "s3_bucket_arn" {
  description = "S3 Bucket ARN"
  value       = aws_s3_bucket.frontend.arn
}
