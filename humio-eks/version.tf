terraform {
  required_version = ">= 1.1.0"
  required_providers {
    aws = {
      version = ">= 2.28.1"
    }
    kubernetes = {
      version = "~> 2.11"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
  }
}
