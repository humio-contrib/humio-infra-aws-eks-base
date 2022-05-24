data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = var.domain_is_private
}

module "external_dns_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "${local.name}-external-dns-controller"


  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = [data.aws_route53_zone.selected.arn]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-dns:external-dns"]
    }
  }
  tags = local.tags
}

resource "helm_release" "edns" {

  name             = "external-dns"
  namespace        = "external-dns"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "external-dns"
  version          = "6.4.0"
  create_namespace = true

  values = [<<EOF
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
EOF 
  ]

  set {
    name  = "replicaCount"
    value = 2
  }
  set {
    name  = "serviceAccount.create"
    value = "true"
  }
  set {
    name  = "serviceAccount.name"
    value = "external-dns"
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.external_dns_role.iam_role_arn
    type  = "string"
  }
  set {
    name  = "txtOwnerId"
    value = local.name
    type  = "string"
  }
}

