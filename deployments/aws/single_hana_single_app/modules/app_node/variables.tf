variable "deployment_name" {
  description = "Suffix string added to some of the infrastructure resources names. If it is not provided, the terraform workspace string is used as suffix"
  type        = string
}

variable "aws_region" {
  description = "AWS region where the deployment machines will be created. If not provided the current configured region will be used"
  type = string
}

variable "name" {
  description = "hostname, without the domain part"
  type        = string
  default     = "vmnetweaver"
}

variable "instance_type" {
  type    = string
  default = "r5.large"
}

variable "availability_zone" {
  description = "Used availability zones"
  type        = string
} 

variable "vpc_id" {
  description = "Id of the vpc used for this deployment"
  type        = string
}

variable "subnet_address_range" {
  description = "Subnet address ranges in cidr notation"
  type        = string
}
  
variable "key_name" {
  description = "AWS key pair name"
  type        = string
}

variable "security_group_id" {
  description = "Security group id"
  type        = string
}

variable "route_table_id" {
  description = "Private route table id"
  type        = string
}

variable "host_ip" {
  description = "ip address to set to the node. The ip must be in 10.0.2.0/24 subnet"
  type        = string
}

variable "image_id" {
  description = "APP AMI image that is used to create the machine"
  type        = string
}

variable "efs_performance_mode" {
  type        = string
  description = "Performance mode of the EFS storage used by the App"
  default     = "generalPurpose"
}
