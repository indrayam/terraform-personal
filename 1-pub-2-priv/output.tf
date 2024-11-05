output "play-aws-public-ip" {
  description = "Public IP address of the EC2 instance in Public Subnet"
  value = aws_instance.play-aws.public_ip
  
}

output "play-aws-private-ip" {
  description = "Private IP address of the EC2 instance in Public Subnet"
  value = aws_instance.play-aws.private_ip
  
}

output "play1-aws-private-ip" {
  description = "Private IP address of the EC2 instance in Private Subnet 1"
  value = aws_instance.play1-aws.private_ip
  
}

output "play2-aws-private-ip" {
  description = "Private IP address of the EC2 instance in Private Subnet 2"
  value = aws_instance.play2-aws.private_ip
  
}