variable "deployment_name" {
  description = "Suffix string added to some of the infrastructure resources names. If it is not provided, the terraform workspace string is used as suffix"
  type        = string
}

variable "name" {
  type        = string
  description = "Name used to create the role and policies. It will be attached after the workspace"
}

variable "aws_region" {
  type = string
}

variable "cluster_instances" {
  type        = list(string)
  description = "Instances that will be attached to the role"
}

variable "route_table_id" {
  type        = string
  description = "Route table id"
}
