locals {
  deployment_name       = var.deployment_name != "" ? var.deployment_name : terraform.workspace
  public_key            = fileexists(var.public_key) ? file(var.public_key) : var.public_key
  subnet_address_ranges = [cidrsubnet(var.vpc_address_range, 8, 1), cidrsubnet(var.vpc_address_range, 8, 2)]
  server_ip             = cidrhost(cidrsubnet(var.vpc_address_range, 8, 0), 5)
  machines = [for i, machine in var.machines : {
    name       = "${local.deployment_name}-server-${machine.name}"
    image_id   = machine.image_id
    private_ip = cidrhost(cidrsubnet(var.vpc_address_range, 8, 0), 5 + i)
    init_script = templatefile("${path.module}/init_script.tpl",
      {
        license_key   = machine.license_key
        license_email = var.license_email
        sles_version  = machine.sles_version
      }
    )
  }]
}

resource "aws_key_pair" "key_pair" {
  key_name   = "${local.deployment_name} - terraform"
  public_key = local.public_key
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_address_range
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name      = "${local.deployment_name}-vpc"
    Workspace = local.deployment_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name      = "${local.deployment_name}-igw"
    Workspace = local.deployment_name
  }
}

resource "aws_subnet" "infra" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.vpc_address_range, 8, 0)
  availability_zone = element(data.aws_availability_zones.available.names, 0)

  tags = {
    Name      = "${local.deployment_name}-infra-subnet"
    Workspace = local.deployment_name
  }
}

resource "aws_route_table_association" "infra" {
  subnet_id      = aws_subnet.infra.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "ngw" {
  vpc = true

  tags = {
    Name      = "${local.deployment_name}-eip-ngw"
    Workspace = local.deployment_name
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "ngw" {
  connectivity_type = "public"
  allocation_id     = aws_eip.ngw.id
  subnet_id         = aws_subnet.public.id

  tags = {
    Name      = "${local.deployment_name}-ngw"
    Workspace = local.deployment_name
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_address_range, 8, 254)
  availability_zone       = element(data.aws_availability_zones.available.names, 0)
  map_public_ip_on_launch = true

  tags = {
    Name      = "${local.deployment_name}-public-subnet"
    Workspace = local.deployment_name
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name      = "${local.deployment_name}-route-table-public"
    Workspace = local.deployment_name
  }

  depends_on = [aws_nat_gateway.ngw]
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_security_group" "secgroup" {
  name   = "${local.deployment_name}-sg"
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name      = "${local.deployment_name}-sg"
    Workspace = local.deployment_name
  }
}

resource "aws_security_group_rule" "outall" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.secgroup.id
}

resource "aws_security_group_rule" "local" {
  type        = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = [var.vpc_address_range]

  security_group_id = aws_security_group.secgroup.id
}

resource "aws_security_group_rule" "ssh" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.secgroup.id
}

resource "aws_security_group_rule" "http" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.secgroup.id
}

resource "aws_security_group_rule" "https" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.secgroup.id
}

resource "aws_instance" "server" {
  count                       = length(local.machines)
  ami                         = element(local.machines, count.index).image_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.key_pair.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.infra.id
  private_ip                  = element(local.machines, count.index).private_ip
  vpc_security_group_ids      = [aws_security_group.secgroup.id]
  availability_zone           = element(data.aws_availability_zones.available.names, 0)

  root_block_device {
    volume_type = "gp2"
    volume_size = "60"
  }

  volume_tags = {
    Name = "${element(local.machines, count.index).name}-volume-${count.index + 1}"
  }

  tags = {
    Name      = element(local.machines, count.index).name
    Workspace = var.deployment_name
  }

  user_data = element(local.machines, count.index).init_script

}