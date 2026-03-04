output "host_id" {
  description = "ID of the dedicated host"
  value       = aws_ec2_host.this.id
}

output "host_arn" {
  description = "ARN of the dedicated host"
  value       = aws_ec2_host.this.arn
}
