resource "kubernetes_namespace" "karpenter" {
  depends_on = [
    module.eks
  ]
  metadata {
    name = "karpenter"
  }
}


module "karpenter_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0.0"

  role_name                          = "${var.name}-karpenter-controller"
  attach_karpenter_controller_policy = true

  karpenter_controller_cluster_id = module.eks.cluster_id
  karpenter_controller_node_iam_role_arns = [
    module.eks.eks_managed_node_groups["karpenter"].iam_role_arn
  ]

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${kubernetes_namespace.karpenter.metadata[0].name}:karpenter"]
    }
  }
  tags = var.tags

}


resource "aws_iam_instance_profile" "karpenter" {
  name = "KarpenterNodeInstanceProfile-${var.name}"
  role = module.eks.eks_managed_node_groups["karpenter"].iam_role_name
}

resource "helm_release" "karpenter" {
  namespace        = kubernetes_namespace.karpenter.metadata[0].name
  create_namespace = false

  name       = "karpenter"
  repository = "https://charts.karpenter.sh"
  chart      = "karpenter"
  version    = "0.10.1"

  values = [<<EOF
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
EOF 
  ]
  set {
    name  = "replicas"
    value = 2
  }


  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter_irsa.iam_role_arn
  }

  set {
    name  = "clusterName"
    value = module.eks.cluster_id
  }

  set {
    name  = "clusterEndpoint"
    value = module.eks.cluster_endpoint
  }

  set {
    name  = "aws.defaultInstanceProfile"
    value = aws_iam_instance_profile.karpenter.name
  }
}


# Workaround - https://github.com/hashicorp/terraform-provider-kubernetes/issues/1380#issuecomment-967022975
resource "kubectl_manifest" "karpenter_provisioner_general" {
  depends_on = [
    helm_release.karpenter
  ]
  yaml_body = <<-YAML
  apiVersion: karpenter.sh/v1alpha5
  kind: Provisioner
  metadata:
    name: default
    namespace: ${kubernetes_namespace.karpenter.metadata[0].name}
  spec:
    requirements:
      - key: karpenter.sh/capacity-type
        operator: In
        values: ["spot", "on-demand"]
      - key: node.kubernetes.io/instance-type
        operator: In
        values: 
        # - m6i.large
        - m6i.xlarge
        # - m6a.large
        - m6a.xlarge
        # - m5.large
        - m5.xlarge
        # - m5a.large
        - m5a.xlarge
        # - m5n.large
        - m5n.xlarge
        # - m5zn.large
        - m5zn.xlarge
        # - m4.large
        - m4.xlarge



    limits:
      resources:
        cpu: 1000
    provider:
      subnetSelector:
        karpenter.sh/discovery: ${var.name}
      securityGroupSelector:
        karpenter.sh/discovery: ${var.name}
      tags:
        karpenter.sh/discovery: ${var.name}
    ttlSecondsAfterEmpty: 30
  YAML

}


# Workaround - https://github.com/hashicorp/terraform-provider-kubernetes/issues/1380#issuecomment-967022975
resource "kubectl_manifest" "karpenter_provisioner_humio" {
  depends_on = [
    helm_release.karpenter
  ]

  yaml_body = <<-YAML
  apiVersion: karpenter.sh/v1alpha5
  kind: Provisioner
  metadata:
    name: humio
    namespace: karpenter
  spec:
    labels:
        beta.humio.com/humiocluster: "true"
        beta.humio.com/instance-storage: "true"
    requirements:
      - key: karpenter.sh/capacity-type
        operator: In
        values: ["spot", "on-demand"]
      - key: node.kubernetes.io/instance-type
        operator: In
        values: 
            - c5d.large
            
    taints:
        - key: beta.humio.com/humiocluster
          value: "true"
          effect: NoSchedule        
        - key: beta.humio.com/instance-storage
          value: "true"
          effect: NoSchedule        
    limits:
      resources:
        cpu: 32
    provider:
      subnetSelector:
        karpenter.sh/discovery: ${module.eks.cluster_id}
      securityGroupSelector:
        karpenter.sh/discovery: ${module.eks.cluster_id}
      tags:
        karpenter.sh/discovery: ${module.eks.cluster_id}
    ttlSecondsAfterEmpty: 180
  YAML

}
