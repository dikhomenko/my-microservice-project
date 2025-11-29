# Main Terraform Configuration for Final Project
# Production-ready AWS infrastructure with EKS, RDS, CI/CD, and Monitoring

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
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# ============================================================================
# Provider Configuration
# ============================================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(var.tags, {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    })
  }
}

# Kubernetes provider - requires EKS cluster
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

# Helm provider - requires EKS cluster
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

# ============================================================================
# Local Values
# ============================================================================

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  cluster_name = "${var.project_name}-eks"
}

# ============================================================================
# S3 Backend Module - State Storage
# ============================================================================

module "s3_backend" {
  source = "./modules/s3-backend"

  bucket_name         = "${var.project_name}-terraform-state"
  dynamodb_table_name = "${var.project_name}-terraform-locks"
  aws_region          = var.aws_region
}

# ============================================================================
# VPC Module - Network Infrastructure
# ============================================================================

module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr_block     = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnets     = var.public_subnet_cidrs
  private_subnets    = var.private_subnet_cidrs
}

# ============================================================================
# ECR Module - Container Registry
# ============================================================================

module "ecr" {
  source = "./modules/ecr"

  ecr_name     = var.ecr_repository_name
  scan_on_push = true
}

# ============================================================================
# EKS Module - Kubernetes Cluster
# ============================================================================

module "eks" {
  source = "./modules/eks"

  cluster_name    = local.cluster_name
  cluster_version = var.eks_cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  node_group_name     = "${var.project_name}-nodes"
  node_instance_types = var.eks_node_instance_types
  node_desired_size   = var.eks_node_desired_size
  node_min_size       = var.eks_node_min_size
  node_max_size       = var.eks_node_max_size

  depends_on = [module.vpc]
}

# ============================================================================
# RDS Module - Database
# ============================================================================

module "rds" {
  source = "./modules/rds"

  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnet_ids

  # Database configuration
  use_aurora        = var.use_aurora
  engine            = var.db_engine
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage

  # Credentials
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  # High availability
  multi_az = var.db_multi_az

  # Security - Allow access from EKS nodes
  allowed_cidr_blocks = var.private_subnet_cidrs

  # Backup configuration
  backup_retention_period = 7
  deletion_protection     = var.environment == "production"

  # Parameter group settings
  parameters = {
    max_connections = "200"
    log_statement   = "all"
  }

  depends_on = [module.vpc]
}

# ============================================================================
# Jenkins Module - CI Server
# ============================================================================

module "jenkins" {
  source = "./modules/jenkins"

  aws_region        = var.aws_region
  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_ca_data   = module.eks.cluster_certificate_authority_data
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url

  namespace              = var.jenkins_namespace
  jenkins_admin_password = var.jenkins_admin_password
  ecr_repository_url     = module.ecr.repository_url
  git_repo_url           = var.git_repo_url
  git_branch             = var.git_branch

  depends_on = [module.eks]
}

# ============================================================================
# Argo CD Module - GitOps CD
# ============================================================================

module "argocd" {
  source = "./modules/argo_cd"

  aws_region       = var.aws_region
  cluster_name     = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  cluster_ca_data  = module.eks.cluster_certificate_authority_data

  namespace           = var.argocd_namespace
  git_repo_url        = var.git_repo_url
  git_target_revision = var.git_branch
  chart_path          = "final-project/charts/django-app"
  app_namespace       = var.app_namespace

  # Database connection details for application
  db_host     = module.rds.db_address
  db_port     = module.rds.db_port
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  depends_on = [module.eks, module.jenkins, module.rds]
}

# ============================================================================
# Monitoring Module - Prometheus & Grafana
# ============================================================================

module "monitoring" {
  source = "./modules/monitoring"

  aws_region       = var.aws_region
  cluster_name     = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  cluster_ca_data  = module.eks.cluster_certificate_authority_data

  namespace                 = var.monitoring_namespace
  grafana_admin_password    = var.grafana_admin_password
  prometheus_retention_days = var.prometheus_retention_days
  prometheus_storage_size   = var.prometheus_storage_size
  grafana_storage_size      = var.grafana_storage_size

  depends_on = [module.eks]
}
