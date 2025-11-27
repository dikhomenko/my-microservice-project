# Argo CD installation via Helm

# Create Kubernetes namespace for Argo CD
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }
}

# Install Argo CD via Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.51.6"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [
    templatefile("${path.module}/values.yaml", {
      namespace = var.namespace
    })
  ]

  depends_on = [
    kubernetes_namespace.argocd
  ]
}

# Deploy Argo CD Application using Helm chart
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
    })
  ]

  depends_on = [
    helm_release.argocd
  ]
}

# Create namespace for the application
resource "kubernetes_namespace" "app" {
  metadata {
    name = var.app_namespace
  }
}
