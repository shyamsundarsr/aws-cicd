#------------------------------------------------------------------------------
# IAM Module
# Creates: ECS Task Execution Role with:
#   - AmazonECSTaskExecutionRolePolicy (ECR pull + CloudWatch logs)
#   - Custom Secrets Manager policy (least-privilege access to specific secrets)
#------------------------------------------------------------------------------

data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name               = "${var.name_prefix}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_managed" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_secrets_access" {
  statement {
    sid     = "AllowSecretsManagerAccess"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      var.rds_credentials_secret_version_arn,
      var.backend_env_secret_version_arn,
    ]
  }
}

resource "aws_iam_policy" "ecs_secrets" {
  name        = "${var.name_prefix}-ecs-secrets-policy"
  description = "Least-privilege Secrets Manager access for ECS task execution role"
  policy      = data.aws_iam_policy_document.ecs_secrets_access.json
}

resource "aws_iam_role_policy_attachment" "ecs_secrets" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.ecs_secrets.arn
}
