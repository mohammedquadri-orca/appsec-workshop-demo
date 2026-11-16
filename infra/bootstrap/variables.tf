variable "owner" {
  description = "Value for the `owner` tag on every resource (e.g. your username)."
  type        = string
}

variable "region" {
  description = "AWS region for the sandbox demo."
  type        = string
  default     = "us-east-1"
}
