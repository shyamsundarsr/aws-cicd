resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "github_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud" #Audience
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub" #Subject
      values   = ["repo:shyamsundarsr/aws-cicd:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_oidc_role" {
  name               = "github_oidc_role"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "github_actions_ecs_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition"
    ]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.ecs_task_execution_role.arn] # Explicit reference to your existing role! 
  }
}

resource "aws_iam_policy" "github_actions_ecs_policy" {
  name   = "github_actions_ecs_policy"
  policy = data.aws_iam_policy_document.github_actions_ecs_permissions.json
}

resource "aws_iam_role_policy_attachment" "github_actions_attach" {
  role       = aws_iam_role.github_oidc_role.name
  policy_arn = aws_iam_policy.github_actions_ecs_policy.arn
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
      values   = ["repo:shyamsundarsr/aws-cicd:ref:*"]
    }
  }
}

resource "aws_iam_role" "github_terraform_role" {
  name               = "github_terraform_role"
  assume_role_policy = data.aws_iam_policy_document.github_terraform_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "github_terraform_admin_attach" {
  role       = aws_iam_role.github_terraform_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}