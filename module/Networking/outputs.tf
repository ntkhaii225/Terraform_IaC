# --- VPC Outputs ---
output "vpc_id" {
  description = "VPC Id"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of VPC"
  value       = aws_vpc.main.cidr_block
}

# --- Subnet Outputs ---
output "public_subnet_id" {
  description = "Public Subnet Id"
  value       = aws_subnet.public.id
}

output "public_subnet_cidr" {
  description = "Public Subnet Cidr"
  value       = aws_subnet.public.cidr_block
}

output "private_subnet_id" {
  description = "Private Subnet Id"
  value       = aws_subnet.private.id
}

output "private_subnet_cidr" {
  description = "Private Subnet Cidr"
  value       = aws_subnet.private.cidr_block
}

# --- Gateway & Route Table Outputs ---
output "internet_gateway_id" {
  description = "Internet Gateway Id"
  value       = aws_internet_gateway.main.id
}

output "public_route_table_id" {
  description = "Public Route Table Id"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "Private Route Table Id"
  value       = aws_route_table.private.id
}



# --- Subnet 2 Outputs ---
output "public_subnet_id_2" {
  description = "Public Subnet 2 Id"
  value       = aws_subnet.public_2.id
}

output "public_subnet_cidr_2" {
  description = "Public Subnet 2 Cidr"
  value       = aws_subnet.public_2.cidr_block
}

output "private_subnet_id_2" {
  description = "Private Subnet 2 Id"
  value       = aws_subnet.private_2.id
}

output "private_subnet_cidr_2" {
  description = "Private Subnet 2 Cidr"
  value       = aws_subnet.private_2.cidr_block
}

# --- List Outputs (Useful for ALB) ---
output "public_subnet_ids" {
  description = "List of all public subnet IDs (for ALB)"
  value       = [aws_subnet.public.id, aws_subnet.public_2.id]
}

output "private_subnet_ids" {
  description = "List of all private subnet IDs (for ECS tasks)"
  value       = [aws_subnet.private.id, aws_subnet.private_2.id]
}
