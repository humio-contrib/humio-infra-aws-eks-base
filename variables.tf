variable "deployment_name" {
  type    = string
  default = "humio"
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
