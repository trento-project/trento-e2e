resource "aws_instance" "trento_server" {
  ami                         = var.image_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  associate_public_ip_address = true
  subnet_id                   = var.subnet_id
  private_ip                  = var.host_ip
  vpc_security_group_ids      = [var.security_group_id]
  availability_zone           = var.availability_zone

  root_block_device {
    volume_type = "gp2"
    volume_size = "20"
  }

  volume_tags = {
    Name = "${var.deployment_name}-trento-server"
  }

  tags = {
    Name      = "${var.deployment_name}-trento-server"
    Workspace = var.deployment_name
  }

  user_data = <<EOF
#!/bin/bash
sudo su
SUSEConnect -p PackageHub/15.4/x86_64
EOF
}