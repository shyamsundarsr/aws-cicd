variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "public_subnet" {
  description = "The CIDR block for the public subnet"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

variable "private_backend_subnet" {
  description = "The CIDR block for the private backend subnet"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

variable "private_db_subnet" {
  description = "The CIDR block for the private database subnet"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

variable "domain_name" {
  description = "The domain name for the application"
  type        = string
}

variable "tags" {
  description = "Tags for the AWS resources"
  type        = map(string)
}

variable "db_name" {
  description = "The name of the RDS PostgreSQL database"
  type        = string
}

variable "db_username" {
  description = "The username for the RDS PostgreSQL database"
  type        = string
}