variable "github_runner_url" {
  description = "GitHub repository or organization URL for runner registration"
  type        = string
}

variable "github_runner_token" {
  description = "GitHub runner registration token"
  type        = string
  sensitive   = true
}
