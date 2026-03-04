output "instance_id" {
  description = "ID of the Mac EC2 instance"
  value       = module.mac_instance.instance_id
}

output "instance_public_ip" {
  description = "Public IP address of the Mac instance"
  value       = module.mac_instance.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the Mac instance"
  value       = module.mac_instance.private_ip
}

output "dedicated_host_id" {
  description = "ID of the dedicated host"
  value       = module.dedicated_host.host_id
}

output "ami_id" {
  description = "AMI ID used for the Mac instance"
  value       = module.mac_instance.ami_id
}

output "ami_name" {
  description = "Name of the AMI used"
  value       = module.mac_instance.ami_name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "ssm_connect_command" {
  description = "AWS CLI command to connect via SSM"
  value       = "aws ssm start-session --target ${module.mac_instance.instance_id} --region ${var.aws_region}"
}

output "ssh_connect_command" {
  description = "SSH command to connect (if SSH is enabled)"
  value       = length(var.ssh_allowed_cidrs) > 0 ? "ssh ec2-user@${module.mac_instance.public_ip}" : "SSH disabled - use SSM instead"
}
