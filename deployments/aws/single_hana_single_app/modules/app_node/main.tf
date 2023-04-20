# Network resources: subnets, routes, etc

resource "aws_subnet" "app" {
  vpc_id            = var.vpc_id
  cidr_block        = var.subnet_address_range
  availability_zone = var.availability_zone

  tags = {
    Name      = "${var.deployment_name}-app-subnet"
    Workspace = var.deployment_name
  }
}

resource "aws_route_table_association" "app" {
  subnet_id      = aws_subnet.app.id
  route_table_id = var.route_table_id
}

# EFS storage for nfs share used by App for /usr/sap/{sid} and /sapmnt
# It will be created for app only when drbd is disabled
# terraform import module.app_node.aws_efs_file_system.app-efs arn:aws:elasticfilesystem:eu-central-1:xxx:file-system/fs-xxxx
resource "aws_efs_file_system" "app-efs" {
  performance_mode = var.efs_performance_mode

  tags = {
    Name = "${var.deployment_name}-efs"
  }
}

resource "aws_efs_mount_target" "app-efs-mount-target" {
  file_system_id  = aws_efs_file_system.app-efs.id
  subnet_id       = aws_subnet.app.id
  security_groups = [var.security_group_id]
}

resource "aws_instance" "app" {
  ami                         = var.image_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.app.id
  private_ip                  = var.host_ip
  vpc_security_group_ids      = [var.security_group_id]
  availability_zone           = var.availability_zone
  source_dest_check           = false

  root_block_device {
    volume_type = "gp2"
    volume_size = "60"
  }

  # Disk to store App software installation files
  ebs_block_device {
    volume_type = "gp2"
    volume_size = "60"
    device_name = "/dev/sdb"
  }

  volume_tags = {
    Name = "${var.deployment_name}-${var.name}"
  }

  tags = {
    Name      = "${var.deployment_name}-${var.name}"
    Workspace = var.deployment_name
  }

  user_data = templatefile("${path.module}/init_script.tpl",
    {
      efs_dns = aws_efs_file_system.app-efs.dns_name
    }
  )

  depends_on = [aws_efs_mount_target.app-efs-mount-target]
}

