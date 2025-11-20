# Main Terraform configuration for lesson-8-9 (Jenkins + Argo CD)
# Reuses infrastructure from lesson-5 (VPC, ECR)
# Creates its own EKS cluster (does NOT depend on lesson-7)

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Kubernetes provider - configure after EKS cluster is created
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name,
      "--region",
      var.aws_region
    ]
  }
}

# Helm provider - configure after EKS cluster is created
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_name,
        "--region",
        var.aws_region
      ]
    }
  }
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "jenkins_admin_password" {
  description = "Admin password for Jenkins"
  type        = string
  sensitive   = true
  default     = "admin123"
}

variable "git_repo_url" {
  description = "Git repository URL"
  type        = string
  default     = "https://github.com/dikhomenko/my-microservice-project.git"
}

# Data sources to get resources from lesson-5
data "terraform_remote_state" "lesson5" {
  backend = "s3"
  config = {
    bucket = "dina-bucket-1"
    key    = "lesson-5/terraform.tfstate"
    region = "us-west-2"
  }
}

# EKS Module (complete cluster with OIDC provider and EBS CSI driver)
# This is a full EKS cluster module copied from lesson-7 and enhanced
module "eks" {
  source = "./modules/eks"
  
  cluster_name    = "lesson-8-9-eks"
  cluster_version = "1.28"
  
  # Use VPC and subnets from lesson-5
  vpc_id          = data.terraform_remote_state.lesson5.outputs.vpc_id
  subnet_ids      = data.terraform_remote_state.lesson5.outputs.private_subnet_ids
  
  # Node group configuration
  node_group_name         = "lesson-8-9-nodes"
  node_instance_types     = ["t3.small"]
  node_desired_size       = 2
  node_min_size          = 1
  node_max_size          = 4
}

# Jenkins Module
module "jenkins" {
  source = "./modules/jenkins"
  
  aws_region         = var.aws_region
  cluster_name       = module.eks.cluster_name
  cluster_endpoint   = module.eks.cluster_endpoint
  cluster_ca_data    = module.eks.cluster_certificate_authority_data
  oidc_provider_arn  = module.eks.oidc_provider_arn
  oidc_provider_url  = module.eks.oidc_provider_url
  
  namespace              = "jenkins"
  jenkins_admin_password = var.jenkins_admin_password
  ecr_repository_url     = data.terraform_remote_state.lesson5.outputs.ecr_repository_url
  git_repo_url           = var.git_repo_url
  git_branch             = "main"
  
  depends_on = [module.eks]
}

# Argo CD Module
module "argocd" {
  source = "./modules/argo_cd"
  
  aws_region       = var.aws_region
  cluster_name     = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  cluster_ca_data  = module.eks.cluster_certificate_authority_data
  
  namespace           = "argocd"
  git_repo_url        = var.git_repo_url
  git_target_revision = "main"
  chart_path          = "lesson-8-9/charts/django-app"
  app_namespace       = "default"
  
  depends_on = [module.eks, module.jenkins]
}
