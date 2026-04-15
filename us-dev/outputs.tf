output "autostart_lambda_url" {
  description = "The URL to trigger the AutoStart Lambda"
  value       = module.autostart.lambda_function_url
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID (dùng cho CI/CD cache invalidation)"
  value       = module.frontend_s3_cloudfront.cloudfront_distribution_id
}

output "frontend_s3_bucket_name" {
  description = "S3 Bucket Name cho Frontend (dùng cho CI/CD deploy)"
  value       = module.frontend_s3_cloudfront.s3_bucket_name
}

output "backend_instance_id" {
  description = "Backend EC2 Instance ID"
  value       = module.backend_ec2.instance_id
}

output "alb_dns_name" {
  description = "ALB DNS Name"
  value       = module.alb.alb_dns_name
}
