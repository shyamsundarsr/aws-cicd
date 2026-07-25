#------------------------------------------------------------------------------
# ECS Module
# Creates: CloudWatch Log Groups, ECS Cluster, placeholder Task Definitions
# (frontend + backend), and ECS Fargate Services.
#
# Placeholder task definitions use lightweight images so the initial service
# can be created. CI/CD (GitHub Actions via OIDC) updates these on each deploy.
# The `ignore_changes` lifecycle blocks prevent Terraform from reverting
# CI/CD-managed task definitions and desired_counts on subsequent applies.
#------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.name_prefix}-frontend"
  retention_in_days = var.log_retention_days
  tags              = merge(var.tags, { Name = "${var.name_prefix}-frontend-log-group" })
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.name_prefix}-backend"
  retention_in_days = var.log_retention_days
  tags              = merge(var.tags, { Name = "${var.name_prefix}-backend-log-group" })
}

resource "aws_ecs_cluster" "this" {
  name = "${var.name_prefix}-cluster"
  tags = merge(var.tags, { Name = "${var.name_prefix}-cluster" })
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.name_prefix}-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.frontend_cpu)
  memory                   = tostring(var.frontend_memory)
  execution_role_arn       = var.execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "${var.name_prefix}-frontend"
      image     = "nginxdemos/hello"
      essential = true
      command   = ["sleep", "3600"]
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.frontend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.name_prefix}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.backend_cpu)
  memory                   = tostring(var.backend_memory)
  execution_role_arn       = var.execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "${var.name_prefix}-backend"
      image     = "nginx:alpine"
      essential = true
      portMappings = [
        {
          containerPort = 9966
          hostPort      = 9966
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      environment = [
        { name = "SPRING_PROFILES_ACTIVE", value = "postgres,spring-data-jpa" }
      ]
      secrets = [
        { name = "POSTGRES_URL", valueFrom = "${var.backend_env_secret_arn}:POSTGRES_URL::" },
        { name = "POSTGRES_USER", valueFrom = "${var.backend_env_secret_arn}:POSTGRES_USER::" },
        { name = "POSTGRES_PASS", valueFrom = "${var.backend_env_secret_arn}:POSTGRES_PASS::" }
      ]
    }
  ])
}

resource "aws_ecs_service" "frontend" {
  name                              = "${var.name_prefix}-frontend"
  cluster                           = aws_ecs_cluster.this.id
  task_definition                   = aws_ecs_task_definition.frontend.arn
  desired_count                     = var.frontend_desired_count
  health_check_grace_period_seconds = 120
  launch_type                       = "FARGATE"

  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [var.ecs_tasks_sg_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.frontend_tg_arn
    container_name   = "${var.name_prefix}-frontend"
    container_port   = 8080
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}

resource "aws_ecs_service" "backend" {
  name                              = "${var.name_prefix}-backend"
  cluster                           = aws_ecs_cluster.this.id
  task_definition                   = aws_ecs_task_definition.backend.arn
  desired_count                     = var.backend_desired_count
  health_check_grace_period_seconds = 120
  launch_type                       = "FARGATE"

  network_configuration {
    subnets          = var.private_backend_subnet_ids
    security_groups  = [var.ecs_tasks_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.backend_tg_arn
    container_name   = "${var.name_prefix}-backend"
    container_port   = 9966
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}
