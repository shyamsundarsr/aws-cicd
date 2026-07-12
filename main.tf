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
#AWS Private Subnets (Backend and Database)
resource "aws_subnet" "private_backend_subnet" {
  for_each                = var.private_backend_subnet
  vpc_id                  = aws_vpc.tf-vpc.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = false
  tags                    = merge(var.tags, { Name = "tf-private-subnet" })
}

resource "aws_subnet" "private_db_subnet" {
  for_each                = var.private_db_subnet
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
#AWS Route Table for Private Subnets (Backend and Database)
resource "aws_route_table" "private_backend_route_table" {
  vpc_id   = aws_vpc.tf-vpc.id
  for_each = var.private_backend_subnet

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw[each.key].id
  }
  tags = merge(var.tags, { Name = "tf-private-route-table" })
}

resource "aws_route_table" "private_db_route_table" {
  vpc_id   = aws_vpc.tf-vpc.id
  for_each = var.private_db_subnet

  # route {
  #   cidr_block     = "0.0.0.0/0"
  #   nat_gateway_id = aws_nat_gateway.nat-gw[each.key].id
  # }
  tags = merge(var.tags, { Name = "tf-private-route-table" })
}

#AWS Route Table Association for Public Subnet
resource "aws_route_table_association" "public_subnet_route_association" {
  for_each       = var.public_subnet
  subnet_id      = aws_subnet.public_subnet[each.key].id
  route_table_id = aws_route_table.public_route_table.id
}

#AWS Route Table Associations for Private Subnets (Backend and Database)
resource "aws_route_table_association" "private_backend_subnet_route_association" {
  for_each       = var.private_backend_subnet
  subnet_id      = aws_subnet.private_backend_subnet[each.key].id
  route_table_id = aws_route_table.private_backend_route_table[each.key].id
}
resource "aws_route_table_association" "private_db_subnet_route_association" {
  for_each       = var.private_db_subnet
  subnet_id      = aws_subnet.private_db_subnet[each.key].id
  route_table_id = aws_route_table.private_db_route_table[each.key].id
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
resource "aws_lb_target_group" "tf-alb-frontend-tg" {
  name        = "tf-alb-frontend-tg"
  port        = 8080
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

resource "aws_lb_target_group" "tf-alb-backend-tg" {
  name        = "tf-alb-backend-tg"
  port        = 9966
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.tf-vpc.id

  health_check {
    enabled           = true
    path              = "/petclinic/actuator/health"
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
resource "aws_lb_listener" "tf-alb-listener-rule-frontend" {
  load_balancer_arn = aws_lb.tf-alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.tf-acm-cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tf-alb-frontend-tg.arn
  }
}

resource "aws_lb_listener_rule" "tf-alb-listener-rule-backend" {
  listener_arn = aws_lb_listener.tf-alb-listener-rule-frontend.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tf-alb-backend-tg.arn
  }

  condition {
    path_pattern {
      values = ["/petclinic/api/*", "/petclinic/api"]
    }
  }
}

#AWS CloudWatch Log Group for ECS backend
resource "aws_cloudwatch_log_group" "tf-ecs-petclinic-backend" {
  name              = "/ecs/petclinic-backend"
  retention_in_days = 14
  tags              = merge(var.tags, { Name = "tf-ecs-petclinic-backend-log-group" })
}

#AWS CloudWatch Log Group for ECS frontend
resource "aws_cloudwatch_log_group" "tf-ecs-petclinic-frontend" {
  name              = "/ecs/petclinic-frontend"
  retention_in_days = 14
  tags              = merge(var.tags, { Name = "tf-ecs-petclinic-frontend-log-group" })
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
    description     = "Allow frontend traffic from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "Allow backend traffic from ALB"
    from_port       = 9966
    to_port         = 9966
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
resource "aws_ecs_task_definition" "backend_placeholder" {
  family                   = "petclinic-backend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name = "petclinic-backend"
      # image     = "aws_ecr_repository.backend.repository_url:latest"
      image     = "nginx:alpine"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 9966
          hostPort      = 9966
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "SPRING_PROFILES_ACTIVE", value = "postgres,spring-data-jpa" },
        { name = "POSTGRES_URL", value = "jdbc:postgresql://${aws_db_instance.rds_postgres.endpoint}/${var.db_name}" },
        { name = "POSTGRES_USER", value = var.db_username },
        { name = "POSTGRES_PASS", value = random_password.rds_password.result }
      ]
    }
  ])
}
# Temporary placeholder task definition so the initial service can build
resource "aws_ecs_task_definition" "frontend_placeholder" {
  family                   = "petclinic-frontend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "petclinic-frontend"
      image     = "nginxdemos/hello" # Temporary bootstrap image
      essential = true
      command   = ["sleep", "3600"]
      portMappings = [
        {
          containerPort = 8080 # Matches your backend application port
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
    }
  ])
}

#AWS ECS Service
resource "aws_ecs_service" "tf-ecs-petclinic-frontend" {
  name            = "tf-ecs-petclinic-frontend"
  cluster         = aws_ecs_cluster.tf-ecs-cluster.id
  task_definition = aws_ecs_task_definition.frontend_placeholder.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [for subnet in aws_subnet.public_subnet : subnet.id]
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tf-alb-frontend-tg.arn
    container_name   = "petclinic-frontend"
    container_port   = 8080
  }
  lifecycle {
    ignore_changes = [
      # task_definition,
      desired_count
    ]
  }
  depends_on = [aws_lb_listener.tf-alb-listener-rule-frontend]
}

#AWS ECS Service
resource "aws_ecs_service" "tf-ecs-petclinic-backend" {
  name            = "tf-ecs-petclinic-backend"
  cluster         = aws_ecs_cluster.tf-ecs-cluster.id
  task_definition = aws_ecs_task_definition.backend_placeholder.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [for subnet in aws_subnet.private_backend_subnet : subnet.id]
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tf-alb-backend-tg.arn
    container_name   = "petclinic-backend"
    container_port   = 9966
  }
  lifecycle {
    ignore_changes = [
      # task_definition,
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


# AWS ECR repository for Docker images

resource "aws_ecr_repository" "frontend" {
  name                 = "petclinic-frontend"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(var.tags, { Name = "petclinic-frontend-ecr" })

}

resource "aws_ecr_repository" "backend" {
  name                 = "petclinic-backend"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(var.tags, { Name = "petclinic-backend-ecr" })
}

# AWS RDS PostgreSQL Database Security Group
resource "aws_security_group" "rds_sg" {
  name        = "tf-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = aws_vpc.tf-vpc.id

  ingress {
    description     = "Allow PostgreSQL traffic from ECS tasks"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# AWS RDS Subnet Group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "tf-rds-subnet-group"
  subnet_ids = [for subnet in aws_subnet.private_db_subnet : subnet.id]
  tags       = merge(var.tags, { Name = "tf-rds-subnet-group" })
}

# AWS RDS PostgreSQL Database Password
resource "random_password" "rds_password" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "rds_postgres_db_secret" {
  name        = "tf-rds-postgres-db-secret"
  description = "RDS PostgreSQL database credentials"
  tags        = merge(var.tags, { Name = "tf-rds-postgres-db-secret" })
}

resource "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id = aws_secretsmanager_secret.rds_postgres_db_secret.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.rds_password.result
  })
}

# AWS RDS PostgreSQL Database
resource "aws_db_instance" "rds_postgres" {
  identifier             = "tf-rds-postgres"
  engine                 = "postgres"
  engine_version         = "16.4"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = var.db_name
  username               = var.db_username
  password               = random_password.rds_password.result
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  multi_az               = false

  tags = merge(var.tags, { Name = "tf-rds-petclinic-db" })
}