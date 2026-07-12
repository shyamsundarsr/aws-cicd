# Trust Policy (Allows the ECS Service to assume these roles)
data "aws_iam_policy_document" "ecs_tasks_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ECS Task Execution Role (For pulling images & logs)
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecs_task_execution_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role_policy.json
  tags               = var.tags
}

# Attach AWS managed policy for standard ECS execution tasks

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Permissions policy (Allows ECS to inject secrets into the container)
data "aws_iam_policy_document" "ecs_secrets_access_policy" {
  statement {
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      aws_secretsmanager_secret_version.rds_secret_version.secret_arn,
      aws_secretsmanager_secret_version.petclinic_backend_env_version.secret_arn
    ]
  }
}

# IAM policy for ECS tasks to access RDS secrets
resource "aws_iam_policy" "ecs_secrets_policy" {
  name        = "ecs_secrets_policy"
  description = "Policy for ECS tasks to access RDS secrets"
  policy      = data.aws_iam_policy_document.ecs_secrets_access_policy.json
}

# Attach the secrets access policy to the ECS task execution role
resource "aws_iam_role_policy_attachment" "ecs_secrets_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_secrets_policy.arn
}