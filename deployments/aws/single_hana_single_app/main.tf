locals {
  deployment_name = var.deployment_name != "" ? var.deployment_name : terraform.workspace
  public_key      = fileexists(var.public_key) ? file(var.public_key) : var.public_key

  hana_subnet_address_range = cidrsubnet(var.vpc_address_range, 8, 1)
  app_subnet_address_range  = cidrsubnet(var.vpc_address_range, 8, 2)

  trento_server_ip = var.trento_server_ip != "" ? var.trento_server_ip : cidrhost(cidrsubnet(var.vpc_address_range, 8, 0), 5)
  hana_ip          = var.hana_ip != "" ? var.hana_ip : cidrhost(local.hana_subnet_address_range, 10)
  app_ip           = var.app_ip != "" ? var.app_ip : cidrhost(local.app_subnet_address_range, 30)
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
  vpc   = true

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

module "trento_server" {
  source                        = "../generic_modules/trento_server"
  deployment_name               = local.deployment_name
  availability_zone             = element(data.aws_availability_zones.available.names, 0)
  image_id                      = var.trento_server_image_id
  key_name                      = aws_key_pair.key_pair.key_name
  security_group_id             = aws_security_group.secgroup.id
  subnet_id                     = aws_subnet.infra.id
  host_ip                       = local.trento_server_ip
}

module "hana_node" {
  source                        = "./modules/hana_node"
  aws_region                    = var.aws_region
  deployment_name               = local.deployment_name
  instance_type                 = var.hana_instancetype
  availability_zone             = element(data.aws_availability_zones.available.names, 0)
  image_id                      = var.hana_image_id
  vpc_id                        = aws_vpc.vpc.id
  subnet_address_range          = local.hana_subnet_address_range
  key_name                      = aws_key_pair.key_pair.key_name
  security_group_id             = aws_security_group.secgroup.id
  route_table_id                = aws_route_table.public.id
  host_ip                       = local.hana_ip
  block_devices                 = var.block_devices
  hana_data_disks_configuration = var.hana_data_disks_configuration
}

module "app_node" {
  source                        = "./modules/app_node"
  aws_region                    = var.aws_region
  deployment_name               = local.deployment_name
  instance_type                 = var.app_instancetype
  availability_zone             = element(data.aws_availability_zones.available.names, 0)
  image_id                      = var.app_image_id
  vpc_id                        = aws_vpc.vpc.id
  subnet_address_range          = local.app_subnet_address_range
  key_name                      = aws_key_pair.key_pair.key_name
  security_group_id             = aws_security_group.secgroup.id
  route_table_id                = aws_route_table.public.id
  host_ip                       = local.app_ip
}