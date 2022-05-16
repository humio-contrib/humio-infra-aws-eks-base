data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = var.domain_is_private
}

module "iam_assumable_role_edns" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "4.24.0"
  create_role                   = true
  role_name                     = "${local.cluster_name}-edns"
  provider_url                  = replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")
  role_policy_arns              = [aws_iam_policy.alb.arn, aws_iam_policy.edns.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:external-dns:external-dns"]
}


resource "aws_iam_policy" "edns" {
  name        = "${local.cluster_name}-edns"
  description = "Allow configuration of ingress"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": [
        "${data.aws_route53_zone.selected.arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}


resource "helm_release" "edns" {
  depends_on = [
    module.iam_assumable_role_edns,
  ]

  name             = "external-dns"
  namespace        = "external-dns"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "external-dns"
  version          = "6.3.0"
  create_namespace = true

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
    value = module.iam_assumable_role_edns.iam_role_arn
    type  = "string"
  }
}

