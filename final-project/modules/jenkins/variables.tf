# Variables for Jenkins Module

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
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

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for the EKS cluster"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the OIDC provider (without https://)"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for Jenkins"
  type        = string
  default     = "jenkins"
}

variable "jenkins_admin_password" {
  description = "Admin password for Jenkins"
  type        = string
  sensitive   = true
  default     = "admin123"
}

variable "ecr_repository_url" {
  description = "ECR repository URL for pushing images"
  type        = string
}

variable "git_repo_url" {
  description = "Git repository URL for the application"
  type        = string
  default     = "https://github.com/dikhomenko/my-microservice-project.git"
}

variable "git_branch" {
  description = "Git branch to use"
  type        = string
  default     = "main"
}

variable "jenkins_chart_version" {
  description = "Jenkins Helm chart version"
  type        = string
  default     = "5.1.27"
}
