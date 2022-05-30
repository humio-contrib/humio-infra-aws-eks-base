


data "aws_caller_identity" "current" {}
data "aws_organizations_organization" "current" {}
data "aws_partition" "current" {}
data "aws_eks_cluster" "eks" {
  name = var.cluster_id
}
