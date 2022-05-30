resource "kubernetes_namespace" "edns" {
  metadata {
    name = "external-dns"
  }
}

data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = var.domain_is_private
}

module "external_dns_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "${var.name}-external-dns-controller"


  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = [data.aws_route53_zone.selected.arn]

  oidc_providers = {
    main = {
      provider_arn               = var.cluster_provider_arn
      namespace_service_accounts = ["${kubernetes_namespace.edns.metadata[0].name}:external-dns"]
    }
  }
  tags = var.tags
}

resource "helm_release" "edns" {

  name             = "external-dns"
  namespace        = kubernetes_namespace.edns.metadata[0].name
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "external-dns"
  version          = "6.4.0"
  create_namespace = false

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
    value = var.name
    type  = "string"
  }
}

