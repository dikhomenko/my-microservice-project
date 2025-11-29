# Outputs for Monitoring Module

output "grafana_url" {
  description = "URL to access Grafana (LoadBalancer endpoint)"
  value       = "http://${try(data.kubernetes_service.grafana.status[0].load_balancer[0].ingress[0].hostname, "pending")}"
}

output "prometheus_url" {
  description = "URL to access Prometheus (ClusterIP - use port-forward)"
  value       = "http://prometheus-kube-prometheus-prometheus.${var.namespace}.svc.cluster.local:9090"
}

output "alertmanager_url" {
  description = "URL to access Alertmanager (ClusterIP - use port-forward)"
  value       = "http://prometheus-kube-prometheus-alertmanager.${var.namespace}.svc.cluster.local:9093"
}

output "monitoring_namespace" {
  description = "Kubernetes namespace where monitoring stack is deployed"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = var.grafana_admin_password
  sensitive   = true
}

output "port_forward_commands" {
  description = "Commands to port-forward monitoring services"
  value = {
    grafana      = "kubectl port-forward svc/prometheus-grafana 3000:80 -n ${var.namespace}"
    prometheus   = "kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n ${var.namespace}"
    alertmanager = "kubectl port-forward svc/prometheus-kube-prometheus-alertmanager 9093:9093 -n ${var.namespace}"
  }
}

# Data source to get Grafana service details
data "kubernetes_service" "grafana" {
  metadata {
    name      = "prometheus-grafana"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  depends_on = [helm_release.prometheus_stack]
}
