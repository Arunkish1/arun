terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "my_arun" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  assign_generated_ipv6_cidr_block = true

  tags = {
    Name = "vpc1"
  }
}

resource "aws_subnet" "pubsu1" {
  vpc_id     = aws_vpc.my_arun.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnetvpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_arun.id

  tags = {
    Name = "main"
  }
}

resource "aws_route_table" "pubr1" {
  vpc_id = aws_vpc.my_arun.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "routertab"
  }
}

resource "aws_route_table_association" "bar" {
  subnet_id      = aws_subnet.pubsu1.id
  route_table_id = aws_route_table.pubr1.id
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.my_arun.id

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv6" {
  security_group_id = aws_security_group.allow_tls.id
   cidr_ipv6         = "::/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_instance" "web" {
  ami           = "ami-0f918f7e67a3323f0"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.pubsu1.id
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  key_name = "ter"
  associate_public_ip_address = true
  tags = {
    Name = "HelloWorld1"
  }
 output "aws_instances" {
  value = [for instance in aws_instance.this : instance.public_ip]
 }
}
