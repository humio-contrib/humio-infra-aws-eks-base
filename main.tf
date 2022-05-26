

provider "aws" {

}
data "aws_caller_identity" "current" {}
data "aws_organizations_organization" "current" {}
data "aws_partition" "current" {}


provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = "false"
}


provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}



resource "random_string" "suffix" {
  length  = 4
  special = false
  lower   = true
  upper   = false
  number  = false
}

locals {
  name            = var.deployment_name != "" ? "${var.deployment_name}-${random_string.suffix.result}" : "humio-${(replace(replace(basename(path.cwd), "_", "-"), " ", ""))}"
  cluster_version = "1.22"
  partition       = data.aws_partition.current.partition

  tags = {
    Instance    = local.name
    GithubRepo  = "humio-infra-aws-eks-base"
    GithubOrg   = "humio-contrib"
    App         = "humio"
    Environment = var.environment
    Department  = var.department
  }
}

