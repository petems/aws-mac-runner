resource "aws_security_group" "mac_instance" {
  name_prefix = "${var.name_prefix}-mac-"
  description = "Security group for Mac EC2 instance"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-mac-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Egress: allow all outbound (required for GitHub runner communication)
resource "aws_vpc_security_group_egress_rule" "allow_all_ipv4" {
  security_group_id = aws_security_group.mac_instance.id
  description       = "Allow all outbound IPv4 traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Optional SSH ingress - only created when ssh_allowed_cidrs is non-empty
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  count = length(var.ssh_allowed_cidrs)

  security_group_id = aws_security_group.mac_instance.id
  description       = "SSH access from allowed CIDR"
  cidr_ipv4         = var.ssh_allowed_cidrs[count.index]
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

# IAM role for the Mac instance (SSM access)
resource "aws_iam_role" "mac_instance" {
  name_prefix = "${var.name_prefix}-mac-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.name_prefix}-mac-role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.mac_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "mac_instance" {
  name_prefix = "${var.name_prefix}-mac-"
  role        = aws_iam_role.mac_instance.name

  tags = {
    Name = "${var.name_prefix}-mac-profile"
  }
}
