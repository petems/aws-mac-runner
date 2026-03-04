# Optional SSM-related policies for enhanced session management

# Allow CloudWatch logging for SSM sessions
resource "aws_iam_role_policy" "ssm_cloudwatch" {
  count = var.enable_session_logging ? 1 : 0

  name = "${var.name_prefix}-ssm-cloudwatch"
  role = var.iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.ssm_sessions[0].arn}:*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "ssm_sessions" {
  count = var.enable_session_logging ? 1 : 0

  name              = "/ssm/sessions/${var.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.name_prefix}-ssm-sessions"
  }
}
