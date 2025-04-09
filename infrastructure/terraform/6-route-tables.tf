# Public Route Table to Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ecommerce-web-gen-vpc.id

  route {
    cidr_block = local.default_route
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = local.public_subnet_route_table_name
  }

  depends_on = [ aws_internet_gateway.igw ]
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)
  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}