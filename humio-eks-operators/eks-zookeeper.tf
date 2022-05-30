resource "kubernetes_namespace" "zookeeper" {
  depends_on = [
    module.aws_ebs
  ]
  metadata {
    name = "zookeeper-operator"
  }
}

resource "helm_release" "zookeeper" {
  depends_on = [
    kubernetes_namespace.zookeeper,
    module.aws_ebs
  ]
  name             = "zookeeper-operator"
  namespace        = kubernetes_namespace.zookeeper.metadata[0].name
  repository       = "https://charts.pravega.io"
  chart            = "zookeeper-operator"
  version          = "0.2.14"
  create_namespace = false

  values = [<<EOF
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
EOF 
  ]
  set {
    name  = "crd.create"
    value = true
  }

}

