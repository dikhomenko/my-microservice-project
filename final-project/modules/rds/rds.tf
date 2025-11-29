# RDS Module - Regular RDS Instance
# Creates regular RDS database instances (PostgreSQL, MySQL, etc.)

# Create RDS instance only if use_aurora = false
resource "aws_db_instance" "main" {
  count = var.use_aurora ? 0 : 1

  identifier     = "${var.project_name}-db"
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = local.db_port

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  parameter_group_name   = aws_db_parameter_group.main[0].name

  multi_az                  = var.multi_az
  publicly_accessible       = var.publicly_accessible
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  deletion_protection = var.deletion_protection

  performance_insights_enabled = var.performance_insights_enabled

  tags = {
    Name        = "${var.project_name}-rds-instance"
    Environment = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Parameter group for RDS instance
resource "aws_db_parameter_group" "main" {
  count = var.use_aurora ? 0 : 1

  name        = "${var.project_name}-${var.engine}-params"
  family      = var.parameter_group_family != "" ? var.parameter_group_family : "${var.engine}${split(".", var.engine_version)[0]}"
  description = "Parameter group for ${var.project_name} ${var.engine} database"

  # Apply custom parameters
  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.engine}-params"
    Environment = var.project_name
    ManagedBy   = "Terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}
