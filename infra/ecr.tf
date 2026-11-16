resource "aws_ecr_repository" "app" {
  name = var.name

  # ORCA-DEMO: IaC – ECR tag mutability enabled (tags like v1 can be silently overwritten)
  image_tag_mutability = "MUTABLE"

  # ORCA-DEMO: IaC – ECR image scanning on push disabled
  image_scanning_configuration {
    scan_on_push = false
  }

  # Lets `make destroy` remove the repo even when it still holds images.
  force_delete = true
}
