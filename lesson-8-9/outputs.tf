# Outputs for lesson-8-9

# EKS Cluster outputs
output "cluster_name" {
  description = "Name of the EKS cluster (from lesson-8-9)"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS"
  value       = module.eks.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC Provider for EKS (without https://)"
  value       = module.eks.oidc_provider_url
}

output "ebs_csi_driver_installed" {
  description = "EBS CSI Driver installation status"
  value       = "Installed via lesson-8-9 EKS module"
}

# Jenkins outputs
output "jenkins_url" {
  description = "URL to access Jenkins"
  value       = module.jenkins.jenkins_url
}

output "jenkins_admin_password" {
  description = "Jenkins admin password"
  value       = module.jenkins.jenkins_admin_password
  sensitive   = true
}

output "jenkins_namespace" {
  description = "Kubernetes namespace where Jenkins is deployed"
  value       = module.jenkins.jenkins_namespace
}

# Argo CD outputs
output "argocd_server_url" {
  description = "URL to access Argo CD server"
  value       = module.argocd.argocd_server_url
}

output "argocd_namespace" {
  description = "Kubernetes namespace where Argo CD is deployed"
  value       = module.argocd.argocd_namespace
}

output "argocd_initial_admin_password" {
  description = "Command to get Argo CD initial admin password"
  value       = module.argocd.argocd_initial_admin_password
}

output "app_namespace" {
  description = "Namespace where the application is deployed"
  value       = module.argocd.app_namespace
}

# Infrastructure info from previous lessons
output "ecr_repository_url" {
  description = "ECR repository URL (from lesson-5)"
  value       = data.terraform_remote_state.lesson5.outputs.ecr_repository_url
}

output "vpc_id" {
  description = "VPC ID (from lesson-5)"
  value       = data.terraform_remote_state.lesson5.outputs.vpc_id
}

output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
