# Variables for Monitoring Module

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

variable "namespace" {
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

variable "prometheus_stack_version" {
  description = "Version of kube-prometheus-stack Helm chart"
  type        = string
  default     = "55.5.0"
}

variable "enable_app_monitoring" {
  description = "Enable ServiceMonitor for application monitoring"
  type        = bool
  default     = true
}

variable "app_namespace" {
  description = "Namespace where the application is deployed"
  type        = string
  default     = "default"
}
