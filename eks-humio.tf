
resource "helm_release" "humio-operator" {
  depends_on = [
    module.eks
  ]

  name             = "humio-operator"
  namespace        = "humio-operator"
  repository       = "https://humio.github.io/humio-operator"
  chart            = "humio-operator"
  version          = "0.14.2"
  create_namespace = true

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
    name  = "installCRDs"
    value = "true"
  }
}
