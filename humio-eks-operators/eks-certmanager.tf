resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}


module "cert_manager_role" {

  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "${var.name}-cert-manager-controller"


  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = [data.aws_route53_zone.selected.arn]

  oidc_providers = {
    main = {
      provider_arn               = var.cluster_provider_arn
      namespace_service_accounts = ["${kubernetes_namespace.cert_manager.metadata[0].name}:cert-manager"]
    }
  }
  tags = var.tags
}

resource "helm_release" "cert-manager" {

  name             = "cert-manager"
  namespace        = kubernetes_namespace.cert_manager.metadata[0].name
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "1.8.0"
  create_namespace = false

  values = [<<EOF
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
EOF 
  ]

  set {
    name  = "installCRDs"
    value = "true"
  }
  set {
    name  = "replicaCount"
    value = 2
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.cert_manager_role.iam_role_arn
    type  = "string"
  }
  set {
    name  = "webhook.replicaCount"
    value = 2
  }
  set {
    name  = "cainjector.replicaCount"
    value = 2
  }
}
