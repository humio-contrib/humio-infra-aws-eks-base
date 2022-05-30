variable "tags" {
  type = map(string)
}

variable "name" {
  type = string
}

variable "k8s_version" {
  type    = string
  default = "1.22"
}

variable "aws_admin_arn" {
  type = string
}

variable "eks_general_instance_type" {
  type    = list
  default = ["c6i.xlarge"]
}

variable "eks_general_min_size" {
    type = number
    default = 2  
}
variable "eks_general_max_size" {
    type = number
    default = 5  
}
variable "eks_general_desired_size" {
    type = number
    default = 3  
}