# Outputs for Argo CD module

output "argocd_server_url" {
  description = "URL to access Argo CD server (LoadBalancer endpoint)"
  value       = "http://${try(data.kubernetes_service.argocd_server.status[0].load_balancer[0].ingress[0].hostname, "pending")}"
}

output "argocd_namespace" {
  description = "Kubernetes namespace where Argo CD is deployed"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "argocd_initial_admin_password" {
  description = "Initial admin password for Argo CD (stored in secret)"
  value       = "Run: kubectl -n ${kubernetes_namespace.argocd.metadata[0].name} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
  sensitive   = false
}

output "app_namespace" {
  description = "Namespace where the application is deployed"
  value       = kubernetes_namespace.app.metadata[0].name
}

# Data source to get Argo CD server service details
data "kubernetes_service" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }
  
  depends_on = [helm_release.argocd]
}
