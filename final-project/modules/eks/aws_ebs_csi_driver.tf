# AWS EBS CSI Driver for Persistent Volumes

# Data source to get current AWS account information
data "aws_caller_identity" "current" {}

# OIDC Provider for EKS
data "tls_certificate" "cluster" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = {
    Name        = "${var.cluster_name}-oidc-provider"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# IAM Role for EBS CSI Driver
resource "aws_iam_role" "ebs_csi_driver" {
  name = "${var.cluster_name}-ebs-csi-driver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.cluster.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub" : "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:aud" : "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = {
    Name        = "${var.cluster_name}-ebs-csi-driver-role"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# Attach AWS managed policy for EBS CSI Driver
resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}

# EKS Add-on for EBS CSI Driver
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = var.ebs_csi_driver_version
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.ebs_csi_driver
  ]

  tags = {
    Name        = "${var.cluster_name}-ebs-csi-driver"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# CoreDNS Add-on
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]

  tags = {
    Name        = "${var.cluster_name}-coredns"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# VPC CNI Add-on
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]

  tags = {
    Name        = "${var.cluster_name}-vpc-cni"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# kube-proxy Add-on
resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]

  tags = {
    Name        = "${var.cluster_name}-kube-proxy"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
