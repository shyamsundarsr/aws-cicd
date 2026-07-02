#AWS VPC
resource "aws_vpc" "tf-vpc" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = "tf-vpc" })
}

#AWS Internet Gateway
resource "aws_internet_gateway" "tf-ecs-igw" {
  vpc_id = aws_vpc.tf-vpc.id
  tags   = merge(var.tags, { Name = "tf-ecs-igw" })
}

#AWS Public Subnet
resource "aws_subnet" "public_subnet" {
  for_each                = var.public_subnet
  vpc_id                  = aws_vpc.tf-vpc.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true
  tags                    = merge(var.tags, { Name = "tf-public-subnet" })
}
#AWS Private Subnet
resource "aws_subnet" "private_subnet" {
  for_each                = var.private_subnet
  vpc_id                  = aws_vpc.tf-vpc.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = false
  tags                    = merge(var.tags, { Name = "tf-private-subnet" })
}

#AWS EIP for NAT Gateway
resource "aws_eip" "nat_eip" {
  for_each = var.public_subnet
  domain   = "vpc"
  tags     = merge(var.tags, { Name = "tf-nat-eip" })
}

#AWS NAT Gateway
resource "aws_nat_gateway" "nat-gw" {
  for_each      = var.public_subnet
  allocation_id = aws_eip.nat_eip[each.key].id
  subnet_id     = aws_subnet.public_subnet[each.key].id
  depends_on    = [aws_internet_gateway.tf-ecs-igw]
  tags          = merge(var.tags, { Name = "tf-nat-gw" })
}

#AWS Route Table for Public Subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.tf-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tf-ecs-igw.id
  }
  tags = merge(var.tags, { Name = "tf-public-route-table" })
}
#AWS Route Table for Private Subnet
resource "aws_route_table" "private_route_table" {
  vpc_id   = aws_vpc.tf-vpc.id
  for_each = var.private_subnet

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw[each.key].id
  }
  tags = merge(var.tags, { Name = "tf-private-route-table" })
}

#AWS Route Table Association for Public Subnet
resource "aws_route_table_association" "public_subnet_route_association" {
  for_each       = var.public_subnet
  subnet_id      = aws_subnet.public_subnet[each.key].id
  route_table_id = aws_route_table.public_route_table.id
}

#AWS Route Table Association for Private Subnet
resource "aws_route_table_association" "private_subnet_route_association" {
  for_each       = var.private_subnet
  subnet_id      = aws_subnet.private_subnet[each.key].id
  route_table_id = aws_route_table.private_route_table[each.key].id
}

#Security Group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "tf-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.tf-vpc.id

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "tf-alb-sg" })
}

#AWS Application Load Balancer
resource "aws_lb" "tf-alb" {
  name               = "tf-ecs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for subnet in aws_subnet.public_subnet : subnet.id]
  tags               = merge(var.tags, { Name = "tf-alb" })
}

#AWS ALB Target Group with HTTP health check
resource "aws_lb_target_group" "tf-alb-tg" {
  name        = "tf-lb-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.tf-vpc.id

  health_check {
    enabled           = true
    path              = "/"
    protocol          = "HTTP"
    interval          = 30
    timeout           = 5
    healthy_threshold = 3
    matcher           = "200"
  }

  tags = merge(var.tags, { Name = "tf-alb-tg" })
}

#AWS ACM Certificate
data "aws_acm_certificate" "tf-acm-cert" {
  domain   = var.domain_name
  statuses = ["ISSUED"]
}

#AWS ALB listener for HTTPS with redirect to HTTPS
resource "aws_lb_listener" "tf-alb-listener-http" {
  load_balancer_arn = aws_lb.tf-alb.arn
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

#AWS ALB Listener for HTTPS
resource "aws_lb_listener" "tf-alb-listener-https" {
  load_balancer_arn = aws_lb.tf-alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.tf-acm-cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tf-alb-tg.arn
  }
}

#AWS CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "tf-alb-log-group" {
  name              = "/aws/elasticloadbalancing/tf-alb"
  retention_in_days = 14
  tags              = merge(var.tags, { Name = "tf-alb-log-group" })
}

#AWS ECS Cluster
resource "aws_ecs_cluster" "tf-ecs-cluster" {
  name = "tf-ecs-cluster"
  tags = merge(var.tags, { Name = "tf-ecs-cluster" })
}

#AWS Security Group for ECS Tasks (Allow traffic only from ALB)
resource "aws_security_group" "ecs_tasks_sg" {
  name        = "tf-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.tf-vpc.id

  ingress {
    description     = "Allow HTTP traffic"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = merge(var.tags, { Name = "tf-ecs-tasks-sg" })
}

# Temporary placeholder task definition so the initial service can build
resource "aws_ecs_task_definition" "placeholder" {
  family                   = "tf-nginx-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "nginx:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  ])
}

#AWS ECS Service
resource "aws_ecs_service" "tf-ecs-service" {
  name            = "tf-ecs-service"
  cluster         = aws_ecs_cluster.tf-ecs-cluster.id
  task_definition = aws_ecs_task_definition.placeholder.arn
  desired_count   = 3
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [for subnet in aws_subnet.private_subnet : subnet.id]
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tf-alb-tg.arn
    container_name   = "nginx"
    container_port   = 80
  }
  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count
    ]
  }
  depends_on = [aws_lb_listener.tf-alb-listener-http]
}


#AWS Route 53 Hosted Zone for ALB
resource "aws_route53_zone" "tf-route53-zone" {
  name = var.domain_name
  tags = merge(var.tags, { Name = "tf-route53-zone" })
}

#AWS Route 53 A record for ALB
resource "aws_route53_record" "root_domain_record" {
  zone_id = aws_route53_zone.tf-route53-zone.id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = aws_lb.tf-alb.dns_name
    zone_id                = aws_lb.tf-alb.zone_id
    evaluate_target_health = true
  }
}