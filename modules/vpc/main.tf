## VPC
resource "aws_vpc" "main" {
  cidr_block       = var.cidr

  tags = {
    Name = "${var.env}-vpc"
  }
}

## SUBNETS
resource "aws_subnet" "public_subnet" {
  count               = length(var.public_subnets)
  vpc_id              = aws_vpc.main.id
  cidr_block          = var.public_subnets[count.index]
  availability_zone   = var.availability_zones[count.index]

  tags = {
    Name = "public_subnet-${split("-", var.availability_zones[count.index])[2]}"
  }
}

resource "aws_subnet" "web_subnet" {
  count                 = length(var.web_subnets)
  vpc_id                = aws_vpc.main.id
  cidr_block            = var.web_subnets[count.index]
  availability_zone     = var.availability_zones[count.index]

  tags = {
    Name = "web-subnet-${split("-", var.availability_zones[count.index])[2]}"
  }
}

resource "aws_subnet" "app_subnet" {
  count               = length(var.app_subnets)
  vpc_id              = aws_vpc.main.id
  cidr_block          = var.app_subnets[count.index]
  availability_zone   = var.availability_zones[count.index]

  tags = {
    Name = "app_subnet-${split("-", var.availability_zones[count.index])[2]}"
  }
}

resource "aws_subnet" "db_subnet" {
  count               = length(var.db_subnets)
  vpc_id              = aws_vpc.main.id
  cidr_block          = var.db_subnets[count.index]
  availability_zone   = var.availability_zones[count.index]

  tags = {
    Name = "db_subnet-${split("-", var.availability_zones[count.index])[2]}"
  }
}

## Internet Gateway for public
resource "aws_internet_gateway" "internet_gw" {
  vpc_id  = aws_vpc.main.id

  tags = {
    Name = "${var.env}-igw"
  }
}

## NAT-GATEWAY
resource "aws_eip" "ngw_ip" {
  count       = length(var.availability_zones)
  domain      = "vpc"
}
resource "aws_nat_gateway" "main" {
  count           = length(var.availability_zones)
  allocation_id   = aws_eip.ngw_ip.*.id[count.index]
  subnet_id       = aws_subnet.public_subnet.*.id[count.index]

  tags = {
    Name = "nat_gateway-${split("-", var.availability_zones[count.index])[2]}"
  }
}

## Route Table
resource "aws_route_table" "public-rt" {
  count     = length(var.public_subnets)
  vpc_id    = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gw.id
  }

  route {
    cidr_block                = var.default_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
  }

   tags = {
    Name = "public-rt-${split("-", var.availability_zones[count.index])[2]}"
  }
}

resource "aws_route_table" "web-rt" {
  count       = length(var.web_subnets)
  vpc_id      = aws_vpc.main.id

  route {
    cidr_block        = "0.0.0.0/0"
    nat_gateway_id    = aws_nat_gateway.main.*.id[count.index]
  }

  route {
    cidr_block                = var.default_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
  }
  tags = {
    Name = "web-rt-${split("-", var.availability_zones[count.index])[2]}"
  }
}

resource "aws_route_table" "app-rt" {
  count       = length(var.app_subnets)
  vpc_id      = aws_vpc.main.id

  route {
    cidr_block        = "0.0.0.0/0"
    nat_gateway_id    = aws_nat_gateway.main.*.id[count.index]
  }

  route {
    cidr_block                = var.default_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
  }
  tags = {
    Name = "app-rt-${split("-", var.availability_zones[count.index])[2]}"
  }
}

resource "aws_route_table" "db-rt" {
  count     = length(var.db_subnets)
  vpc_id    = aws_vpc.main.id

  route {
    cidr_block        = "0.0.0.0/0"
    nat_gateway_id    = aws_nat_gateway.main.*.id[count.index]
  }

  route {
    cidr_block                = var.default_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
  }
  tags = {
    Name = "db-rt-${split("-", var.availability_zones[count.index])[2]}"
  }
}

## Route Table Association
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public_subnet.*.id[count.index]
  route_table_id = aws_route_table.public-rt.*.id[count.index]
}

resource "aws_route_table_association" "web" {
  count          = length(var.web_subnets)
  subnet_id      = aws_subnet.web_subnet.*.id[count.index]
  route_table_id = aws_route_table.web-rt.*.id[count.index]
}

resource "aws_route_table_association" "app" {
  count          = length(var.app_subnets)
  subnet_id      = aws_subnet.app_subnet.*.id[count.index]
  route_table_id = aws_route_table.app-rt.*.id[count.index]
}

resource "aws_route_table_association" "db" {
  count          = length(var.db_subnets)
  subnet_id      = aws_subnet.db_subnet.*.id[count.index]
  route_table_id = aws_route_table.db-rt.*.id[count.index]
}

## Peering
resource "aws_vpc_peering_connection" "vpc_peering" {
  peer_vpc_id   = aws_vpc.main.id
  vpc_id        = var.default_vpc_id
  auto_accept   = true
}

resource "aws_route" "default-vpc-peer-route" {
  route_table_id            = var.default_vpc_rt
  destination_cidr_block    = var.cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}
