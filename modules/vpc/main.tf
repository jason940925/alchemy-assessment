### vpc.tf
### purpose: config for vpcs

data "aws_region" "scope" {}

### VARIABLES ###

locals {
  eks_tags = var.eks_enabled ? {
    for name in var.cluster_name :
    "kubernetes.io/cluster/${name}" => "shared"
  } : {}

}

### VPC ###

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true

  tags = merge(
    { Name = "${var.account_name}-${var.application_name}" },
    local.eks_tags
  )
}

resource "aws_vpc_ipv4_cidr_block_association" "vpc" {
  count = var.enable_container_subnet ? 1 : 0
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.cidr_block_secondary
}

### INTERNET GATEWAY ###

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
}

### NAT GATEWAYS ###

resource "aws_nat_gateway" "nat_primary" {
  allocation_id = aws_eip.eip_primary.id
  subnet_id     = aws_subnet.public_primary.id
  depends_on    = [aws_internet_gateway.internet_gateway]

  tags = {
    Name = "${var.account_name}-${var.application_name}-public-primary"
  }
}

resource "aws_eip" "eip_primary" {
  vpc = true
}

resource "aws_nat_gateway" "nat_secondary" {
  allocation_id = aws_eip.eip_secondary.id
  subnet_id     = aws_subnet.public_secondary.id
  depends_on    = [aws_internet_gateway.internet_gateway]

  tags = {
    Name = "${var.account_name}-${var.application_name}-public-secondary"
  }
}

resource "aws_eip" "eip_secondary" {
  vpc = true
}

### VPN GATEWAYS ###
resource "aws_vpn_gateway" "vpn_gateway" {
  count = var.enable_vpn_connection ? 1 : 0

  vpc_id = aws_vpc.vpc[count.index].id
}

### PUBLIC SUBNETS ###
data "aws_availability_zones" "available" {
}

resource "aws_subnet" "public_primary" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.cidr_block, 3, 0)
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(
    {
      Name   = "${var.account_name}-${var.application_name}-public-primary"
      Zone   = data.aws_availability_zones.available.names[0]
      Tier   = var.subnet_public_tier
      Set    = var.subnet_public_set
      Region = data.aws_region.scope.name
    },
    var.eks_enabled ? { "kubernetes.io/role/elb" = "1" } : {},
    local.eks_tags,
    var.public_subnet_custom_tags
  )
}

resource "aws_subnet" "public_secondary" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.cidr_block, 3, 1)
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = merge(
    {
      Name   = "${var.account_name}-${var.application_name}-public-secondary"
      Zone   = data.aws_availability_zones.available.names[1]
      Tier   = var.subnet_public_tier
      Set    = var.subnet_public_set
      Region = data.aws_region.scope.name
    },
    var.eks_enabled ? { "kubernetes.io/role/elb" = "1" } : {},
    local.eks_tags,
    var.public_subnet_custom_tags
  )
}

resource "aws_route_table" "public" {
  vpc_id       = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "${var.account_name}-${var.application_name}-public"
  }
}

resource "aws_route_table_association" "public_primary" {
  subnet_id      = aws_subnet.public_primary.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_secondary" {
  subnet_id      = aws_subnet.public_secondary.id
  route_table_id = aws_route_table.public.id
}

### PRIVATE SUBNETS ###

resource "aws_subnet" "private_primary" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.cidr_block, 2, 1)
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(
    {
      Name   = "${var.account_name}-${var.application_name}-private-primary"
      Zone   = data.aws_availability_zones.available.names[0]
      Tier   = var.subnet_private_tier
      Set    = var.subnet_private_set
      Region = data.aws_region.scope.name
    },
    var.eks_enabled ? { "kubernetes.io/role/internal-elb" = "1" } : {},
    local.eks_tags,
    var.private_subnet_custom_tags
  )
}

resource "aws_route_table" "private_primary" {
  vpc_id           = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_primary.id
  }

  tags = {
    Name = "${var.account_name}-${var.application_name}-private-primary"
  }
}

resource "aws_route_table_association" "private_primary" {
  subnet_id      = aws_subnet.private_primary.id
  route_table_id = aws_route_table.private_primary.id
}

resource "aws_subnet" "private_secondary" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.cidr_block, 2, 2)
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = merge(
    {
      Name   = "${var.account_name}-${var.application_name}-private-secondary"
      Zone   = data.aws_availability_zones.available.names[1]
      Tier   = var.subnet_private_tier
      Set    = var.subnet_private_set
      Region = data.aws_region.scope.name
    },
    var.eks_enabled ? { "kubernetes.io/role/internal-elb" = "1" } : {},
    local.eks_tags,
    var.private_subnet_custom_tags
  )
}

resource "aws_route_table" "private_secondary" {
  vpc_id           = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_secondary.id
  }

  tags = {
    Name = "${var.account_name}-${var.application_name}-private-secondary"
  }
}

resource "aws_route_table_association" "private_secondary" {
  subnet_id      = aws_subnet.private_secondary.id
  route_table_id = aws_route_table.private_secondary.id
}

### DATA SUBNETS ###

resource "aws_subnet" "data_primary" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.cidr_block, 3, 6)
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(
    {
      Name   = "${var.account_name}-${var.application_name}-data-primary"
      Zone   = data.aws_availability_zones.available.names[0]
      Tier   = var.subnet_data_tier
      Set    = var.subnet_data_set
      Region = data.aws_region.scope.name
    },
    var.data_subnet_custom_tags
  )
}

resource "aws_subnet" "data_secondary" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.cidr_block, 3, 7)
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = merge(
    {
      Name   = "${var.account_name}-${var.application_name}-data-secondary"
      Zone   = data.aws_availability_zones.available.names[1]
      Tier   = var.subnet_data_tier
      Set    = var.subnet_data_set
      Region = data.aws_region.scope.name
    },
    var.data_subnet_custom_tags
  )
}

resource "aws_route_table" "data_primary" {
  vpc_id           = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_primary.id
  }

  tags = merge(
    { Name = "${var.account_name}-${var.application_name}-data-primary" },
    var.data_subnet_custom_tags
  )
}

resource "aws_route_table_association" "data_primary" {
  subnet_id      = aws_subnet.data_primary.id
  route_table_id = aws_route_table.data_primary.id
}

resource "aws_route_table" "data_secondary" {
  vpc_id           = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_secondary.id
  }

  tags = merge(
    {
      Name = "${var.account_name}-${var.application_name}-data-secondary"
    },
    var.data_subnet_custom_tags
  )
}

resource "aws_route_table_association" "data_secondary" {
  subnet_id      = aws_subnet.data_secondary.id
  route_table_id = aws_route_table.data_secondary.id
}

resource "aws_subnet" "container_primary" {
  depends_on = [aws_vpc_ipv4_cidr_block_association.vpc]
  count      = var.enable_container_subnet ? 1 : 0

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.cidr_block_secondary, 2, 0)
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(
    {
      Name   = "${var.account_name}-${var.application_name}-container-primary"
      Zone   = data.aws_availability_zones.available.names[0]
      Tier   = var.subnet_container_tier
      Set    = var.subnet_container_set
      Region = data.aws_region.scope.name
    },
    var.container_subnet_custom_tags
  )
}

resource "aws_subnet" "container_secondary" {
  depends_on = [aws_vpc_ipv4_cidr_block_association.vpc]
  count      = var.enable_container_subnet ? 1 : 0

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.cidr_block_secondary, 2, 1)
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = merge(
    {
      Name   = "${var.account_name}-${var.application_name}-container-secondary"
      Zone   = data.aws_availability_zones.available.names[1]
      Tier   = var.subnet_container_tier
      Set    = var.subnet_container_set
      Region = data.aws_region.scope.name
    },
    var.container_subnet_custom_tags
  )
}

resource "aws_route_table" "container_primary" {
  count = var.enable_container_subnet ? 1 : 0

  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_primary.id
  }

  tags = {
    Name = "${var.account_name}-${var.application_name}-container-primary"
  }
}

resource "aws_route_table_association" "container_primary" {
  count = var.enable_container_subnet ? 1 : 0

  subnet_id      = aws_subnet.container_primary[count.index].id
  route_table_id = aws_route_table.container_primary[count.index].id
}

resource "aws_route_table" "container_secondary" {
  count = var.enable_container_subnet ? 1 : 0

  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_secondary.id
  }

  tags = {
    Name = "${var.account_name}-${var.application_name}-container-secondary"
  }
}

resource "aws_route_table_association" "container_secondary" {
  count = var.enable_container_subnet ? 1 : 0

  subnet_id      = aws_subnet.container_secondary[count.index].id
  route_table_id = aws_route_table.container_secondary[count.index].id
}

# Restrict all traffic for dedault sg
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Default Security Group"
  }
}