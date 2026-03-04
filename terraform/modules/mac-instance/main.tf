# Find the latest macOS AMI for Apple Silicon
data "aws_ami" "macos" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ec2-macos-${var.macos_version}*"]
  }

  filter {
    name   = "architecture"
    values = ["arm64_mac"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_instance" "mac" {
  ami                  = data.aws_ami.macos.id
  instance_type        = var.instance_type
  host_id              = var.host_id
  subnet_id            = var.subnet_id
  iam_instance_profile = var.instance_profile_name

  vpc_security_group_ids = [var.security_group_id]

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    iops        = var.root_volume_iops
    throughput  = var.root_volume_throughput
    encrypted   = true
  }

  # IMDSv2 enforced
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  user_data = var.user_data

  tags = {
    Name = "${var.name_prefix}-mac-runner"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}
