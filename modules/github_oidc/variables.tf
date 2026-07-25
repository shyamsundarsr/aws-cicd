variable "name_prefix" {
  description = "Prefix applied to all resource names"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository in 'owner/repo' format (e.g. myorg/my-app)"
  type        = string
}

variable "github_main_branch" {
  description = "Main branch name for the ECS deploy OIDC trust condition"
  type        = string
  default     = "main"
}

variable "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role (granted iam:PassRole to github_oidc_role)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
