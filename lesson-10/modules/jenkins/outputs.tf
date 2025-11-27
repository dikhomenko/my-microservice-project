# Outputs for Jenkins module

output "jenkins_url" {
  description = "URL to access Jenkins (LoadBalancer endpoint)"
  value       = "http://${try(data.kubernetes_service.jenkins.status[0].load_balancer[0].ingress[0].hostname, "pending")}"
}

output "jenkins_admin_password" {
  description = "Jenkins admin password"
  value       = var.jenkins_admin_password
  sensitive   = true
}

output "jenkins_namespace" {
  description = "Kubernetes namespace where Jenkins is deployed"
  value       = kubernetes_namespace.jenkins.metadata[0].name
}

output "jenkins_service_account" {
  description = "Jenkins service account name"
  value       = kubernetes_service_account.jenkins.metadata[0].name
}

output "jenkins_iam_role_arn" {
  description = "IAM role ARN for Jenkins with ECR access"
  value       = aws_iam_role.jenkins_ecr.arn
}

# Data source to get Jenkins service details
data "kubernetes_service" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }
  
  depends_on = [helm_release.jenkins]
}
