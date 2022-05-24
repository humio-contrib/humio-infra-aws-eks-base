module "alb_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "${local.name}-aws-alb-controller"


  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["alb-manager:aws-load-balancer-controller"]
    }
  }
  tags = local.tags
}


resource "helm_release" "alb" {
  depends_on = [
    helm_release.cert-manager
  ]
  name             = "aws-load-balancer-controller"
  namespace        = "alb-manager"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  version          = "1.4.1"
  create_namespace = true

  values = [<<EOF
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
EOF 
  ]

  set {
    name  = "clusterName"
    value = local.name
  }
  set {
    name  = "enableCertManager"
    value = true
  }
  set {
    name  = "podDisruptionBudget.maxUnavailable"
    value = 1
  }
  set {
    name  = "rbac.serviceAccount.create"
    value = "true"
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.alb_role.iam_role_arn
    type  = "string"
  }
  #   set {
  #     name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/sts-regional-endpoints"
  #     value  = "true"
  #   }
}
