output "security_group_id" {
  description = "ID of the Mac instance security group"
  value       = aws_security_group.mac_instance.id
}

output "instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = aws_iam_instance_profile.mac_instance.name
}

output "instance_profile_arn" {
  description = "ARN of the IAM instance profile"
  value       = aws_iam_instance_profile.mac_instance.arn
}

output "iam_role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.mac_instance.name
}

output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.mac_instance.arn
}
