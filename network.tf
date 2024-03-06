variable "external_ips"{
  default = ["38.34.109.158/32","146.115.59.209/32"]
}
variable "allowed_ips"{
  default = ["38.34.109.158/32","146.115.59.209/32","10.0.0.0/28"]
}

resource "aws_vpc" "vpc" {
    cidr_block = "10.0.1.0/24"
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags       = {
        Name = "${var.project_name} EKS VPC"
    }
}

data "aws_availability_zones" "available" {}

## Pulic Subnet
# Create public subnet in us-east-2a
resource "aws_subnet" "public_subnet1" {
    vpc_id                  = aws_vpc.vpc.id
    cidr_block              = "10.0.1.0/28"
    availability_zone       = data.aws_availability_zones.available.names[0]
    tags = {
        "Name" = "${var.project_name} Public Subnet 1"
    }
}

resource "aws_subnet" "public_subnet2" {
    vpc_id                  = aws_vpc.vpc.id
    cidr_block              = "10.0.1.16/28"
    availability_zone       = data.aws_availability_zones.available.names[1]
    tags = {
        "Name" = "${var.project_name} Public Subnet 2"
    }
}

resource "aws_internet_gateway" "internet_gateway" {
    vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.internet_gateway.id
    }
}

resource "aws_route_table_association" "route_table_association" {
    subnet_id      = aws_subnet.public_subnet1.id
    route_table_id = aws_route_table.public.id
}

# Create Elastic IP for the NAT Gateway
resource "aws_eip" "fah_eip" {
  domain   = "vpc"
}

# Create NAT Gateway
resource "aws_nat_gateway" "fah_nat_gateway" {
  allocation_id = aws_eip.fah_eip.id
  subnet_id     = aws_subnet.public_subnet1.id

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_security_group" "security_group" {
    vpc_id      = aws_vpc.vpc.id

    ingress {
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        cidr_blocks     = var.allowed_ips
    }

    ingress {
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        cidr_blocks     = var.allowed_ips
    }
    
    ingress {
        from_port       = 443
        to_port         = 443
        protocol        = "tcp"
        cidr_blocks     = var.allowed_ips
    }

    egress {
        cidr_blocks = ["0.0.0.0/0"]
        from_port = 0
        to_port = 0
        protocol = "-1"
    }
}
