#------------------------------------------------------------------------------
# DEV environment variable values
# Usage: terraform apply -var-file="dev.tfvars"
# Or rename to terraform.tfvars for auto-loading.
#------------------------------------------------------------------------------

aws_region   = "us-east-1"
environment  = "dev"
project_name = "petclinic"

# Networking
cidr_block = "10.0.0.0/16"

public_subnets = {
  az_1 = { cidr_block = "10.0.1.0/24", availability_zone = "us-east-1a" }
  az_2 = { cidr_block = "10.0.2.0/24", availability_zone = "us-east-1b" }
}

private_backend_subnets = {
  az_1 = { cidr_block = "10.0.10.0/24", availability_zone = "us-east-1a" }
  az_2 = { cidr_block = "10.0.20.0/24", availability_zone = "us-east-1b" }
}

private_db_subnets = {
  az_1 = { cidr_block = "10.0.30.0/24", availability_zone = "us-east-1a" }
  az_2 = { cidr_block = "10.0.40.0/24", availability_zone = "us-east-1b" }
}

# DNS / TLS
domain_name = "shyamdevops.online"

# Database – dev is cost-optimised (single-AZ, no deletion protection)
db_name                = "postgres"
db_username            = "petclinic"
db_instance_class      = "db.t3.micro"
db_allocated_storage   = 20
db_multi_az            = false
db_deletion_protection = false
db_skip_final_snapshot = true

# ECS – single replica, small Fargate sizes for dev
log_retention_days     = 14
frontend_desired_count = 1
backend_desired_count  = 1
frontend_cpu           = 256
frontend_memory        = 1024
backend_cpu            = 256
backend_memory         = 512

# GitHub OIDC
github_repo        = "shyamsundarsr/aws-cicd"
github_main_branch = "main"

tags = {
  CreatedBy = "terraform"
  Owner     = "platform-team"
}
