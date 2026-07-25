output "oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC identity provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "github_oidc_role_arn" {
  description = "ARN of the GitHub OIDC role used for ECS deployments"
  value       = aws_iam_role.github_oidc.arn
}

output "github_terraform_role_arn" {
  description = "ARN of the GitHub Terraform CI/CD role"
  value       = aws_iam_role.github_terraform.arn
}
