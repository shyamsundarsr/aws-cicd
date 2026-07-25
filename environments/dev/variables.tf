variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment name (e.g. dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name used as a prefix for all resource names"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "Map of public subnets"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

variable "private_backend_subnets" {
  description = "Map of private backend subnets"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

variable "private_db_subnets" {
  description = "Map of private database subnets"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

variable "domain_name" {
  description = "Apex domain name (must have a matching ISSUED ACM certificate)"
  type        = string
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
}

variable "db_multi_az" {
  description = "Enable Multi-AZ for RDS"
  type        = bool
}

variable "db_deletion_protection" {
  description = "Enable RDS deletion protection"
  type        = bool
}

variable "db_skip_final_snapshot" {
  description = "Skip final RDS snapshot on destroy"
  type        = bool
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
}

variable "frontend_desired_count" {
  description = "Desired number of frontend ECS tasks"
  type        = number
}

variable "backend_desired_count" {
  description = "Desired number of backend ECS tasks"
  type        = number
}

variable "frontend_cpu" {
  description = "Fargate CPU units for the frontend task"
  type        = number
}

variable "frontend_memory" {
  description = "Fargate memory (MB) for the frontend task"
  type        = number
}

variable "backend_cpu" {
  description = "Fargate CPU units for the backend task"
  type        = number
}

variable "backend_memory" {
  description = "Fargate memory (MB) for the backend task"
  type        = number
}

variable "github_repo" {
  description = "GitHub repository in 'owner/repo' format"
  type        = string
}

variable "github_main_branch" {
  description = "Main branch name for GitHub OIDC trust"
  type        = string
  default     = "main"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
