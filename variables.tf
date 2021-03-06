variable "region" {
  type    = string
  default = "us-east-1"
}
variable "environment" {
  type    = string
  default = "Production"
}
variable "department" {
  type    = string
  default = "humio"
}


variable "domain_name" {
  type = string
}
variable "domain_is_private" {
  type    = bool
  default = false
}

variable "humio_namespace" {
  type    = string
  default = "humio"
}
variable "humio_instance" {
  type    = string
  default = "humio"
}

variable "humio_bucket_client_key" {
  type    = string
  default = "D3BeRhYCexFPt0Q5Uceb49paCpjz2p1KSFNXEX/DgP4Jz2uPpXSl54qXnBUnsKhIsRUCGNDoambpgK7Yoh26pg=="
}

variable "humio_license" {
  type      = string
  sensitive = true
}

variable "sso_saml_idp_cert" {
  type = string
}

variable "sso_saml_sign_on_url" {
  type = string
}

variable "sso_saml_entity_id" {
  type = string
}
