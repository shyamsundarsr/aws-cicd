output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_frontend_service_name" {
  description = "Name of the frontend ECS service"
  value       = module.ecs.frontend_service_name
}

output "ecs_backend_service_name" {
  description = "Name of the backend ECS service"
  value       = module.ecs.backend_service_name
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "frontend_ecr_url" {
  description = "ECR URL for the frontend image"
  value       = module.ecr.frontend_repository_url
}

output "backend_ecr_url" {
  description = "ECR URL for the backend image"
  value       = module.ecr.backend_repository_url
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.rds_endpoint
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = module.iam.ecs_task_execution_role_arn
}

output "github_oidc_role_arn" {
  description = "ARN of the GitHub OIDC deploy role"
  value       = module.github_oidc.github_oidc_role_arn
}

output "github_terraform_role_arn" {
  description = "ARN of the GitHub Terraform CI/CD role"
  value       = module.github_oidc.github_terraform_role_arn
}

output "route53_name_servers" {
  description = "Name servers – update your domain registrar with these"
  value       = module.route53.name_servers
}
