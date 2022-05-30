resource "kubernetes_namespace" "strimzi" {
  metadata {
    name = "strimzi-kafka-operator"
  }
}
resource "helm_release" "strimzi" {
  depends_on = [
    module.aws_ebs
  ]
  name             = "strimzi-kafka-operator"
  namespace        = kubernetes_namespace.strimzi.metadata[0].name
  repository       = "https://strimzi.io/charts/"
  chart            = "strimzi-kafka-operator"
  version          = "0.29.0"
  create_namespace = false

  values = [<<EOF
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
EOF 
  ]
  set {
    name  = "watchAnyNamespace"
    value = true
  }
}

