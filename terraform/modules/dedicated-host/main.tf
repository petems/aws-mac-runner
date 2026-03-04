resource "aws_ec2_host" "this" {
  instance_type     = var.instance_type
  availability_zone = var.availability_zone
  auto_placement    = "on"
  host_recovery     = "off" # Not supported for Mac dedicated hosts

  tags = {
    Name = "${var.name_prefix}-mac-host"
  }

  lifecycle {
    # Prevent accidental destruction - dedicated hosts have a 24h minimum billing period
    prevent_destroy = false
  }
}
