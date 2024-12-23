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

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block             = var.public_subnet_cidr
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = true
  tags = merge(var.common_tags, { Name = "my-demo-public-subnet" })
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "eu-north-1a"
  tags = merge(var.common_tags, { Name = "my-demo-private-subnet" })
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

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Приватна RT (без NAT)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.common_tags, { Name = "my-demo-private-rt" })
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
