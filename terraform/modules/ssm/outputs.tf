output "log_group_name" {
  description = "Name of the CloudWatch log group for SSM sessions"
  value       = var.enable_session_logging ? aws_cloudwatch_log_group.ssm_sessions[0].name : null
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group for SSM sessions"
  value       = var.enable_session_logging ? aws_cloudwatch_log_group.ssm_sessions[0].arn : null
}
