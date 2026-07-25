#------------------------------------------------------------------------------
# RDS Module
# Creates: DB Subnet Group, random password, Secrets Manager secrets
# (RDS credentials + backend runtime env), and the RDS PostgreSQL instance.
# The backend-env secret is constructed here because it requires the RDS
# endpoint, keeping all database concerns in one module.
#------------------------------------------------------------------------------

resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-rds-subnet-group"
  subnet_ids = var.private_db_subnet_ids
  tags       = merge(var.tags, { Name = "${var.name_prefix}-rds-subnet-group" })
}

resource "random_password" "rds" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "rds_credentials" {
  name        = "${var.name_prefix}/rds-credentials"
  description = "RDS PostgreSQL credentials for ${var.name_prefix}"
  tags        = merge(var.tags, { Name = "${var.name_prefix}-rds-credentials" })
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.rds.result
  })
}

resource "aws_secretsmanager_secret" "backend_env" {
  name        = "${var.name_prefix}/backend-env"
  description = "Runtime environment variables for the Spring Boot backend (${var.name_prefix})"
  tags        = merge(var.tags, { Name = "${var.name_prefix}-backend-env-secret" })
}

resource "aws_secretsmanager_secret_version" "backend_env" {
  secret_id = aws_secretsmanager_secret.backend_env.id
  secret_string = jsonencode({
    POSTGRES_URL  = "jdbc:postgresql://${aws_db_instance.this.endpoint}/${var.db_name}"
    POSTGRES_USER = var.db_username
    POSTGRES_PASS = random_password.rds.result
  })
}

resource "aws_db_instance" "this" {
  identifier             = "${var.name_prefix}-postgres"
  engine                 = "postgres"
  engine_version         = "16.4"
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  db_name                = var.db_name
  username               = var.db_username
  password               = random_password.rds.result
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.rds_sg_id]
  skip_final_snapshot    = var.skip_final_snapshot
  publicly_accessible    = false
  multi_az               = var.multi_az
  deletion_protection    = var.deletion_protection
  storage_encrypted      = true

  tags = merge(var.tags, { Name = "${var.name_prefix}-rds-postgres" })
}
