output "aws_region" {
  description = "The AWS region to deploy resources in"
  value       = var.aws_region
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.tf-ecs-cluster.name
}

output "ecs_service_name" {
  description = "The name of the ECS service"
  value       = aws_ecs_service.tf-ecs-service.name
}

output "github_oidc_provider_arn" {
  description = "The ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "name_servers" {
  description = "The name servers for the Route 53 hosted zone"
  value       = aws_route53_zone.tf-route53-zone.name_servers
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_oidc_role.arn
  description = "The actual IAM Role ARN for GitHub Actions to assume"
}

output "ecs_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
  description = "The ARN of the ECS task execution role"
}