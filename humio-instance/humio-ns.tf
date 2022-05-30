resource "kubernetes_namespace" "humio" {
  metadata {
    name = var.humio_namespace
  }
}
