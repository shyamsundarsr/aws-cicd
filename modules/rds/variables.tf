variable "name_prefix" {
  description = "Prefix applied to all resource names"
  type        = string
}

variable "private_db_subnet_ids" {
  description = "List of private DB subnet IDs for the subnet group"
  type        = list(string)
}

variable "rds_sg_id" {
  description = "Security group ID to attach to the RDS instance"
  type        = string
}

variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
}

variable "db_username" {
  description = "Master username for the PostgreSQL database"
  type        = string
}

variable "instance_class" {
  description = "RDS instance class (e.g. db.t3.micro for dev, db.t3.medium for prod)"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "multi_az" {
  description = "Enable Multi-AZ for high availability (recommended for prod)"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Enable deletion protection (set true for prod)"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy (set false for prod)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
