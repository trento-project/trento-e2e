variable "deployment_name" {
  description = "Suffix string added to some of the infrastructure resources names. If it is not provided, the terraform workspace string is used as suffix"
  type        = string
}

variable "image_id" {
  description = "Trento server machine os image"
  type        = string
}

variable "instance_type" {
  type    = string
  default = "t2.large"
}

variable "key_name" {
  description = "AWS key pair name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet id"
  type        = string
}

variable "security_group_id" {
  description = "Security group id"
  type        = string
}

variable "availability_zone" {
  description = "Used availability zone"
  type        = string
}

variable "host_ip" {
  description = "Trento server internal ip"
  type        = string
}