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

variable "trento_server_image_id" {
  description = "Trento server os image. Run to get the ami id: aws ec2 describe-images --owners 679593333241 --filters \"Name=name,Values=suse-sles-sap-15-spx*\""
  type        = string
  default     = ""
}

variable "trento_server_ip" {
  description = "Trento server internal ip address"
  type        = string
  default     = ""
}

variable "hana_image_ids" {
  description = "List of HANA AMI images that are used to create the machines"
  type        = list(string)
}

variable "hana_instancetype" {
  description = "The instance type of the hana nodes"
  type        = string
  default     = "r5b.xlarge"
}

variable "hana_ips" {
  description = "List of ip addresses to give to the hana nodes"
  type        = list(string)
  default     = []
}

variable "block_devices" {
  description = "List of devices that will be available to attach as an ebs volume. These values are mapped later between the values in terraform and in the operating system (see e.g. hana_data_disks_configuration['devices']."
  type        = string
  default     = "/dev/sdf,/dev/sdg,/dev/sdh,/dev/sdi,/dev/sdj,/dev/sdk,/dev/sdl,/dev/sdm,/dev/sdn,/dev/sdo,/dev/sdp,/dev/sdq,/dev/sdr,/dev/sds,/dev/sdt,/dev/sdu,/dev/sdv,/dev/sdw,/dev/sdx,/dev/sdy,/dev/sdz"
}

variable "hana_data_disks_configuration" {
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
  type = map(any)
  default = {
    disks_type = "gp2,gp2,gp2,gp2,gp2,gp2,gp2"
    disks_size = "128,128,128,128,64,64,128"
    # The next variables are used during the provisioning
    luns     = "0,1#2,3#4#5#6"
    names    = "data#log#shared#usrsap#backup"
    lv_sizes = "100#100#100#100#100"
    paths    = "/hana/data#/hana/log#/hana/shared#/usr/sap#/hana/backup"
  }
  
}



