output "db_endpoint" {
  description = "The connection endpoint"
  value       = aws_db_instance.mysql.endpoint
}

output "db_address" {
  description = "The hostname of the RDS instance"
  value       = aws_db_instance.mysql.address
}

output "db_port" {
  description = "The port of the RDS instance"
  value       = aws_db_instance.mysql.port
}
