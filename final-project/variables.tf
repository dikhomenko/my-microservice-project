# Final Project Variables
# Central configuration for all infrastructure components

# ============================================================================
# General Configuration
# ============================================================================

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "final-project"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# VPC Configuration
# ============================================================================

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}

# ============================================================================
# EKS Configuration
# ============================================================================

variable "eks_cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "eks_node_instance_types" {
  description = "Instance types for EKS worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 3
}

variable "eks_node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2
}

variable "eks_node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 6
}

# ============================================================================
# Database Configuration
# ============================================================================

variable "db_engine" {
  description = "Database engine (postgres, mysql, mariadb)"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "15.4"
}

variable "db_instance_class" {
  description = "Database instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 8
    error_message = "Database password must be at least 8 characters long."
  }
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment for high availability"
  type        = bool
  default     = true
}

variable "use_aurora" {
  description = "Use Aurora cluster instead of regular RDS"
  type        = bool
  default     = false
}

# ============================================================================
# ECR Configuration
# ============================================================================

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "django-app"
}

# ============================================================================
# Jenkins Configuration
# ============================================================================

variable "jenkins_admin_password" {
  description = "Admin password for Jenkins"
  type        = string
  sensitive   = true
  default     = "admin123"
}

variable "jenkins_namespace" {
  description = "Kubernetes namespace for Jenkins"
  type        = string
  default     = "jenkins"
}

# ============================================================================
# Argo CD Configuration
# ============================================================================

variable "argocd_namespace" {
  description = "Kubernetes namespace for Argo CD"
  type        = string
  default     = "argocd"
}

variable "git_repo_url" {
  description = "Git repository URL for application source"
  type        = string
  default     = "https://github.com/dikhomenko/my-microservice-project.git"
}

variable "git_branch" {
  description = "Git branch to track"
  type        = string
  default     = "main"
}

# ============================================================================
# Monitoring Configuration
# ============================================================================

variable "monitoring_namespace" {
  description = "Kubernetes namespace for monitoring stack"
  type        = string
  default     = "monitoring"
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  sensitive   = true
  default     = "admin123"
}

variable "prometheus_retention_days" {
  description = "Number of days to retain Prometheus metrics"
  type        = number
  default     = 15
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus data"
  type        = string
  default     = "50Gi"
}

variable "grafana_storage_size" {
  description = "Storage size for Grafana data"
  type        = string
  default     = "10Gi"
}

# ============================================================================
# Application Configuration
# ============================================================================

variable "app_namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "default"
}

variable "app_replicas" {
  description = "Number of application replicas"
  type        = number
  default     = 2
}
