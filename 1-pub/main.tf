# Import Provider(s)
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

# Create a VPC
resource "aws_vpc" "play-vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name    = "${var.default_infra_name_tag}-vpc"
    Project = "${var.default_infra_name_tag}"
  }
}

# Create a Public Subnet
resource "aws_subnet" "play-subnet" {
  vpc_id            = aws_vpc.play-vpc.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.aws_availability_zone

  tags = {
    Name    = "${var.default_infra_name_tag}-public"
    Project = "${var.default_infra_name_tag}"
  }
}


# Internet Gateway
resource "aws_internet_gateway" "play-igw" {
  vpc_id = aws_vpc.play-vpc.id

  tags = {
    Name    = "${var.default_infra_name_tag}-igw"
    Project = "${var.default_infra_name_tag}"
  }
}

# Route Table
resource "aws_route_table" "play-route-table" {
  vpc_id = aws_vpc.play-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.play-igw.id
  }

  tags = {
    Name    = "${var.default_infra_name_tag}-public-rt"
    Project = "${var.default_infra_name_tag}"
  }

  depends_on = [aws_internet_gateway.play-igw]
}

# Associate the route table with the appropriate subnet(s)
resource "aws_route_table_association" "public_rt_association" {
  subnet_id      = aws_subnet.play-subnet.id
  route_table_id = aws_route_table.play-route-table.id
}

# Security Group
resource "aws_security_group" "play-sg" {
  vpc_id      = aws_vpc.play-vpc.id
  description = "Allow SSH, HTTP, and HTTPS inbound traffic"

  tags = {
    Name    = "${var.default_infra_name_tag}-public-sg"
    Project = "${var.default_infra_name_tag}"
  }

}

# Ingress rule for SSH
resource "aws_vpc_security_group_ingress_rule" "play-allow-ssh" {
  security_group_id = aws_security_group.play-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# Ingress rule for HTTP
resource "aws_vpc_security_group_ingress_rule" "play-allow-http" {
  security_group_id = aws_security_group.play-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# Ingress rule for HTTPS
resource "aws_vpc_security_group_ingress_rule" "play-allow-https" {
  security_group_id = aws_security_group.play-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

# Egress rule for All Traffic
resource "aws_vpc_security_group_egress_rule" "play-allow-all-traffic" {
  security_group_id = aws_security_group.play-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# EC2 Instance(s)
# Public Instance
resource "aws_instance" "play-aws" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2_instance_type

  subnet_id                   = aws_subnet.play-subnet.id
  associate_public_ip_address = "true"
  key_name                    = var.key_pair_name
  vpc_security_group_ids      = [aws_security_group.play-sg.id]

  # Define the EBS block storage
  root_block_device {
    volume_size = 30 # Sets the EBS size to 20 GB
  }

  user_data = <<-EOF
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -y
sudo apt-get upgrade -y

# Update /etc/hosts with the proper entry
HOST=$(hostname)
export VM_IP=$(hostname -I | awk '{print $1}')
sed -i "1s/^/$VM_IP $HOST\n/" /etc/hosts
EOF


  tags = {
    Name    = "${var.default_infra_name_tag}"
    Project = "${var.default_infra_name_tag}"
  }

  depends_on = [aws_route_table.play-route-table]
}
