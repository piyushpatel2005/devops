# VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * Route Table
#

resource "aws_vpc" "eks_vpc" {
  cidr_block = "172.1.0.0/16"

  tags = map(
    "Name", "${var.vpc-name}",
    "kubernetes.io/cluster/${var.cluster-name}", "shared",
  )
}

resource "aws_subnet" "eks_vpc" {
  count = 2

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = "172.1.${count.index}.0/24"
  vpc_id            = aws_vpc.eks_vpc.id
  map_public_ip_on_launch = true

  tags = map(
    "Name", "${var.cluster-name}-subnet",
    "kubernetes.io/cluster/${var.cluster-name}", "shared",
  )
}

resource "aws_internet_gateway" "eks_vpc" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "${var.cluster-name}-IG"
  }
}

resource "aws_route_table" "eks_vpc" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_vpc.id
  }
}

resource "aws_route_table_association" "eks_vpc" {
  count = 2

  subnet_id      = aws_subnet.eks_vpc.*.id[count.index]
  route_table_id = aws_route_table.eks_vpc.id
}