terraform {
  required_version = ">= 1.0.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.3.2"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.1.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.1.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "3.45.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.2.0"
    }
  }
}

provider "kubernetes" {
  config_path = var.path_kubeconfig
  insecure    = var.insecure_kubeconfig
}

provider "helm" {
  kubernetes {
    config_path = var.path_kubeconfig
  }
}

provider "aws" {
  region                  = var.aws_region
  shared_credentials_file = var.aws_shared_credentials_file_path
  profile                 = var.aws_profile
}
