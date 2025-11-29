# Argo CD Installation via Helm

# Create Kubernetes namespace for Argo CD
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace

    labels = {
      name                           = var.namespace
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# Install Argo CD via Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [
    templatefile("${path.module}/values.yaml", {
      namespace = var.namespace
    })
  ]

  depends_on = [kubernetes_namespace.argocd]

  timeout = 600
}

# Deploy Argo CD Application using local Helm chart
resource "helm_release" "argocd_apps" {
  name      = "argocd-apps"
  chart     = "${path.module}/charts/argo-apps"
  namespace = kubernetes_namespace.argocd.metadata[0].name

  values = [
    yamlencode({
      gitRepoUrl        = var.git_repo_url
      gitTargetRevision = var.git_target_revision
      chartPath         = var.chart_path
      appNamespace      = var.app_namespace
      argocdNamespace   = var.namespace
      dbHost            = var.db_host
      dbPort            = var.db_port
      dbName            = var.db_name
      dbUsername        = var.db_username
      dbPassword        = var.db_password
    })
  ]

  depends_on = [helm_release.argocd]
}

# Create namespace for the application
resource "kubernetes_namespace" "app" {
  metadata {
    name = var.app_namespace

    labels = {
      name                           = var.app_namespace
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# Create secret for database credentials in application namespace
resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "db-credentials"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    DB_HOST     = var.db_host
    DB_PORT     = tostring(var.db_port)
    DB_NAME     = var.db_name
    DB_USERNAME = var.db_username
    DB_PASSWORD = var.db_password
  }

  type = "Opaque"
}
