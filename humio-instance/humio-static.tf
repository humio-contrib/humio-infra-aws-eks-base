resource "kubernetes_secret" "license" {
  metadata {
    name      = "${var.humio_instance}-license"
    namespace = kubernetes_namespace.humio.metadata[0].name
  }

  data = {
    data = var.humio_license
  }

  type = "Opaque"
}

resource "kubernetes_secret" "humio_bucket_client_key" {
  metadata {
    name      = "${var.humio_instance}-bucket-key"
    namespace = kubernetes_namespace.humio.metadata[0].name
  }

  data = {
    encryption-key = var.humio_bucket_client_key
  }

  type = "Opaque"
}


resource "kubernetes_secret" "humio_idp_cert" {
  metadata {
    name      = "${var.humio_instance}-idp-certificate"
    namespace = kubernetes_namespace.humio.metadata[0].name
  }

  data = {
    "idp-certificate.pem" = var.sso_saml_idp_cert
  }

  type = "Opaque"
}
