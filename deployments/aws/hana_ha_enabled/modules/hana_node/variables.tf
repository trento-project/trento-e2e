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
  default     = "vmhana"
}

variable "instance_type" {
  type    = string
  default = "r3.8xlarge"
}

variable "availability_zones" {
  description = "Used availability zones"
  type        = list(string)
} 

variable "vpc_id" {
  description = "Id of the vpc used for this deployment"
  type        = string
}

variable "subnet_address_ranges" {
  description = "List with subnet address ranges in cidr notation to create the netweaver subnets"
  type        = list(string)
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
  description = "Pirvate route table id"
  type        = string
}

variable "host_ips" {
  description = "ip addresses to set to the nodes. The first ip must be in 10.0.0.0/24 subnet and the second in 10.0.1.0/24 subnet"
  type        = list(string)
}

variable "image_ids" {
  description = "List of HANA AMI images that are used to create the machines"
  type        = list(string)
}

variable "block_devices" {
  description = "List of devices that will be available to attach as an ebs volume."
  type        = string
}

variable "hana_data_disks_configuration" {
  type        = map(any)
  default     = {}
  description = <<EOF
    This map describes how the disks will be formatted to create the definitive configuration during the provisioning.

    disks_type and disks_size are used during the disks creation. The number of elements must match in all of them
    "," is used to separate each disk.

    disk_type = The disk type used to create disks. See https://aws.amazon.com/ebs/volume-types/ and https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume for reference.
    disk_size = The disk size in GB.

    luns, names, lv_sizes and paths are used during the provisioning to create/format/mount logical volumes and filesystems.
    "#" character is used to split the volume groups, while "," is used to define the logical volumes for each group
    The number of groups split by "#" must match in all of the entries.

    luns  -> The luns or disks used for each volume group. The number of luns must match with the configured in the previous disks variables (example 0,1#2,3#4#5#6)
    names -> The names of the volume groups and logical volumes (example data#log#shared#usrsap#backup)
    lv_sizes -> The size in % (from available space) dedicated for each logical volume and folder (example 50#50#100#100#100)
    paths -> Folder where each volume group will be mounted (example /hana/data,/hana/log#/hana/shared#/usr/sap#/hana/backup#/sapmnt/)
  EOF
}

variable "hana_virtual_ip" {
  description = "HANA cluster virtual ip address"
  type        = string
  default     = "192.168.1.10"
}
