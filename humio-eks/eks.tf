module "vpc_cni_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "${var.name}-vpc-cni-controller"


  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }
  tags = var.tags
}

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = var.tags
}

module "eks" {
  source                          = "terraform-aws-modules/eks/aws"
  version                         = "<19.0"
  cluster_name                    = var.name
  cluster_version                 = var.k8s_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id                                 = module.vpc.vpc_id
  subnet_ids                             = module.vpc.private_subnets
  cloudwatch_log_group_retention_in_days = 7
  cluster_enabled_log_types              = ["audit", "api", "authenticator", "controllerManager", "scheduler"]

  cluster_encryption_config = [{
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }]


  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.vpc_cni_irsa_role.iam_role_arn
    }
    # aws-ebs-csi-driver = {
    #   resolve_conflicts        = "OVERWRITE"
    #   service_account_role_arn = module.vpc_cni_irsa_role.iam_role_arn
    # }
  
  }
  
  manage_aws_auth_configmap = true
  aws_auth_users = [
    {
      userarn  = data.aws_caller_identity.current.arn
      username = "admin-caller"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      username = "admin-aws-root"
      groups   = ["system:masters"]
    },
    {
      userarn  = var.aws_admin_arn
      username = "admin-user-role"
      groups   = ["system:masters"]
    },
  ]
  aws_auth_accounts = [
    data.aws_caller_identity.current.account_id
  ]
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

  node_security_group_additional_rules = {
    # Control plane invoke Karpenter webhook
    ingress_karpenter_webhook_tcp = {
      description                   = "Control plane invoke Karpenter webhook"
      protocol                      = "tcp"
      from_port                     = 8443
      to_port                       = 8443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_allow_access_from_control_plane = {
      type                          = "ingress"
      protocol                      = "tcp"
      from_port                     = 9443
      to_port                       = 9443
      source_cluster_security_group = true
      description                   = "Allow access from control plane to webhook port of AWS load balancer controller"
    }
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  eks_managed_node_groups = {
    karpenter = {
      instance_types = var.eks_general_instance_type

      min_size     = var.eks_general_min_size
      max_size     = var.eks_general_max_size
      desired_size = var.eks_general_desired_size

      labels = var.tags
      iam_role_additional_policies = [
        # Required by Karpenter
        "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
      ]
    }
  }

  tags                                       = var.tags
  create_cluster_primary_security_group_tags = false
  node_security_group_tags = {
    "karpenter.sh/discovery" = var.name
    "aws-alb"                = true
  }
}
