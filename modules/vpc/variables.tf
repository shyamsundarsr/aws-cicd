variable "name_prefix" {
  description = "Prefix applied to all resource names (e.g. petclinic-dev)"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "Map of public subnets keyed by AZ shortname"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

variable "private_backend_subnets" {
  description = "Map of private backend (ECS) subnets keyed by AZ shortname"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

variable "private_db_subnets" {
  description = "Map of private database subnets keyed by AZ shortname"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
