variable "default_infra_name_tag" {
  description = "Value of the Name tag of the EC2 instance"
  type        = string
  default     = "play-aws"
}

variable "aws_profile" {
  description = "AWS profile to use"
  type        = string
  default     = "anand"
}

variable "aws_region" {
  description = "AWS profile to use"
  type        = string
  default     = "us-east-2"
}

variable "aws_availability_zone" {
  description = "Availability zone used for the EC2 instance"
  type        = string
  default     = "us-east-2a"
}

variable "key_pair_name" {
  description = "Key pair name for the EC2 instance"
  type        = string
  default     = "Anand on MacBook (Personal)"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr_block" {
  description = "CIDR block for the Subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

