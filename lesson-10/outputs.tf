# Outputs for lesson-10 infrastructure

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

# ECR Outputs
output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

# EKS Outputs
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

# RDS Outputs
output "db_endpoint" {
  description = "Database endpoint"
  value       = module.rds.db_endpoint
}

output "db_port" {
  description = "Database port"
  value       = module.rds.db_port
}

output "db_name" {
  description = "Database name"
  value       = module.rds.db_name
}

output "db_type" {
  description = "Database type (RDS or Aurora)"
  value       = module.rds.db_type
}

output "db_connection_string" {
  description = "Database connection string (without password)"
  value       = "postgresql://${var.db_username}@${module.rds.db_endpoint}/${module.rds.db_name}"
  sensitive   = true
}

# Jenkins Outputs
output "jenkins_url" {
  description = "Jenkins URL"
  value       = module.jenkins.jenkins_url
}

output "jenkins_admin_password" {
  description = "Jenkins admin password"
  value       = var.jenkins_admin_password
  sensitive   = true
}

# Argo CD Outputs
output "argocd_server_url" {
  description = "Argo CD server URL"
  value       = module.argocd.argocd_server_url
}

output "argocd_admin_password_command" {
  description = "Command to get Argo CD admin password"
  value       = module.argocd.argocd_admin_password_command
}
