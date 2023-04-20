locals {
  disks_number = length(split(",", var.hana_data_disks_configuration["disks_size"]))
  disks_name   = [for disk_name in split(",", var.block_devices) : trimspace(disk_name)]
  disks_size   = [for disk_size in split(",", var.hana_data_disks_configuration["disks_size"]) : tonumber(trimspace(disk_size))]
  disks_type   = [for disk_type in split(",", var.hana_data_disks_configuration["disks_type"]) : trimspace(disk_type)]
  disks = flatten([
    for disk in range(local.disks_number) : {
      node        = "${var.name}"
      disk_number = disk
      disk_name   = element(local.disks_name, disk)
      disk_size   = element(local.disks_size, disk)
      disk_type   = element(local.disks_type, disk)
    }
  ])
}

resource "aws_subnet" "hana" {
  vpc_id            = var.vpc_id
  cidr_block        = var.subnet_address_range
  availability_zone = var.availability_zone

  tags = {
    Name      = "${var.deployment_name}-hana-subnet"
    Workspace = var.deployment_name
  }
}

resource "aws_route_table_association" "hana" {
  subnet_id      = aws_subnet.hana.id
  route_table_id = var.route_table_id
}

## EC2 HANA Instance
resource "aws_instance" "hana" {
  ami                         = var.image_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.hana.id
  private_ip                  = var.host_ip
  vpc_security_group_ids      = [var.security_group_id]
  availability_zone           = var.availability_zone
  source_dest_check           = false

  root_block_device {
    volume_type = "gp2"
    volume_size = "60"
  }

  dynamic "ebs_block_device" {
    for_each = { for disk in local.disks : "${disk.disk_name}" => disk }
    content {
      volume_type = ebs_block_device.value.disk_type
      volume_size = ebs_block_device.value.disk_size
      device_name = ebs_block_device.value.disk_name
    }
  }

  volume_tags = {
    Name = "${var.deployment_name}-${var.name}"
  }

  tags = {
    Name      = "${var.deployment_name}-${var.name}"
    Workspace = var.deployment_name
  }

  user_data = templatefile("${path.module}/init_script.tpl", {})
}