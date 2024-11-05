output "play-aws-public-ip" {
  description = "Public IP address of the EC2 instance in Public Subnet"
  value       = aws_instance.play-aws.public_ip

}


