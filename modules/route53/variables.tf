variable "name_prefix" {
  description = "Prefix applied to all resource names"
  type        = string
}

variable "domain_name" {
  description = "Apex domain name for the Route 53 hosted zone"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB (for the A-record alias)"
  type        = string
}

variable "alb_zone_id" {
  description = "Canonical hosted zone ID of the ALB (for the A-record alias)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
