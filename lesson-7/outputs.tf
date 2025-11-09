# Outputs for lesson-7

# EKS Cluster outputs
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region us-west-2 --name ${module.eks.cluster_name}"
}

# ECR Repository (from lesson-5)
output "ecr_repository_url" {
  description = "URL of the ECR repository (from lesson-5)"
  value       = local.ecr_repository_url
}

# VPC information (from lesson-5)
output "vpc_id" {
  description = "VPC ID (from lesson-5)"
  value       = data.terraform_remote_state.lesson5.outputs.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (from lesson-5)"
  value       = data.terraform_remote_state.lesson5.outputs.private_subnet_ids
}