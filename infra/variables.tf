variable "owner" {
  description = "Value for the `owner` tag on every resource (e.g. your username)."
  type        = string
}

variable "region" {
  description = "AWS region for the sandbox demo."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Name prefix for all resources."
  type        = string
  default     = "orca-appsec-demo"
}

variable "vpc_cidr" {
  type    = string
  default = "10.42.0.0/16"
}

variable "instance_type" {
  description = "x86_64 instance type (the image is built for linux/amd64)."
  type        = string
  default     = "t3.small"
}

variable "image_tag" {
  description = "Tag of the app image in ECR that the instance runs."
  type        = string
  default     = "v1"
}
