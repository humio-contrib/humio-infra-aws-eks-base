
resource "helm_release" "cert-manager" {

  name             = "cert-manager"
  namespace        = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "1.8.0"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}
