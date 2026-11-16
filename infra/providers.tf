provider "aws" {
  region = var.region

  # Every resource gets owner + purpose tags.
  default_tags {
    tags = {
      owner   = var.owner
      purpose = "orca-appsec-demo"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}
