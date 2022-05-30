variable "region" {
  type=string
}
variable "name" {
  type = string
}
variable "tags" {
  type = map(string)
}
variable "cluster_id" {
  type = string
}
variable "cluster_endpoint" {
  type = string
}
variable "cluster_certificate_authority_data" {
  type = string
}

variable "cluster_provider_arn" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "domain_is_private" {
  type = bool
}

variable "humio_namespace" {
  type = string
}
variable "humio_instance" {
  type = string
}

variable "humio_logs_bucket_id" {
  type = string
}

variable "humio_bucket_client_key" {
  type = string
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
