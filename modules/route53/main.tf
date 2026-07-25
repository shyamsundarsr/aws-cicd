#------------------------------------------------------------------------------
# Route 53 Module
# Creates: Public Hosted Zone and an A-record alias pointing to the ALB.
#------------------------------------------------------------------------------

resource "aws_route53_zone" "this" {
  name = var.domain_name
  tags = merge(var.tags, { Name = "${var.name_prefix}-hosted-zone" })
}

resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.this.id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
