#------------------------------------------------------------------------------
# ECR Module
# Creates private ECR repositories for frontend and backend images.
# image_tag_mutability = IMMUTABLE enforces immutable tags (enterprise standard).
# scan_on_push = true enables automated vulnerability scanning on every push.
#
# NOTE: For production environments, uncomment `prevent_destroy = true` in the
# lifecycle blocks below to protect repositories from accidental deletion.
# Terraform lifecycle arguments cannot be controlled via variables.
#------------------------------------------------------------------------------

resource "aws_ecr_repository" "frontend" {
  name                 = "${var.name_prefix}-frontend"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  # lifecycle {
  #   prevent_destroy = true  # Uncomment for production
  # }

  tags = merge(var.tags, { Name = "${var.name_prefix}-frontend-ecr" })
}

resource "aws_ecr_repository" "backend" {
  name                 = "${var.name_prefix}-backend"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  # lifecycle {
  #   prevent_destroy = true  # Uncomment for production
  # }

  tags = merge(var.tags, { Name = "${var.name_prefix}-backend-ecr" })
}
