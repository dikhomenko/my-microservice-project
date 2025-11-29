# Shared Resources for both RDS and Aurora
# These resources are created regardless of database type

# Local values
locals {
  db_port = var.db_port != null ? var.db_port : (var.engine == "postgres" ? 5432 : 3306)
}

# DB Subnet Group - required for both RDS and Aurora
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.subnet_ids

  description = "Database subnet group for ${var.project_name}"

  tags = {
    Name        = "${var.project_name}-db-subnet-group"
    Environment = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Security Group for database access
resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "Security group for ${var.project_name} database"
  vpc_id      = var.vpc_id

  # Ingress rule - allow database connections from CIDR blocks
  ingress {
    description = "Database access from allowed CIDR blocks"
    from_port   = local.db_port
    to_port     = local.db_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Additional security group rules if specified
  dynamic "ingress" {
    for_each = var.allowed_security_groups
    content {
      description     = "Database access from security group ${ingress.value}"
      from_port       = local.db_port
      to_port         = local.db_port
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  # Egress rule - allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-db-sg"
    Environment = var.project_name
    ManagedBy   = "Terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# CloudWatch Alarms for Database Monitoring
resource "aws_cloudwatch_metric_alarm" "database_cpu" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.project_name}-db-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Database CPU utilization is too high"

  dimensions = {
    DBInstanceIdentifier = var.use_aurora ? aws_rds_cluster.main[0].cluster_identifier : aws_db_instance.main[0].identifier
  }

  tags = {
    Name        = "${var.project_name}-db-cpu-alarm"
    Environment = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "database_memory" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.project_name}-db-memory-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "100000000" # 100 MB
  alarm_description   = "Database free memory is too low"

  dimensions = {
    DBInstanceIdentifier = var.use_aurora ? aws_rds_cluster.main[0].cluster_identifier : aws_db_instance.main[0].identifier
  }

  tags = {
    Name        = "${var.project_name}-db-memory-alarm"
    Environment = var.project_name
    ManagedBy   = "Terraform"
  }
}
