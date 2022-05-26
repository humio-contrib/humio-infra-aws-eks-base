resource "helm_release" "zk" {
  depends_on = [
    module.eks
  ]

  name             = "zookeeper-operator"
  namespace        = "zookeeper-operator"
  repository       = "https://charts.pravega.io"
  chart            = "zookeeper-operator"
  version          = "0.2.14"
  create_namespace = true

  values = [<<EOF
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
EOF 
  ]

}

