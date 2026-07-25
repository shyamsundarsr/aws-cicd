variable "name_prefix" {
  description = "Prefix applied to all resource names"
  type        = string
}

variable "rds_credentials_secret_version_arn" {
  description = "ARN of the RDS credentials secret version (for least-privilege IAM policy)"
  type        = string
}

variable "backend_env_secret_version_arn" {
  description = "ARN of the backend env secret version (for least-privilege IAM policy)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
