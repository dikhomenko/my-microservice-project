# Main Terraform configuration for lesson-7 (EKS + ECR + Helm)
# Reuses VPC from lesson-5 and adds EKS cluster

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# Data sources to get lesson-5 VPC and ECR resources
data "terraform_remote_state" "lesson5" {
  backend = "s3"
  config = {
    bucket = "dina-bucket-1"
    key    = "lesson-5/terraform.tfstate"
    region = "us-west-2"
  }
}

# EKS Module
module "eks" {
  source = "./modules/eks"
  
  cluster_name    = "lesson-7-eks"
  cluster_version = "1.28"
  
  # Use VPC and subnets from lesson-5
  vpc_id          = data.terraform_remote_state.lesson5.outputs.vpc_id
  subnet_ids      = data.terraform_remote_state.lesson5.outputs.private_subnet_ids
  
  # Node group configuration
  node_group_name         = "lesson-7-nodes"
  node_instance_types     = ["t3.small"]
  node_desired_size       = 2
  node_min_size          = 1
  node_max_size          = 4
}

# Use ECR from lesson-5
locals {
  ecr_repository_url = data.terraform_remote_state.lesson5.outputs.ecr_repository_url
}