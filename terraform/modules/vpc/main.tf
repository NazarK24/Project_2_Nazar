resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = merge(
    var.common_tags,
    { Name = "my-demo-vpc" }
  )
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.common_tags, { Name = "my-demo-igw" })
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.this.id
  cidr_block             = var.public_subnet_cidr_1
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = true
  tags = merge(var.common_tags, { Name = "Public_Subnet_1" })
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.this.id
  cidr_block             = var.public_subnet_cidr_2
  availability_zone       = "eu-north-1b"
  map_public_ip_on_launch = true
  tags = merge(var.common_tags, { Name = "Public_Subnet_2" })
}

resource "aws_subnet" "private_1" {
  vpc_id     = aws_vpc.this.id
  cidr_block = var.private_subnet_cidr_1
  availability_zone = "eu-north-1b"
  tags = merge(var.common_tags, { Name = "Private_Subnet_1" })
}

resource "aws_subnet" "private_2" {
  vpc_id     = aws_vpc.this.id
  cidr_block = var.private_subnet_cidr_2
  availability_zone = "eu-north-1c"
  tags = merge(var.common_tags, { Name = "Private_Subnet_2" })
}

# NAT Gateway
resource "aws_eip" "this" {
  tags = merge(var.common_tags, { Name = "my-demo-eip" })
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.this.id
  subnet_id     = aws_subnet.public_1.id
  tags          = merge(var.common_tags, { Name = "my-demo-nat-gw" })
}

# Публічна RT
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.common_tags, { Name = "my-demo-public-rt" })
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# Приватна RT (з NAT)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.common_tags, { Name = "my-demo-private-rt" })
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

resource "aws_route_table_association" "private_assoc_1" {
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private_1.id
}

resource "aws_route_table_association" "private_assoc_2" {
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private_2.id
}
