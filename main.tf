provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = module.humio-eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.humio-eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.humio-eks.cluster_id]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.humio-eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.humio-eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.humio-eks.cluster_id]
    }
  }
}

provider "kubectl" {
  apply_retry_count      = 10
  host                   = module.humio-eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.humio-eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.humio-eks.cluster_id]
  }
}

resource "random_string" "suffix" {
  length  = 4
  special = false
  lower   = true
  upper   = false
  number  = false
}

data "aws_caller_identity" "current" {}
data "aws_organizations_organization" "current" {}
data "aws_partition" "current" {}




locals {
  name            = var.humio_instance != "" ? "${var.humio_instance}-${random_string.suffix.result}" : "humio-${(replace(replace(basename(path.cwd), "_", "-"), " ", ""))}"
  cluster_version = "1.22"

  tags = {
    Instance    = local.name
    GithubRepo  = "humio-infra-aws-eks-base"
    GithubOrg   = "humio-contrib"
    App         = "humio"
    Environment = var.environment
    Department  = var.department
  }
}


module "humio-eks" {
  source = "./humio-eks"

  name = local.name
  tags = local.tags

  aws_admin_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/cs-mb"
}

module "humio-eks-operators" {
  depends_on = [
    module.humio-eks
  ]
  source = "./humio-eks-operators"

  name = local.name
  tags = local.tags

  cluster_id                         = module.humio-eks.cluster_id
  cluster_endpoint                   = module.humio-eks.cluster_endpoint
  cluster_certificate_authority_data = module.humio-eks.cluster_certificate_authority_data
  cluster_provider_arn               = module.humio-eks.cluster_provider_arn

  domain_name       = var.domain_name
  domain_is_private = var.domain_is_private
}

module "humio-instance" {
  source = "./humio-instance"
  depends_on = [
    module.humio-eks-operators
  ]

  region = var.region
  name   = local.name
  tags   = local.tags

  cluster_id                         = module.humio-eks.cluster_id
  cluster_endpoint                   = module.humio-eks.cluster_endpoint
  cluster_certificate_authority_data = module.humio-eks.cluster_certificate_authority_data
  cluster_provider_arn               = module.humio-eks.cluster_provider_arn

  domain_name       = var.domain_name
  domain_is_private = var.domain_is_private
  humio_instance    = var.humio_instance
  humio_namespace   = var.humio_namespace

  humio_logs_bucket_id    = module.humio-eks.logs_bucket
  humio_bucket_client_key = var.humio_bucket_client_key
  humio_license           = var.humio_license

  sso_saml_idp_cert    = var.sso_saml_idp_cert
  sso_saml_sign_on_url = var.sso_saml_sign_on_url
  sso_saml_entity_id   = var.sso_saml_entity_id
}
