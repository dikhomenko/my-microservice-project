# RDS Module Variables

# Basic Configuration
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where database will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for DB subnet group"
  type        = list(string)
}

# Database Type Selection
variable "use_aurora" {
  description = "Set to true to create Aurora cluster, false for regular RDS instance"
  type        = bool
  default     = false
}

# Engine Configuration
variable "engine" {
  description = "Database engine (postgres, mysql, mariadb, etc.)"
  type        = string
  default     = "postgres"
  
  validation {
    condition     = contains(["postgres", "mysql", "mariadb"], var.engine)
    error_message = "Engine must be one of: postgres, mysql, mariadb"
  }
}

variable "engine_version" {
  description = "Database engine version (for RDS)"
  type        = string
  default     = "15.4"
}

variable "aurora_engine_version" {
  description = "Aurora engine version (for Aurora clusters)"
  type        = string
  default     = "15.4"
}

variable "aurora_engine_mode" {
  description = "Aurora engine mode: provisioned or serverless"
  type        = string
  default     = "provisioned"
  
  validation {
    condition     = contains(["provisioned", "serverless"], var.aurora_engine_mode)
    error_message = "Aurora engine mode must be provisioned or serverless"
  }
}

# Instance Configuration
variable "instance_class" {
  description = "Database instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "aurora_instance_class" {
  description = "Aurora instance class (if different from regular RDS)"
  type        = string
  default     = ""
}

variable "aurora_instance_count" {
  description = "Number of Aurora instances (1 writer + N readers)"
  type        = number
  default     = 2
}

# Storage Configuration (RDS only)
variable "allocated_storage" {
  description = "Allocated storage in GB (RDS only)"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum allocated storage for autoscaling (RDS only)"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type (gp2, gp3, io1)"
  type        = string
  default     = "gp3"
}

variable "storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

# Database Credentials
variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Master password for database"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.db_password) >= 8
    error_message = "Database password must be at least 8 characters long"
  }
}

variable "db_port" {
  description = "Database port (default: 5432 for postgres, 3306 for mysql)"
  type        = number
  default     = null
}

# High Availability
variable "multi_az" {
  description = "Enable Multi-AZ deployment (RDS only)"
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "Make database publicly accessible"
  type        = bool
  default     = false
}

# Backup Configuration
variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "mon:04:00-mon:05:00"
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on deletion"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

# Parameter Groups
variable "parameter_group_family" {
  description = "Parameter group family (e.g., postgres15, mysql8.0)"
  type        = string
  default     = ""
}

variable "aurora_parameter_group_family" {
  description = "Aurora parameter group family"
  type        = string
  default     = ""
}

variable "parameters" {
  description = "Database parameters to apply"
  type        = map(string)
  default     = {}
}

# Monitoring
variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = []
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false
}

# Network Security
variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the database"
  type        = list(string)
  default     = []
}

variable "allowed_security_groups" {
  description = "Security group IDs allowed to access the database"
  type        = list(string)
  default     = []
}

# Aurora Serverless v2 Scaling
variable "aurora_serverless_v2_scaling" {
  description = "Serverless v2 scaling configuration"
  type = object({
    min_capacity = number
    max_capacity = number
  })
  default = null
}
