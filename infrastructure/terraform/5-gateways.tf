# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.ecommerce-web-gen-vpc.id

  tags = {
    Name = local.igw_name
  }
}