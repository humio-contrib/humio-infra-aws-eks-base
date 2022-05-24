
module "aws_ebs" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 4.21.1"

  role_name             = "${local.name}-aws-ebs"
  attach_ebs_csi_policy = true


  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
  tags = local.tags
}
resource "helm_release" "ebs-controller" {

  name             = "aws-ebs-csi-driver"
  namespace        = "kube-system"
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
tolerations:
#Any tolerations used to control pod deployment should be here
- key: "humio.com/reservednode"
  operator: "Exists"
  effect: "NoSchedule"
EOF 
  ]

  set {
    name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.aws_ebs.iam_role_arn
    type  = "string"
  }
}

# resource "kubectl_manifest" "aws_ebs_gp3" {

#   yaml_body = <<-YAML
# apiVersion: storage.k8s.io/v1
# kind: StorageClass
# metadata:
#   annotations:
#     storageclass.kubernetes.io/is-default-class: "true"
#   name: gp3
# parameters:
#   csi.storage.k8s.io/fstype: xfs
#   type: gp3
# provisioner: ebs.csi.aws.com
# reclaimPolicy: Delete
# #volumeBindingMode: WaitForFirstConsumer  
# YAML
# }
