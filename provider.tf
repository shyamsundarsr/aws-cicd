provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket       = "shyam-tf-state-261371110333-us-east-1-an"
    key          = "infra/aws-cicd/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
