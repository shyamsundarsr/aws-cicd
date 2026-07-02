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