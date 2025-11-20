# Jenkins installation via Helm with IRSA for ECR access

# Data source to get current AWS account
data "aws_caller_identity" "current" {}

# Create Kubernetes namespace for Jenkins
resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.namespace
  }
}

# Create service account for Jenkins
resource "kubernetes_service_account" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.jenkins_ecr.arn
    }
  }
}

# IAM Role for Jenkins with IRSA (to push to ECR)
resource "aws_iam_role" "jenkins_ecr" {
  name = "${var.cluster_name}-jenkins-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" : "system:serviceaccount:${var.namespace}:jenkins"
          "${var.oidc_provider_url}:aud" : "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = {
    Name        = "${var.cluster_name}-jenkins-ecr-role"
    Environment = "lesson-8-9"
  }
}

# IAM Policy for ECR push access
resource "aws_iam_role_policy" "jenkins_ecr_policy" {
  name = "${var.cluster_name}-jenkins-ecr-policy"
  role = aws_iam_role.jenkins_ecr.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/*"
      }
    ]
  })
}

# Install Jenkins via Helm
resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = "5.1.27"
  namespace  = kubernetes_namespace.jenkins.metadata[0].name

  values = [
    templatefile("${path.module}/values.yaml", {
      service_account_name = kubernetes_service_account.jenkins.metadata[0].name
      admin_password      = var.jenkins_admin_password
      ecr_repository_url  = var.ecr_repository_url
      git_repo_url        = var.git_repo_url
      git_branch          = var.git_branch
      aws_region          = var.aws_region
      aws_account_id      = data.aws_caller_identity.current.account_id
    })
  ]

  depends_on = [
    kubernetes_service_account.jenkins,
    aws_iam_role_policy.jenkins_ecr_policy
  ]
}
