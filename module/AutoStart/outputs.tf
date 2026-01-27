output "lambda_function_url" {
  description = "The URL to trigger the Lambda function"
  value       = aws_lambda_function_url.autostart_url.function_url
}

output "lambda_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.autostart.arn
}
