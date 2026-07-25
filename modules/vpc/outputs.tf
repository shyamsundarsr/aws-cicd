output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [for s in aws_subnet.public : s.id]
}

output "private_backend_subnet_ids" {
  description = "List of private backend subnet IDs"
  value       = [for s in aws_subnet.private_backend : s.id]
}

output "private_db_subnet_ids" {
  description = "List of private database subnet IDs"
  value       = [for s in aws_subnet.private_db : s.id]
}
