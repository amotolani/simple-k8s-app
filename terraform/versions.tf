terraform {
  required_providers {
    aws = {
      version = "5.39.1"
      source  = "hashicorp/aws"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.12.1"
    }
    kubernetes = {
      version = "2.21.1"
      source  = "hashicorp/kubernetes"
    }
  }
  required_version = ">= 1.2.3"

  
}

