# Final Project Outputs
# All important resource information for operations and connectivity

# ============================================================================
# VPC Outputs
# ============================================================================

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

# ============================================================================
# ECR Outputs
# ============================================================================

output "ecr_repository_url" {
  description = "ECR repository URL for Docker images"
  value       = module.ecr.repository_url
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = module.ecr.repository_name
}

# ============================================================================
# EKS Outputs
# ============================================================================

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

# ============================================================================
# Database Outputs
# ============================================================================

output "db_endpoint" {
  description = "Database endpoint"
  value       = module.rds.db_endpoint
}

output "db_address" {
  description = "Database address (without port)"
  value       = module.rds.db_address
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
  value       = "postgresql://${var.db_username}@${module.rds.db_address}:${module.rds.db_port}/${var.db_name}"
  sensitive   = true
}

# ============================================================================
# Jenkins Outputs
# ============================================================================

output "jenkins_url" {
  description = "Jenkins URL"
  value       = module.jenkins.jenkins_url
}

output "jenkins_admin_password" {
  description = "Jenkins admin password"
  value       = var.jenkins_admin_password
  sensitive   = true
}

output "jenkins_port_forward_command" {
  description = "Command to port-forward Jenkins"
  value       = "kubectl port-forward svc/jenkins 8080:8080 -n ${var.jenkins_namespace}"
}

# ============================================================================
# Argo CD Outputs
# ============================================================================

output "argocd_server_url" {
  description = "Argo CD server URL"
  value       = module.argocd.argocd_server_url
}

output "argocd_admin_password_command" {
  description = "Command to get Argo CD admin password"
  value       = "kubectl -n ${var.argocd_namespace} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

output "argocd_port_forward_command" {
  description = "Command to port-forward Argo CD"
  value       = "kubectl port-forward svc/argocd-server 8081:443 -n ${var.argocd_namespace}"
}

# ============================================================================
# Monitoring Outputs
# ============================================================================

output "grafana_url" {
  description = "Grafana URL"
  value       = module.monitoring.grafana_url
}

output "prometheus_url" {
  description = "Prometheus URL"
  value       = module.monitoring.prometheus_url
}

output "grafana_port_forward_command" {
  description = "Command to port-forward Grafana"
  value       = "kubectl port-forward svc/grafana 3000:80 -n ${var.monitoring_namespace}"
}

output "prometheus_port_forward_command" {
  description = "Command to port-forward Prometheus"
  value       = "kubectl port-forward svc/prometheus-server 9090:80 -n ${var.monitoring_namespace}"
}

# ============================================================================
# Quick Access Commands
# ============================================================================

output "quick_commands" {
  description = "Quick access commands for deployed services"
  value       = <<-EOT
    
    ================================================================================
    QUICK ACCESS COMMANDS
    ================================================================================
    
    1. Configure kubectl:
       aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}
    
    2. Check all resources:
       kubectl get all -n ${var.jenkins_namespace}
       kubectl get all -n ${var.argocd_namespace}
       kubectl get all -n ${var.monitoring_namespace}
    
    3. Port-forward services:
       Jenkins:    kubectl port-forward svc/jenkins 8080:8080 -n ${var.jenkins_namespace}
       Argo CD:    kubectl port-forward svc/argocd-server 8081:443 -n ${var.argocd_namespace}
       Grafana:    kubectl port-forward svc/grafana 3000:80 -n ${var.monitoring_namespace}
       Prometheus: kubectl port-forward svc/prometheus-server 9090:80 -n ${var.monitoring_namespace}
    
    4. Get Argo CD admin password:
       kubectl -n ${var.argocd_namespace} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
    
    5. Access services locally:
       Jenkins:    http://localhost:8080 (admin / <jenkins_password>)
       Argo CD:    https://localhost:8081 (admin / <argocd_password>)
       Grafana:    http://localhost:3000 (admin / <grafana_password>)
       Prometheus: http://localhost:9090
    
    ================================================================================
  EOT
}
