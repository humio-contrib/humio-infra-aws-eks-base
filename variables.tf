variable "deployment_name" {
  type    = string
  default = "humio"
}

variable "humio_instance_type" {
  type    = string
  default = "i3.large" # Instance should have local NVME
}

variable "humio_data_dir" {
  type    = string
  default = "/mnt/disks/vol1"
}
variable "humio_data_dir_owner_uuid" {
  type    = number
  default = 65534
}
variable "user_data_script" {
  type    = string
  default = "user-data.sh.tmpl"
}
variable "environment" {
  type    = string
  default = "Production"
}
variable "department" {
  type    = string
  default = "humio"
}
