terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.62.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}
# Create a VPC
resource "aws_vpc" "VPC_git" {
  cidr_block = "10.15.0.0/16"


  tags = {
    Name = "VPC_git"
  }
}

#create a public subnet

resource "aws_subnet" "pub_subnet_git1" {
  vpc_id     = aws_vpc.VPC_git.id
  cidr_block = "10.15.1.0/24"
  availability_zone=  "us-east-2a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "pub_subnet_git1"
  }
}

resource "aws_subnet" "pub_subnet_git2" {
  vpc_id     = aws_vpc.VPC_git.id
  cidr_block = "10.15.2.0/24"
  availability_zone=  "us-east-2b"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "pub_subnet_git2"
  }
}

#creating an internet gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.VPC_git.id

  tags = {
    Name = "my_igw"
  }
}


#Public route table

resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.VPC_git.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }


  tags = {
    Name = "pub_rt"
  }
}

#attaching the subnets that i created to the aws_route_table

resource "aws_route_table_association" "a_pub_subnet" {
  subnet_id      = aws_subnet.pub_subnet_git1.id
  route_table_id = aws_route_table.pub_rt.id
}
resource "aws_route_table_association" "b_pub_subnet" {
  subnet_id      = aws_subnet.pub_subnet_git2.id
  route_table_id = aws_route_table.pub_rt.id
}

#create a private subnet

resource "aws_subnet" "pvt_subnet_git1" {
  vpc_id     = aws_vpc.VPC_git.id
  cidr_block = "10.15.3.0/24"
  availability_zone=  "us-east-2a"


  tags = {
    Name = "pvt_subnet_git1"
  }
}

resource "aws_subnet" "pvt_subnet_git2" {
  vpc_id     = aws_vpc.VPC_git.id
  cidr_block = "10.15.4.0/24"
  availability_zone=  "us-east-2b"
 

  tags = {
    Name = "pvt_subnet_git2"
  }
}


# Elastic IP

resource "aws_eip" "eip_natgw" {
  domain   = "vpc"
}

#natgateway

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.eip_natgw.id
  subnet_id     = aws_subnet.pub_subnet_git2.id

  tags = {
    Name = "NAT_gw"
  }
  }



#Private route table

resource "aws_route_table" "pvt_rt" {
  vpc_id = aws_vpc.VPC_git.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    Name = "pvt_rt"
  }

}

# to ensure ordering , it is recommended to add an explicit dependency
# on the internet gateway for VPC.

#depends_on = [aws_internet_gateway.gw]


#attaching the subnets that i created to the aws_route_table

resource "aws_route_table_association" "a_pvt_subnet" {
  subnet_id      = aws_subnet.pvt_subnet_git1.id
  route_table_id = aws_route_table.pvt_rt.id
}
resource "aws_route_table_association" "b_pvt_subnet" {
  subnet_id      = aws_subnet.pvt_subnet_git2.id
  route_table_id = aws_route_table.pvt_rt.id

  }

# creating Security groups

resource "aws_security_group" "allow_tcp" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic "
  vpc_id      = aws_vpc.VPC_git.id


ingress{
    description= "TLS from VPC"
    from_port=22
    to_port=22
    protocol="tcp"
    cidr_blocks =["0.0.0.0/0"]
}

egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ssh_allow_tls"
  }
}








  # EC2

data "aws_ami" "Amazonlinux2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "pub_server" {
  ami           = data.aws_ami.Amazonlinux2.id
  subnet_id = aws_subnet.pub_subnet_git2.id
  instance_type = "t3.micro"
  key_name= "terraform"
  security_groups = ["${aws_security_group.allow_tcp.id}"]

  tags = {
    Name = "pub_Instance_git"
  }
}


#private instance_type


resource "aws_instance" "pvt_server" {
  ami           = data.aws_ami.Amazonlinux2.id
  subnet_id = aws_subnet.pvt_subnet_git2.id
  instance_type = "t3.micro"
  key_name= "terraform"
  security_groups = ["${aws_security_group.allow_tcp.id}"]

  tags = {
    Name = "pvt_Instance_git"
  }
}