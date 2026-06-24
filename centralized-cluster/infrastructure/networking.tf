data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "platform_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = var.vpc_name
  })
}

resource "aws_subnet" "platform_vpc_public_subnets" {
  vpc_id                  = aws_vpc.platform_vpc.id
  cidr_block              = var.public_subnet_cidrs[0]
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name                                     = "${var.public_subnet_name}-az1"
    "kubernetes.io/role/elb"                 = "1"
    "kubernetes.io/cluster/platform-cluster" = "shared"
  })
}

resource "aws_subnet" "platform_vpc_public_subnets_2" {
  vpc_id                  = aws_vpc.platform_vpc.id
  cidr_block              = var.public_subnet_cidrs[1]
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name                                     = "${var.public_subnet_name}-az2"
    "kubernetes.io/role/elb"                 = "1"
    "kubernetes.io/cluster/platform-cluster" = "shared"
  })
}

resource "aws_subnet" "platform_vpc_private_subnets" {
  vpc_id            = aws_vpc.platform_vpc.id
  cidr_block        = var.private_subnet_cidrs[0]
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(var.tags, {
    Name                                     = "${var.private_subnet_name}-az1"
    "kubernetes.io/role/internal-elb"        = "1"
    "kubernetes.io/cluster/platform-cluster" = "shared"
  })
}

resource "aws_subnet" "platform_vpc_private_subnets_2" {
  vpc_id            = aws_vpc.platform_vpc.id
  cidr_block        = var.private_subnet_cidrs[1]
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = merge(var.tags, {
    Name                                     = "${var.private_subnet_name}-az2"
    "kubernetes.io/role/internal-elb"        = "1"
    "kubernetes.io/cluster/platform-cluster" = "shared"
  })
}

resource "aws_internet_gateway" "platform_vpc_igw" {
  vpc_id = aws_vpc.platform_vpc.id

  tags = merge(var.tags, {
    Name = var.igw_name
  })
}

resource "aws_eip" "platform_vpc_nat_eip" {
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.natgw_name}-eip"
  })
}

resource "aws_nat_gateway" "platform_vpc_natgw" {
  allocation_id = aws_eip.platform_vpc_nat_eip.id
  subnet_id     = aws_subnet.platform_vpc_public_subnets.id

  tags = merge(var.tags, {
    Name = var.natgw_name
  })

  depends_on = [aws_internet_gateway.platform_vpc_igw]
}

resource "aws_route_table" "platform_public_rt_az1" {
  vpc_id = aws_vpc.platform_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.platform_vpc_igw.id
  }

  tags = merge(var.tags, {
    Name = "${var.public_subnet_route_table_name}-az1"
  })
}

resource "aws_route_table" "platform_public_rt_az2" {
  vpc_id = aws_vpc.platform_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.platform_vpc_igw.id
  }

  tags = merge(var.tags, {
    Name = "${var.public_subnet_route_table_name}-az2"
  })
}

resource "aws_route_table" "platform_private_rt_az1" {
  vpc_id = aws_vpc.platform_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.platform_vpc_natgw.id
  }

  tags = merge(var.tags, {
    Name = "${var.private_subnet_route_table_name}-az1"
  })
}

resource "aws_route_table" "platform_private_rt_az2" {
  vpc_id = aws_vpc.platform_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.platform_vpc_natgw.id
  }

  tags = merge(var.tags, {
    Name = "${var.private_subnet_route_table_name}-az2"
  })
}

resource "aws_route_table_association" "platform_public_subnet_az1_association" {
  subnet_id      = aws_subnet.platform_vpc_public_subnets.id
  route_table_id = aws_route_table.platform_public_rt_az1.id
}

resource "aws_route_table_association" "platform_public_subnet_az2_association" {
  subnet_id      = aws_subnet.platform_vpc_public_subnets_2.id
  route_table_id = aws_route_table.platform_public_rt_az2.id
}

resource "aws_route_table_association" "platform_private_subnet_az1_association" {
  subnet_id      = aws_subnet.platform_vpc_private_subnets.id
  route_table_id = aws_route_table.platform_private_rt_az1.id
}

resource "aws_route_table_association" "platform_private_subnet_az2_association" {
  subnet_id      = aws_subnet.platform_vpc_private_subnets_2.id
  route_table_id = aws_route_table.platform_private_rt_az2.id
}

# VPC Peering Connection: platform_vpc (requester) -> app_vpc (accepter)
# data "aws_vpc" "app_vpc" {
#   tags = {
#     Name = "app-vpc"
#   }
# }

# resource "aws_vpc_peering_connection" "platform_to_app" {
#   vpc_id      = aws_vpc.platform_vpc.id
#   peer_vpc_id = data.aws_vpc.app_vpc.id
#   auto_accept = true

#   tags = merge(var.tags, {
#     Name = "platform-vpc-to-app-vpc-peering"
#   })
# }

# resource "aws_route" "platform_public_to_app_az1" {
#   route_table_id            = aws_route_table.platform_public_rt_az1.id
#   destination_cidr_block    = data.aws_vpc.app_vpc.cidr_block
#   vpc_peering_connection_id = aws_vpc_peering_connection.platform_to_app.id
# }

# resource "aws_route" "platform_public_to_app_az2" {
#   route_table_id            = aws_route_table.platform_public_rt_az2.id
#   destination_cidr_block    = data.aws_vpc.app_vpc.cidr_block
#   vpc_peering_connection_id = aws_vpc_peering_connection.platform_to_app.id
# }

# resource "aws_route" "platform_private_to_app_az1" {
#   route_table_id            = aws_route_table.platform_private_rt_az1.id
#   destination_cidr_block    = data.aws_vpc.app_vpc.cidr_block
#   vpc_peering_connection_id = aws_vpc_peering_connection.platform_to_app.id
# }

# resource "aws_route" "platform_private_to_app_az2" {
#   route_table_id            = aws_route_table.platform_private_rt_az2.id
#   destination_cidr_block    = data.aws_vpc.app_vpc.cidr_block
#   vpc_peering_connection_id = aws_vpc_peering_connection.platform_to_app.id
# }
