output "instance_id" {
  description = "ID of the Mac EC2 instance"
  value       = aws_instance.mac.id
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = aws_instance.mac.private_ip
}

output "public_ip" {
  description = "Public IP address of the instance (if applicable)"
  value       = aws_instance.mac.public_ip
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = data.aws_ami.macos.id
}

output "ami_name" {
  description = "Name of the AMI used"
  value       = data.aws_ami.macos.name
}
