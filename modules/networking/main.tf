resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = merge(
    {
      "Name" = var.vpc_name
    },
    var.tags
  )
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.this.id
  cidr_block = var.private_subnet_cidrs[count.index]
  availability_zone = element(var.availability_zones, count.index)
  tags = merge(
    {
      "Name" = "${var.vpc_name}-private-${count.index + 1}"
    },
    var.tags
  )
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)
  vpc_id = aws_vpc.this.id
  cidr_block = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true  
  availability_zone = element(var.availability_zones, count.index)
  tags = merge(
    {
      "Name" = "${var.vpc_name}-public-${count.index + 1}"
    },
    var.tags
  )
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = merge(
    {
      "Name" = "${var.vpc_name}-igw"
    },
    var.tags
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = merge(
    {
      "Name" = "${var.vpc_name}-public-rt"
    },
    var.tags
  )
}

resource "aws_route_table_association" "public" {
  count     = length(var.public_subnet_cidrs)
  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}