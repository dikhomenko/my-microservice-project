# RDS Module Outputs

# Common Outputs (for both RDS and Aurora)
output "db_type" {
  description = "Type of database deployed (RDS or Aurora)"
  value       = var.use_aurora ? "Aurora" : "RDS"
}

output "db_engine" {
  description = "Database engine"
  value       = var.engine
}

output "db_name" {
  description = "Database name"
  value       = var.db_name
}

output "db_port" {
  description = "Database port"
  value       = local.db_port
}

output "db_security_group_id" {
  description = "Security group ID for database"
  value       = aws_security_group.db.id
}

output "db_subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.main.name
}

# RDS-specific Outputs
output "db_instance_id" {
  description = "RDS instance identifier"
  value       = var.use_aurora ? null : aws_db_instance.main[0].id
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = var.use_aurora ? null : aws_db_instance.main[0].arn
}

output "db_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = var.use_aurora ? null : aws_db_instance.main[0].endpoint
}

output "db_instance_address" {
  description = "RDS instance address"
  value       = var.use_aurora ? null : aws_db_instance.main[0].address
}

# Aurora-specific Outputs
output "aurora_cluster_id" {
  description = "Aurora cluster identifier"
  value       = var.use_aurora ? aws_rds_cluster.main[0].id : null
}

output "aurora_cluster_arn" {
  description = "Aurora cluster ARN"
  value       = var.use_aurora ? aws_rds_cluster.main[0].arn : null
}

output "aurora_cluster_endpoint" {
  description = "Aurora cluster endpoint (writer)"
  value       = var.use_aurora ? aws_rds_cluster.main[0].endpoint : null
}

output "aurora_reader_endpoint" {
  description = "Aurora cluster reader endpoint"
  value       = var.use_aurora ? aws_rds_cluster.main[0].reader_endpoint : null
}

output "aurora_cluster_members" {
  description = "List of Aurora cluster members"
  value       = var.use_aurora ? aws_rds_cluster.main[0].cluster_members : null
}

# Universal Outputs (work for both types)
output "db_endpoint" {
  description = "Database endpoint (works for both RDS and Aurora)"
  value       = var.use_aurora ? aws_rds_cluster.main[0].endpoint : aws_db_instance.main[0].endpoint
}

output "db_address" {
  description = "Database address without port"
  value       = var.use_aurora ? split(":", aws_rds_cluster.main[0].endpoint)[0] : aws_db_instance.main[0].address
}

output "db_connection_info" {
  description = "Database connection information"
  value = {
    type     = var.use_aurora ? "Aurora" : "RDS"
    engine   = var.engine
    endpoint = var.use_aurora ? aws_rds_cluster.main[0].endpoint : aws_db_instance.main[0].endpoint
    port     = local.db_port
    database = var.db_name
    username = var.db_username
  }
  sensitive = true
}

# Local value for port resolution
locals {
  db_port = coalesce(
    var.db_port,
    var.engine == "postgres" ? 5432 : 3306
  )
}
