data "aws_availability_zones" "available" {
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.14.0"

  name = var.name
  cidr = "10.0.0.0/16"

  azs                    = data.aws_availability_zones.available.names
  private_subnets        = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]
  public_subnets         = ["10.0.48.0/20", "10.0.64.0/20", "10.0.80.0/20"]
  enable_nat_gateway     = true
  single_nat_gateway     = true
  enable_dns_hostnames   = true
  one_nat_gateway_per_az = false

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.name}" = "shared"
    "kubernetes.io/role/elb"            = "1"
    "karpenter.sh/discovery"            = var.name
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.name}" = "shared"
    "kubernetes.io/role/internal-elb"   = "1"
    "karpenter.sh/discovery"            = var.name
  }

  tags = var.tags
}
