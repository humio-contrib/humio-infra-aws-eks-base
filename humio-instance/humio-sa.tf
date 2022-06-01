module "iam_assumable_role_humio" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.0.0"
  create_role                   = true
  role_name                     = "${var.cluster_id}-humio"
  provider_url                  = replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")
  role_policy_arns              = [aws_iam_policy.cluster.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${var.humio_namespace}:humio-${var.humio_instance}"]
}

resource "aws_iam_policy" "cluster" {
  name        = var.cluster_id
  description = "EKS humio policy for cluster"
  policy      = data.aws_iam_policy_document.bucket_policy.json
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.humio.id}",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.humio.id}/*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      aws_kms_key.humio.arn
    ]

  }
}
