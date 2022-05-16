
resource "helm_release" "humio-operator" {

  name             = "humio-operator"
  namespace        = "humio-operator"
  repository       = "https://humio.github.io/humio-operator"
  chart            = "humio-operator"
  version          = "0.14.2"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}
