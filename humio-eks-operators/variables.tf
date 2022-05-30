
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
