resource "kubernetes_namespace" "awsebs" {
  metadata {
    name = "awsebs-controller"
  }
}


module "aws_ebs" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 4.21.1"

  role_name             = "${var.name}-aws-ebs"
  attach_ebs_csi_policy = true


  oidc_providers = {
    ex = {
      provider_arn               = var.cluster_provider_arn
      namespace_service_accounts = ["${kubernetes_namespace.awsebs.metadata[0].name}:ebs-csi-controller-sa"]
    }
  }
  tags = var.tags
}
resource "helm_release" "ebs-controller" {

  name             = "aws-ebs-csi-driver"
  namespace        = kubernetes_namespace.awsebs.metadata[0].name
  repository       = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart            = "aws-ebs-csi-driver"
  version          = "2.6.8"
  create_namespace = false

  values = [<<EOF
controller:
    topologySpreadConstraints:
    - maxSkew: 1
      topologyKey: topology.kubernetes.io/zone
      whenUnsatisfiable: DoNotSchedule
storageClasses: 
- name: ebs-gp3-enc
  volumeBindingMode: WaitForFirstConsumer
  reclaimPolicy: Delete
  parameters:
    encrypted: "true"    
- name: ebs-gp3-noenc
  volumeBindingMode: WaitForFirstConsumer
  reclaimPolicy: Delete
  parameters:
    encrypted: "false"
node:
    tolerations:
    #Any tolerations used to control pod deployment should be here
    - operator: "Exists"
EOF 
  ]

  set {
    name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.aws_ebs.iam_role_arn
    type  = "string"
  }
}
