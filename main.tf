resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.vpc_enable_dns_hostnames
  tags = {
    Name        = format("%s-%s", var.vpc_name, var.environment)
    Environment = var.environment
  }
}

resource "aws_flow_log" "vpc_flow_log" {
  count                    = var.log_bucket_arn != "" ? 1 : 0
  log_destination          = var.log_bucket_arn
  log_destination_type     = "s3"
  traffic_type             = "ALL"
  vpc_id                   = aws_vpc.vpc.id
  max_aggregation_interval = var.log_max_aggregation_interval
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.public_subnets)
  cidr_block              = element(var.public_subnets, count.index).cidr
  availability_zone       = element(var.public_subnets, count.index).subnet_az
  map_public_ip_on_launch = false
  tags = {
    Name        = format("public-subnet-%s", element(var.public_subnets, count.index).index)
    Environment = var.environment
  }
}



/* EC2 Private subnet */
resource "aws_subnet" "ec2_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.ec2_subnets)
  cidr_block              = element(var.ec2_subnets, count.index).cidr
  availability_zone       = element(var.ec2_subnets, count.index).subnet_az
  map_public_ip_on_launch = false
  tags = {
    Name        = format("ec2-private-subnet-%s", element(var.ec2_subnets, count.index).index)
    Environment = var.environment
  }
}

/* RDS Private subnet */
resource "aws_subnet" "rds_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.rds_subnets)
  cidr_block              = element(var.rds_subnets, count.index).cidr
  availability_zone       = element(var.rds_subnets, count.index).subnet_az
  map_public_ip_on_launch = false
  tags = {
    Name        = format("rds-private-subnet-%s", element(var.rds_subnets, count.index).index)
    Environment = var.environment
  }
}

/* Elasticache Private subnet */
resource "aws_subnet" "elasticache_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.elasticache_subnets)
  cidr_block              = element(var.elasticache_subnets, count.index).cidr
  availability_zone       = element(var.elasticache_subnets, count.index).subnet_az
  map_public_ip_on_launch = false
  tags = {
    Name        = format("elasticache-private-subnet-%s", element(var.elasticache_subnets, count.index).index)
    Environment = var.environment
  }
}

resource "aws_subnet" "eks_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.eks_subnets)
  cidr_block              = element(var.eks_subnets, count.index).cidr
  availability_zone       = element(var.eks_subnets, count.index).subnet_az
  map_public_ip_on_launch = false
  tags = merge(
    element(var.eks_subnets, count.index).tags,
    {
      Name        = format("%s-private-subnet-%s", element(var.eks_subnets, count.index).cluster_name, element(var.eks_subnets, count.index).index)
      Environment = var.environment
  })
}

resource "aws_internet_gateway" "ig" {
  count  = length(var.public_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = format("%s-igw", var.environment)
    Environment = var.environment
  }
}

/* Elastic IP for NAT */
resource "aws_eip" "nat_eip" {
  count      = length(var.public_subnets) > 0 ? 1 : 0
  vpc        = true
  depends_on = [aws_internet_gateway.ig]
}

/* NAT */
resource "aws_nat_gateway" "nat" {
  count         = length(var.public_subnets) > 0 ? 1 : 0
  allocation_id = aws_eip.nat_eip[0].id
  subnet_id     = element(aws_subnet.public_subnet.*.id, 0)
  depends_on    = [aws_internet_gateway.ig]
  tags = {
    Name        = format("%s-nat", var.environment)
    Environment = var.environment
  }
}

/* Routing table for private subnet */
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = format("%s-private-route-table", var.environment)
    Environment = var.environment
  }
}

/* Routing table for public subnet */
resource "aws_route_table" "public_route_table" {
  count  = length(var.public_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = format("%s-public-route-table", var.environment)
    Environment = var.environment
  }
}


resource "aws_route" "public_internet_gateway" {
  count                  = length(var.public_subnets) > 0 ? 1 : 0
  route_table_id         = aws_route_table.public_route_table[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig[0].id
}

resource "aws_route" "private_nat_gateway" {
  count                  = length(var.public_subnets) > 0 ? 1 : 0
  route_table_id         = aws_route_table.private_route_table[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[0].id

}

/* Route table associations */
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public_route_table[0].id
}

resource "aws_route_table_association" "ec2_private" {
  count          = length(var.ec2_subnets)
  subnet_id      = element(aws_subnet.ec2_subnet.*.id, count.index)
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "rds_private" {
  count          = length(var.rds_subnets)
  subnet_id      = element(aws_subnet.rds_subnet.*.id, count.index)
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "elasticache_private" {
  count          = length(var.elasticache_subnets)
  subnet_id      = element(aws_subnet.elasticache_subnet.*.id, count.index)
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "eks_private" {
  count          = length(var.eks_subnets)
  subnet_id      = element(aws_subnet.eks_subnet.*.id, count.index)
  route_table_id = aws_route_table.private_route_table.id
}