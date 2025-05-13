variable "deployment_name" {
  description = "Suffix string added to some of the infrastructure resources names. If it is not provided, the terraform workspace string is used as suffix"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "AWS region where the deployment machines will be created. If not provided the current configured region will be used"
  type        = string
}

variable "aws_access_key_id" {
  description = "AWS access key id"
  type        = string
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
}

variable "vpc_address_range" {
  description = "vpc address range in CIDR notation"
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition = (
      can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.vpc_address_range))
    )
    error_message = "Invalid IP range format. It must be something like: 102.168.10.5/24 ."
  }
}

variable "public_key" {
  description = "Content of a SSH public key or path to an already existing SSH public key. The key is only used to provision the machines and it is authorized for future accesses"
  type        = string
}

variable "instance_type" {
  type    = string
  default = "r3.8xlarge"
}

variable "license_email" {
  description = "SLES4SAP license email"
  type        = string
}

variable "machines" {
  description = "List of machines to be created. Each machine is a map with the following keys: image_id, private_ip, version_slug, init_script"
  type = list(object({
    name         = string
    image_id     = string
    sles_version = string
    license_key  = string
  }))
  default = []
}