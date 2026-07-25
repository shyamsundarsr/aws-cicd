#------------------------------------------------------------------------------
# ALB Module
# Creates: ALB, Frontend & Backend Target Groups, HTTP→HTTPS redirect listener,
# HTTPS listener (TLS 1.3 policy), Backend path-based listener rule,
# and reads the ACM certificate by domain name.
#------------------------------------------------------------------------------

data "aws_acm_certificate" "this" {
  domain   = var.domain_name
  statuses = ["ISSUED"]
}

resource "aws_lb" "this" {
  name               = "${var.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids
  tags               = merge(var.tags, { Name = "${var.name_prefix}-alb" })
}

resource "aws_lb_target_group" "frontend" {
  name        = "${var.name_prefix}-frontend-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled           = true
    path              = "/"
    protocol          = "HTTP"
    interval          = 30
    timeout           = 5
    healthy_threshold = 3
    matcher           = "200"
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-frontend-tg" })
}

resource "aws_lb_target_group" "backend" {
  name        = "${var.name_prefix}-backend-tg"
  port        = 9966
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled           = true
    path              = "/petclinic/actuator/health"
    protocol          = "HTTP"
    interval          = 30
    timeout           = 5
    healthy_threshold = 3
    matcher           = "200-499"
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-backend-tg" })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.this.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener_rule" "backend" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/petclinic/api/*", "/petclinic/api"]
    }
  }
}
