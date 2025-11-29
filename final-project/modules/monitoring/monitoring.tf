# Monitoring Stack Installation via Helm
# Prometheus + Grafana + AlertManager

# Create Kubernetes namespace for monitoring
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace

    labels = {
      name                           = var.namespace
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# Install Prometheus Stack via Helm (includes Prometheus, Alertmanager, Grafana)
resource "helm_release" "prometheus_stack" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.prometheus_stack_version
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    templatefile("${path.module}/values.yaml", {
      grafana_admin_password = var.grafana_admin_password
      retention_days         = var.prometheus_retention_days
      prometheus_storage     = var.prometheus_storage_size
      grafana_storage        = var.grafana_storage_size
      namespace              = var.namespace
    })
  ]

  depends_on = [kubernetes_namespace.monitoring]

  timeout = 900
}

# Create additional ServiceMonitors for custom applications
resource "kubernetes_manifest" "django_app_servicemonitor" {
  count = var.enable_app_monitoring ? 1 : 0

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "django-app-monitor"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      labels = {
        release = "prometheus"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = "django-app"
        }
      }
      endpoints = [{
        port     = "http"
        interval = "30s"
        path     = "/metrics"
      }]
      namespaceSelector = {
        matchNames = [var.app_namespace]
      }
    }
  }

  depends_on = [helm_release.prometheus_stack]
}

# ConfigMap for Grafana dashboards
resource "kubernetes_config_map" "grafana_dashboards" {
  metadata {
    name      = "grafana-custom-dashboards"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "django-app-dashboard.json" = file("${path.module}/dashboards/django-app.json")
  }

  depends_on = [helm_release.prometheus_stack]
}

# PersistentVolumeClaim for Prometheus data
resource "kubernetes_persistent_volume_claim" "prometheus_data" {
  metadata {
    name      = "prometheus-data"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "gp2"

    resources {
      requests = {
        storage = var.prometheus_storage_size
      }
    }
  }

  depends_on = [kubernetes_namespace.monitoring]
}

# PersistentVolumeClaim for Grafana data
resource "kubernetes_persistent_volume_claim" "grafana_data" {
  metadata {
    name      = "grafana-data"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "gp2"

    resources {
      requests = {
        storage = var.grafana_storage_size
      }
    }
  }

  depends_on = [kubernetes_namespace.monitoring]
}
