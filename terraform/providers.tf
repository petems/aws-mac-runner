provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "aws-mac-runner"
      ManagedBy   = "terraform"
      Environment = var.environment
    }
  }
}
