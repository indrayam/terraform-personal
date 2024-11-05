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
  region = var.aws_region
}

# Create a VPC
resource "aws_vpc" "play-vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "${var.default_infra_name_tag}-vpc"
    Project = "${var.default_infra_name_tag}"
  }
}

# Create a Public Subnet
resource "aws_subnet" "play-subnet" {
  vpc_id            = aws_vpc.play-vpc.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.aws_availability_zone

  tags = {
    Name = "${var.default_infra_name_tag}-public"
    Project = "${var.default_infra_name_tag}"
  }
}

# Create Two Private Subnets
resource "aws_subnet" "play-subnet-private-1" {
  vpc_id            = aws_vpc.play-vpc.id
  cidr_block        = var.subnet_cidr_block_private1
  availability_zone = var.aws_availability_zone

  tags = {
    Name = "${var.default_infra_name_tag}-private-1"
    Project = "${var.default_infra_name_tag}"
  }
}

resource "aws_subnet" "play-subnet-private-2" {
  vpc_id            = aws_vpc.play-vpc.id
  cidr_block        = var.subnet_cidr_block_private2
  availability_zone = var.aws_availability_zone

  tags = {
    Name = "${var.default_infra_name_tag}-private-2"
    Project = "${var.default_infra_name_tag}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "play-igw" {
  vpc_id = aws_vpc.play-vpc.id

  tags = {
    Name = "${var.default_infra_name_tag}-igw"
    Project = "${var.default_infra_name_tag}"
  }
}

# EIP
resource "aws_eip" "play-eip" {
  domain = "vpc"

  tags = {
    Name = "${var.default_infra_name_tag}-eip"
    Project = "${var.default_infra_name_tag}"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "play-natgw" {
  allocation_id = aws_eip.play-eip.id
  subnet_id     = aws_subnet.play-subnet.id

  tags = {
    Name = "${var.default_infra_name_tag}-natgw"
    Project = "${var.default_infra_name_tag}"
  }

  depends_on = [ aws_eip.play-eip ]
}

# Route Table
resource "aws_route_table" "play-route-table" {
  vpc_id = aws_vpc.play-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.play-igw.id
  }

  tags = {
    Name = "${var.default_infra_name_tag}-public-rt"
    Project = "${var.default_infra_name_tag}"
  }

  depends_on = [ aws_internet_gateway.play-igw ]
}

# Route Table (Private)
resource "aws_route_table" "play-route-table-private" {
  vpc_id = aws_vpc.play-vpc.id

  route {
    cidr_block = aws_vpc.play-vpc.cidr_block
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.play-natgw.id
  }

  tags = {
    Name = "${var.default_infra_name_tag}-private-rt"
    Project = "${var.default_infra_name_tag}"
  }

  depends_on = [ aws_nat_gateway.play-natgw ]
}

# Associate the route table with the appropriate subnet(s)
resource "aws_route_table_association" "public_rt_association" {
  subnet_id      = aws_subnet.play-subnet.id
  route_table_id = aws_route_table.play-route-table.id
}

resource "aws_route_table_association" "private-1_rt_association" {
  subnet_id      = aws_subnet.play-subnet-private-1.id
  route_table_id = aws_route_table.play-route-table-private.id
}

resource "aws_route_table_association" "private-2_rt_association" {
  subnet_id      = aws_subnet.play-subnet-private-2.id
  route_table_id = aws_route_table.play-route-table-private.id
}

# Security Group
resource "aws_security_group" "play-sg" {
  vpc_id = aws_vpc.play-vpc.id
  description = "Allow SSH, HTTP, and HTTPS inbound traffic"

  tags = {
    Name = "${var.default_infra_name_tag}-public-sg"
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

# Security Group for Private Instances
resource "aws_security_group" "play-sg-private" {
  vpc_id = aws_vpc.play-vpc.id
  description = "Allow SSH inbound traffic"

  tags = {
    Name = "${var.default_infra_name_tag}-private-sg"
    Project = "${var.default_infra_name_tag}"
  }

}

# Ingress rule for SSH
resource "aws_vpc_security_group_ingress_rule" "play-allow-ssh-private" {
  security_group_id = aws_security_group.play-sg-private.id
  cidr_ipv4         = aws_vpc.play-vpc.cidr_block
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# Egress rule for All Traffic
resource "aws_vpc_security_group_egress_rule" "play-allow-all-traffic-private" {
  security_group_id = aws_security_group.play-sg-private.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# EC2 Instance(s)
# Public Instance
resource "aws_instance" "play-aws" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2_instance_type

  subnet_id     = aws_subnet.play-subnet.id
  associate_public_ip_address = "true"
  key_name = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.play-sg.id]
  
  # Define the EBS block storage
  root_block_device {
    volume_size = 30  # Sets the EBS size to 20 GB
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
    Name = "${var.default_infra_name_tag}"
    Project = "${var.default_infra_name_tag}"
  }

  depends_on = [ aws_route_table.play-route-table ]
}

# Private Instance in Subnet 1
resource "aws_instance" "play1-aws" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2_instance_type

  subnet_id     = aws_subnet.play-subnet-private-1.id
  key_name = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.play-sg-private.id]

  # Define the EBS block storage
  root_block_device {
    volume_size = 30  # Sets the EBS size to 20 GB
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
    Name = "${var.default_infra_name_tag}-1"
    Project = "${var.default_infra_name_tag}"
  }

  depends_on = [ aws_route_table.play-route-table-private ]
}

# Private Instance in Subnet 2
resource "aws_instance" "play2-aws" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2_instance_type

  subnet_id     = aws_subnet.play-subnet-private-2.id
  key_name = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.play-sg-private.id]

  # Define the EBS block storage
  root_block_device {
    volume_size = 30  # Sets the EBS size to 20 GB
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
    Name = "${var.default_infra_name_tag}-2"
    Project = "${var.default_infra_name_tag}"
  }

  depends_on = [ aws_route_table.play-route-table-private ]
}