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


# variable "humio_instance_count" {
#   type    = number
#   default = 3
# }


# variable "humio_data_dir" {
#   type    = string
#   default = "/mnt/disks/vol1"
# }
# variable "humio_data_dir_owner_uuid" {
#   type    = number
#   default = 65534
# }
# variable "user_data_script" {
#   type    = string
#   default = "user-data-vg.sh"
# }
