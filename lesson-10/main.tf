# Main Terraform configuration for lesson-10
# Universal infrastructure with RDS/Aurora database support

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

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "lesson-10"
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

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  default     = "ChangeMe123!"
  sensitive   = true
}

# S3 Backend Module
module "s3_backend" {
  source = "./modules/s3-backend"
  
  bucket_name        = "dina-bucket-1"
  dynamodb_table_name = "terraform-state-lock"
  aws_region         = var.aws_region
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  project_name         = var.project_name
  vpc_cidr            = "10.0.0.0/16"
  availability_zones  = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
}

# ECR Module
module "ecr" {
  source = "./modules/ecr"
  
  repository_name = "dina_django_project_web"
}

# EKS Module
module "eks" {
  source = "./modules/eks"
  
  cluster_name    = "${var.project_name}-eks"
  cluster_version = "1.28"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  
  node_group_name     = "${var.project_name}-nodes"
  node_instance_types = ["t3.small"]
  node_desired_size   = 2
  node_min_size       = 1
  node_max_size       = 4
}

# RDS Module - Regular RDS Instance
module "rds" {
  source = "./modules/rds"
  
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnet_ids
  
  # Database configuration
  use_aurora       = false  # Set to true for Aurora
  engine           = "postgres"
  engine_version   = "15.4"
  instance_class   = "db.t3.micro"
  allocated_storage = 20
  
  # Credentials
  db_username = var.db_username
  db_password = var.db_password
  
  # High availability
  multi_az = false
  
  # Allow access from EKS nodes
  allowed_cidr_blocks = module.vpc.private_subnet_cidrs
  
  # Parameter group settings
  parameters = {
    max_connections = "100"
    log_statement   = "all"
    work_mem        = "4096"
  }
  
  depends_on = [module.vpc]
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
  ecr_repository_url     = module.ecr.repository_url
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
  chart_path          = "lesson-10/charts/django-app"
  app_namespace       = "default"
  
  # Pass database connection details to Django app
  db_host     = module.rds.db_endpoint
  db_port     = module.rds.db_port
  db_name     = module.rds.db_name
  db_username = var.db_username
  db_password = var.db_password
  
  depends_on = [module.eks, module.jenkins, module.rds]
}
