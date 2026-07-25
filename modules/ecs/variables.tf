variable "name_prefix" {
  description = "Prefix applied to all resource names"
  type        = string
}

variable "aws_region" {
  description = "AWS region (used for CloudWatch log driver configuration)"
  type        = string
}

variable "ecs_tasks_sg_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the frontend ECS service"
  type        = list(string)
}

variable "private_backend_subnet_ids" {
  description = "Private backend subnet IDs for the backend ECS service"
  type        = list(string)
}

variable "execution_role_arn" {
  description = "ARN of the ECS task execution IAM role"
  type        = string
}

variable "frontend_tg_arn" {
  description = "ARN of the frontend ALB target group"
  type        = string
}

variable "backend_tg_arn" {
  description = "ARN of the backend ALB target group"
  type        = string
}

variable "backend_env_secret_arn" {
  description = "ARN of the backend env Secrets Manager secret (injected into container)"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days (e.g. 14 for dev, 30 for prod)"
  type        = number
  default     = 14
}

variable "frontend_desired_count" {
  description = "Desired number of frontend ECS tasks"
  type        = number
  default     = 1
}

variable "backend_desired_count" {
  description = "Desired number of backend ECS tasks"
  type        = number
  default     = 1
}

variable "frontend_cpu" {
  description = "CPU units for the frontend Fargate task (e.g. 256, 512)"
  type        = number
  default     = 256
}

variable "frontend_memory" {
  description = "Memory (MB) for the frontend Fargate task (e.g. 1024, 2048)"
  type        = number
  default     = 1024
}

variable "backend_cpu" {
  description = "CPU units for the backend Fargate task (e.g. 256, 512)"
  type        = number
  default     = 256
}

variable "backend_memory" {
  description = "Memory (MB) for the backend Fargate task (e.g. 512, 1024)"
  type        = number
  default     = 512
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
