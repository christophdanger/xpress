# Outputs for User Stories 1.1 & 1.2
# Networking infrastructure outputs only

# ===========================================
# NETWORKING OUTPUTS (User Story 1.2)
# ===========================================
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "public_subnet_cidr" {
  description = "CIDR block of the public subnet"
  value       = aws_subnet.public.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = var.aws_region
}

# ===========================================
# COMPUTE OUTPUTS (User Story 1.3)
# ===========================================
output "instance_id" {
  description = "ID of the ERPNext EC2 instance"
  value       = aws_instance.erpnext.id
}

output "instance_public_ip" {
  description = "Public IP address of the ERPNext instance"
  value       = aws_instance.erpnext.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the ERPNext instance"
  value       = aws_instance.erpnext.public_dns
}

output "security_group_id" {
  description = "ID of the ERPNext security group"
  value       = aws_security_group.erpnext_sg.id
}
