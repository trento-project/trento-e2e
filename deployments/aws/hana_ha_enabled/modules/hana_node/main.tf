locals {
  disks_number = length(split(",", var.hana_data_disks_configuration["disks_size"]))
  disks_name   = [for disk_name in split(",", var.block_devices) : trimspace(disk_name)]
  disks_size   = [for disk_size in split(",", var.hana_data_disks_configuration["disks_size"]) : tonumber(trimspace(disk_size))]
  disks_type   = [for disk_type in split(",", var.hana_data_disks_configuration["disks_type"]) : trimspace(disk_type)]
  disks = flatten([
    for node in range(2) : [
      for disk in range(local.disks_number) : {
        node_num    = node
        node        = "${var.name}${format("%02d", node + 1)}"
        disk_number = disk
        disk_name   = element(local.disks_name, disk)
        disk_size   = element(local.disks_size, disk)
        disk_type   = element(local.disks_type, disk)
      }
    ]
  ])
  user_data = templatefile("${path.module}/init_script.tpl",
    {
      tag            = "${var.deployment_name}-cluster"
      virtual_ip     = var.hana_virtual_ip
      route_table_id = var.route_table_id
      access_key     = var.aws_access_key_id
      secret_key     = var.aws_secret_key
    }
  )
}

resource "aws_subnet" "hana" {
  count             = 2
  vpc_id            = var.vpc_id
  cidr_block        = element(var.subnet_address_ranges, count.index)
  availability_zone = element(var.availability_zones, count.index % 2)

  tags = {
    Name      = "${var.deployment_name}-hana-subnet-${count.index + 1}"
    Workspace = var.deployment_name
  }
}

resource "aws_route_table_association" "hana" {
  count          = 2
  subnet_id      = element(aws_subnet.hana.*.id, count.index)
  route_table_id = var.route_table_id
}

resource "aws_route" "hana_cluster_vip" {
  route_table_id         = var.route_table_id
  destination_cidr_block = "${var.hana_virtual_ip}/32"
  network_interface_id   = aws_instance.hana.0.primary_network_interface_id
}

module "sap_cluster_policies" {
  source            = "../../../generic_modules/sap_cluster_policies"
  deployment_name   = var.deployment_name
  name              = var.name
  aws_region        = var.aws_region
  cluster_instances = aws_instance.hana.*.id
  route_table_id    = var.route_table_id
}

## EC2 HANA Instance
resource "aws_instance" "hana" {
  count                       = 2
  ami                         = element(var.image_ids, count.index)
  instance_type               = var.instance_type
  key_name                    = var.key_name
  associate_public_ip_address = true
  subnet_id                   = element(aws_subnet.hana.*.id, count.index % 2)
  private_ip                  = element(var.host_ips, count.index)
  vpc_security_group_ids      = [var.security_group_id]
  availability_zone           = element(var.availability_zones, count.index % 2)
  iam_instance_profile        = module.sap_cluster_policies.cluster_profile_name[0]
  source_dest_check           = false

  root_block_device {
    volume_type = "gp2"
    volume_size = "60"
  }

  dynamic "ebs_block_device" {
    for_each = { for disk in local.disks : "${disk.disk_name}" => disk if disk.node_num == count.index }
    content {
      volume_type = ebs_block_device.value.disk_type
      volume_size = ebs_block_device.value.disk_size
      device_name = ebs_block_device.value.disk_name
    }
  }

  volume_tags = {
    Name = "${var.deployment_name}-${var.name}${format("%02d", count.index + 1)}"
  }

  tags = {
    Name                             = "${var.deployment_name}-${var.name}${format("%02d", count.index + 1)}"
    Workspace                        = var.deployment_name
    "${var.deployment_name}-cluster" = "${var.name}${format("%02d", count.index + 1)}"
  }

  user_data = count.index == 0 ? local.user_data : ""
}