#------------------------------------------------------------------------------
# PROD environment variable values
# Usage: terraform apply -var-file="prod.tfvars"
# Or rename to terraform.tfvars for auto-loading.
#------------------------------------------------------------------------------

aws_region   = "us-east-1"
environment  = "prod"
project_name = "petclinic"

# Networking – separate CIDR range from dev to avoid overlap
cidr_block = "10.1.0.0/16"

public_subnets = {
  az_1 = { cidr_block = "10.1.1.0/24", availability_zone = "us-east-1a" }
  az_2 = { cidr_block = "10.1.2.0/24", availability_zone = "us-east-1b" }
}

private_backend_subnets = {
  az_1 = { cidr_block = "10.1.10.0/24", availability_zone = "us-east-1a" }
  az_2 = { cidr_block = "10.1.20.0/24", availability_zone = "us-east-1b" }
}

private_db_subnets = {
  az_1 = { cidr_block = "10.1.30.0/24", availability_zone = "us-east-1a" }
  az_2 = { cidr_block = "10.1.40.0/24", availability_zone = "us-east-1b" }
}

# DNS / TLS
domain_name = "shyamdevops.online"

# Database – prod is HA (Multi-AZ, deletion protection, final snapshot on destroy)
db_name                = "postgres"
db_username            = "petclinic"
db_instance_class      = "db.t3.medium"
db_allocated_storage   = 50
db_multi_az            = true
db_deletion_protection = true
db_skip_final_snapshot = false

# ECS – two replicas, larger Fargate sizes for prod
log_retention_days     = 30
frontend_desired_count = 2
backend_desired_count  = 2
frontend_cpu           = 512
frontend_memory        = 2048
backend_cpu            = 512
backend_memory         = 1024

# GitHub OIDC
github_repo        = "shyamsundarsr/aws-cicd"
github_main_branch = "main"

tags = {
  CreatedBy = "terraform"
  Owner     = "platform-team"
}
