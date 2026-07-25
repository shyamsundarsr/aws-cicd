#------------------------------------------------------------------------------
# GitHub OIDC Module
# Creates: GitHub OIDC Identity Provider, two IAM roles:
#   1. github-oidc-role   – for ECS deployments (narrow ECS + iam:PassRole)
#   2. github-terraform-role – for Terraform CI/CD (AdministratorAccess)
#
# SECURITY NOTE: AdministratorAccess on the Terraform role is intentional for
# infrastructure provisioning pipelines. Restrict to specific resources once
# the infrastructure is stable.
#------------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "github_oidc_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:refs/heads/${var.github_main_branch}"]
    }
  }
}

resource "aws_iam_role" "github_oidc" {
  name               = "${var.name_prefix}-github-oidc-role"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "github_ecs_permissions" {
  statement {
    sid    = "ECSDeployPermissions"
    effect = "Allow"
    actions = [
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "PassExecutionRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [var.ecs_task_execution_role_arn]
  }
}

resource "aws_iam_policy" "github_ecs" {
  name   = "${var.name_prefix}-github-ecs-policy"
  policy = data.aws_iam_policy_document.github_ecs_permissions.json
}

resource "aws_iam_role_policy_attachment" "github_ecs" {
  role       = aws_iam_role.github_oidc.name
  policy_arn = aws_iam_policy.github_ecs.arn
}

data "aws_iam_policy_document" "github_terraform_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:*"]
    }
  }
}

resource "aws_iam_role" "github_terraform" {
  name               = "${var.name_prefix}-github-terraform-role"
  assume_role_policy = data.aws_iam_policy_document.github_terraform_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "github_terraform_admin" {
  role       = aws_iam_role.github_terraform.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
