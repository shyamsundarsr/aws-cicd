output "rds_endpoint" {
  description = "Connection endpoint for the RDS instance"
  value       = aws_db_instance.this.endpoint
}

output "rds_credentials_secret_arn" {
  description = "ARN of the RDS credentials Secrets Manager secret"
  value       = aws_secretsmanager_secret.rds_credentials.arn
}

output "rds_credentials_secret_version_arn" {
  description = "ARN of the RDS credentials secret version (used in IAM policy)"
  value       = aws_secretsmanager_secret_version.rds_credentials.arn
}

output "backend_env_secret_arn" {
  description = "ARN of the backend env Secrets Manager secret (used by ECS task)"
  value       = aws_secretsmanager_secret.backend_env.arn
}

output "backend_env_secret_version_arn" {
  description = "ARN of the backend env secret version (used in IAM policy)"
  value       = aws_secretsmanager_secret_version.backend_env.arn
}
