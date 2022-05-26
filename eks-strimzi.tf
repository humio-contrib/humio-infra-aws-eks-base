resource "helm_release" "strimzi" {

  name             = "strimzi-kafka-operator"
  namespace        = "strimzi-operator"
  repository       = "https://strimzi.io/charts/"
  chart            = "strimzi-kafka-operator"
  version          = "0.29.0"
  create_namespace = true

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

