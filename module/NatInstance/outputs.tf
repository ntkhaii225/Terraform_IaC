output "network_interface_id" {
  description = "The Network Interface ID of the NAT Instance"
  value       = aws_instance.nat.primary_network_interface_id
}

output "public_ip" {
  description = "Public IP of NAT Instance"
  value       = aws_instance.nat.public_ip
}

output "instance_id" {
  description = "The ID of the NAT Instance"
  value       = aws_instance.nat.id
}
