# Main Terraform configuration for Web3 Node Platform
# This creates an EKS cluster optimized for blockchain workloads

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }

  # Recommended: use S3 backend for state storage
  # Uncomment and configure for production
  # backend "s3" {
  #   bucket         = "web3-node-terraform-state"
  #   key            = "eks/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

# Data sources
data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.main.name
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}
