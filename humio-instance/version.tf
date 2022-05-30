terraform {
  required_version = ">= 1.1.0"
  required_providers {
    aws = {
      version = ">= 2.28.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
    kubernetes = {
      version = "~> 2.11"
    }
    local = {
      version = "~> 2"
    }
  }
}
