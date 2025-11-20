# Aurora Cluster Configuration
# This file handles Aurora database clusters

# Create Aurora cluster only if use_aurora = true
resource "aws_rds_cluster" "main" {
  count = var.use_aurora ? 1 : 0
  
  cluster_identifier     = "${var.project_name}-aurora-cluster"
  engine                 = var.engine == "postgres" ? "aurora-postgresql" : "aurora-mysql"
  engine_version         = var.aurora_engine_version
  engine_mode            = var.aurora_engine_mode
  
  database_name  = var.db_name
  master_username = var.db_username
  master_password = var.db_password
  port           = var.db_port
  
  db_subnet_group_name            = aws_db_subnet_group.main.name
  vpc_security_group_ids          = [aws_security_group.db.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main[0].name
  
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.backup_window
  preferred_maintenance_window = var.maintenance_window
  
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-aurora-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  
  deletion_protection = var.deletion_protection
  storage_encrypted   = var.storage_encrypted
  
  # Serverless v2 scaling configuration (if using serverless)
  dynamic "serverlessv2_scaling_configuration" {
    for_each = var.aurora_engine_mode == "provisioned" && var.aurora_serverless_v2_scaling != null ? [1] : []
    content {
      min_capacity = var.aurora_serverless_v2_scaling.min_capacity
      max_capacity = var.aurora_serverless_v2_scaling.max_capacity
    }
  }
  
  tags = {
    Name        = "${var.project_name}-aurora-cluster"
    Environment = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Aurora cluster instances (writer + readers)
resource "aws_rds_cluster_instance" "main" {
  count = var.use_aurora ? var.aurora_instance_count : 0
  
  identifier         = "${var.project_name}-aurora-instance-${count.index}"
  cluster_identifier = aws_rds_cluster.main[0].id
  
  instance_class = var.aurora_instance_class != "" ? var.aurora_instance_class : var.instance_class
  engine         = aws_rds_cluster.main[0].engine
  engine_version = aws_rds_cluster.main[0].engine_version
  
  publicly_accessible = var.publicly_accessible
  
  # Performance Insights
  performance_insights_enabled = var.performance_insights_enabled
  
  tags = {
    Name        = "${var.project_name}-aurora-instance-${count.index}"
    Environment = var.project_name
    ManagedBy   = "Terraform"
    Role        = count.index == 0 ? "writer" : "reader"
  }
}

# Aurora cluster parameter group
resource "aws_rds_cluster_parameter_group" "main" {
  count = var.use_aurora ? 1 : 0
  
  name        = "${var.project_name}-aurora-cluster-params"
  family      = var.aurora_parameter_group_family != "" ? var.aurora_parameter_group_family : (var.engine == "postgres" ? "aurora-postgresql15" : "aurora-mysql8.0")
  description = "Cluster parameter group for ${var.project_name} Aurora"
  
  # Apply custom parameters
  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }
  
  tags = {
    Name        = "${var.project_name}-aurora-cluster-params"
    Environment = var.project_name
    ManagedBy   = "Terraform"
  }
}
