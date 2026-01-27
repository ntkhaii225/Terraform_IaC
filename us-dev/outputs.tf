output "autostart_lambda_url" {
  description = "The URL to trigger the AutoStart Lambda"
  value       = module.autostart.lambda_function_url
}
