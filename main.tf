terraform {
  required_version = ">= 1.1.0"
  required_providers {
    aws = {
      version = ">= 2.28.1"
    }
    kubernetes = {
      version = "~> 2.11"
    }
    random = {
      version = "~> 3.1"
    }
    local = {
      version = "~> 2"
    }
  }
}

provider "aws" {
  # ... other configuration ...
  default_tags {
    tags = {
      Name          = local.cluster_name
      Environment   = var.environment
      Owner         = var.owner
      App           = "humio"
      DeployVersion = "0.1.0"
      ManagedBy     = "Terraform"
    }
  }
}
data "aws_caller_identity" "current" {}
data "aws_organizations_organization" "current" {}


locals {
  cluster_name = "${var.deployment_name}-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 4
  special = false
  lower   = true
  upper   = false
  number  = false
}
