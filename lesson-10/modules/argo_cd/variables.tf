# Variables for Argo CD module

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint for EKS cluster"
  type        = string
}

variable "cluster_ca_data" {
  description = "Base64 encoded certificate data for EKS cluster"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for Argo CD"
  type        = string
  default     = "argocd"
}

variable "git_repo_url" {
  description = "Git repository URL for the application"
  type        = string
  default     = "https://github.com/dikhomenko/my-microservice-project.git"
}

variable "git_target_revision" {
  description = "Git branch/tag to track"
  type        = string
  default     = "main"
}

variable "chart_path" {
  description = "Path to Helm chart in the repository"
  type        = string
  default     = "lesson-8-9/charts/django-app"
}

variable "app_namespace" {
  description = "Namespace where the application will be deployed"
  type        = string
  default     = "default"
}

# Database connection variables
variable "db_host" {
  description = "Database host"
  type        = string
  default     = ""
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = ""
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  default     = ""
  sensitive   = true
}
